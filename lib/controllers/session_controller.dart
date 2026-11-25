import 'package:flutter/foundation.dart';

import '../models/profile_change.dart';
import '../models/user_profile.dart';
import '../services/security_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';

class AuthResult {
  const AuthResult.ok({this.firstLogin = false})
      : ok = true,
        message = null;

  const AuthResult.fail(this.message)
      : ok = false,
        firstLogin = false;

  final bool ok;
  final String? message;

  /// true si es la primera vez que este usuario inicia sesión
  /// (momento de ofrecer el acceso con huella).
  final bool firstLogin;
}

/// Maneja registro, inicio/cierre de sesión, edición de perfil y cronograma de cambios.
class SessionController extends ChangeNotifier {
  SessionController({required StorageService storage}) : _storage = storage;

  final StorageService _storage;
  UserProfile? _current;
  List<ProfileChange> _changes = <ProfileChange>[];

  UserProfile? get currentUser => _current;
  bool get isLoggedIn => _current != null;
  bool get hasUsers => _storage.getUsers().isNotEmpty;
  List<ProfileChange> get changes => List.unmodifiable(_changes);

  /// Último usuario que inició sesión en este teléfono.
  UserProfile? get lastUser {
    final email = _storage.lastEmail;
    return email == null ? null : _storage.findUser(email);
  }

  bool get canLoginWithBiometrics => lastUser?.biometricEnabled ?? false;

  /// Restaura la sesión guardada: solo se cierra cuando el usuario lo decide.
  Future<void> load() async {
    final email = _storage.activeEmail;
    if (email == null) return;
    final user = _storage.findUser(email);
    if (user == null) {
      await _storage.setActiveEmail(null);
      return;
    }
    _current = user;
    _changes = _storage.getChanges(user.email);
  }

  // ---------------------------------------------------------------- Registro
  /// Devuelve null si se registró bien, o el mensaje de error.
  Future<String?> register({
    required String name,
    required String nickname,
    required String email,
    required String password,
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) async {
    final mail = email.trim().toLowerCase();
    if (_storage.findUser(mail) != null) {
      return 'Este correo ya está registrado. Inicia sesión.';
    }
    final salt = SecurityService.generateSalt();
    final user = UserProfile(
      name: name.trim(),
      nickname: nickname.trim(),
      email: mail,
      gender: gender,
      age: age,
      weightKg: weightKg,
      heightCm: heightCm,
      passwordHash: SecurityService.hashPassword(password, salt),
      salt: salt,
      createdAt: DateTime.now(),
    );
    await _storage.upsertUser(user);
    await _storage.addChanges(mail, [
      ProfileChange(
        date: DateTime.now(),
        field: 'Cuenta',
        oldValue: '',
        newValue: 'Cuenta creada · IMC ${user.bmi.toStringAsFixed(1)}',
      ),
    ]);
    return null;
  }

  // ------------------------------------------------------------------- Login
  Future<AuthResult> login(String email, String password) async {
    final user = _storage.findUser(email);
    if (user == null || !SecurityService.verify(password, user.salt, user.passwordHash)) {
      return const AuthResult.fail('Correo o contraseña incorrectos.');
    }
    await _startSession(user);
    return AuthResult.ok(firstLogin: !user.biometricPrompted);
  }

  /// Se llama DESPUÉS de que la huella fue validada: abre el perfil del último usuario.
  Future<AuthResult> startSessionForLastUser() async {
    final user = lastUser;
    if (user == null || !user.biometricEnabled) {
      return const AuthResult.fail('La huella no está activada para ninguna cuenta.');
    }
    await _startSession(user);
    return const AuthResult.ok();
  }

  Future<void> _startSession(UserProfile user) async {
    await _storage.setActiveEmail(user.email);
    await _storage.setLastEmail(user.email);
    _current = user;
    _changes = _storage.getChanges(user.email);
    notifyListeners();
  }

  bool verifyPassword(String password) {
    final user = _current;
    if (user == null) return false;
    return SecurityService.verify(password, user.salt, user.passwordHash);
  }

  Future<void> logout() async {
    await _storage.setActiveEmail(null);
    _current = null;
    _changes = <ProfileChange>[];
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final user = _current;
    if (user == null) return;
    // 1) Cerramos sesión (el WorkoutController guarda y se desconecta)
    await _storage.setActiveEmail(null);
    _current = null;
    _changes = <ProfileChange>[];
    notifyListeners();
    // 2) Borramos todos los datos del usuario
    await _storage.deleteUser(user.email);
  }

  // ----------------------------------------------------------------- Biometría
  Future<void> markBiometricPrompted() async {
    final user = _current;
    if (user == null || user.biometricPrompted) return;
    final updated = user.copyWith(biometricPrompted: true);
    await _storage.upsertUser(updated);
    _current = updated;
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final user = _current;
    if (user == null || user.biometricEnabled == enabled) return;
    final updated = user.copyWith(biometricEnabled: enabled, biometricPrompted: true);
    await _storage.upsertUser(updated);
    await _storage.addChanges(user.email, [
      ProfileChange(
        date: DateTime.now(),
        field: 'Acceso con huella',
        oldValue: enabled ? 'Desactivado' : 'Activado',
        newValue: enabled ? 'Activado' : 'Desactivado',
      ),
    ]);
    _current = updated;
    _changes = _storage.getChanges(user.email);
    notifyListeners();
  }

  // ------------------------------------------------------------------- Perfil
  /// Actualiza datos editables. El IMC no se guarda: se recalcula solo y
  /// además se registra en el cronograma cuando cambia.
  Future<void> updateProfile({
    String? name,
    String? nickname,
    double? weightKg,
    double? heightCm,
    int? age,
    String? gender,
  }) async {
    final old = _current;
    if (old == null) return;
    final now = DateTime.now();
    final logs = <ProfileChange>[];

    void log(String field, String before, String after) {
      logs.add(ProfileChange(date: now, field: field, oldValue: before, newValue: after));
    }

    if (name != null && name.trim() != old.name) {
      log('Nombre', old.name, name.trim());
    }
    if (nickname != null && nickname.trim() != old.nickname) {
      log('Apodo', old.nickname.isEmpty ? '—' : old.nickname, nickname.trim().isEmpty ? '—' : nickname.trim());
    }
    if (weightKg != null && weightKg != old.weightKg) {
      log('Peso', '${Formatters.number(old.weightKg)} kg', '${Formatters.number(weightKg)} kg');
    }
    if (heightCm != null && heightCm != old.heightCm) {
      log('Estatura', '${Formatters.number(old.heightCm)} cm', '${Formatters.number(heightCm)} cm');
    }
    if (age != null && age != old.age) {
      log('Edad', '${old.age} años', '$age años');
    }
    if (gender != null && gender != old.gender) {
      log('Género', old.gender, gender);
    }
    if (logs.isEmpty) return;

    final updated = old.copyWith(
      name: name?.trim(),
      nickname: nickname?.trim(),
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    if ((updated.bmi - old.bmi).abs() > 0.001) {
      log('IMC', old.bmi.toStringAsFixed(1), updated.bmi.toStringAsFixed(1));
    }

    await _storage.upsertUser(updated);
    await _storage.addChanges(old.email, logs);
    _current = updated;
    _changes = _storage.getChanges(old.email);
    notifyListeners(); // el perfil y el IMC se redibujan automáticamente
  }
}