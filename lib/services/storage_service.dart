import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_stats.dart';
import '../models/profile_change.dart';
import '../models/user_profile.dart';
import '../models/workout_record.dart';

/// Capa de persistencia local (SharedPreferences).
/// Todo se guarda como JSON; los datos de cada usuario van separados por correo.
class StorageService {
  StorageService._(this._prefs);

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService._(prefs);
  }

  static const _kUsers = 'users';
  static const _kActive = 'active_session';
  static const _kLast = 'last_user';

  String _changesKey(String email) => 'changes_$email';
  String _workoutsKey(String email) => 'workouts_$email';
  String _dailyKey(String email) => 'daily_$email';

  // ---------------------------------------------------------------- Usuarios
  List<UserProfile> getUsers() {
    final raw = _prefs.getString(_kUsers);
    if (raw == null || raw.isEmpty) return <UserProfile>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => UserProfile.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return <UserProfile>[];
    }
  }

  Future<void> _saveUsers(List<UserProfile> users) async {
    await _prefs.setString(_kUsers, jsonEncode(users.map((u) => u.toJson()).toList()));
  }

  UserProfile? findUser(String email) {
    final key = email.trim().toLowerCase();
    for (final u in getUsers()) {
      if (u.email == key) return u;
    }
    return null;
  }

  Future<void> upsertUser(UserProfile user) async {
    final users = getUsers();
    final index = users.indexWhere((u) => u.email == user.email);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await _saveUsers(users);
  }

  /// Borra la cuenta y TODOS sus datos (cambios, entrenamientos y pasos).
  Future<void> deleteUser(String email) async {
    final users = getUsers()..removeWhere((u) => u.email == email);
    await _saveUsers(users);
    await _prefs.remove(_changesKey(email));
    await _prefs.remove(_workoutsKey(email));
    await _prefs.remove(_dailyKey(email));
    if (activeEmail == email) await _prefs.remove(_kActive);
    if (lastEmail == email) await _prefs.remove(_kLast);
  }

  // ------------------------------------------------------------------ Sesión
  String? get activeEmail => _prefs.getString(_kActive);
  String? get lastEmail => _prefs.getString(_kLast);

  Future<void> setActiveEmail(String? email) async {
    if (email == null) {
      await _prefs.remove(_kActive);
    } else {
      await _prefs.setString(_kActive, email);
    }
  }

  Future<void> setLastEmail(String? email) async {
    if (email == null) {
      await _prefs.remove(_kLast);
    } else {
      await _prefs.setString(_kLast, email);
    }
  }

  // --------------------------------------------------------------- Cronograma
  List<ProfileChange> getChanges(String email) {
    final raw = _prefs.getString(_changesKey(email));
    if (raw == null || raw.isEmpty) return <ProfileChange>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => ProfileChange.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return <ProfileChange>[];
    }
  }

  /// Inserta al inicio (lo más reciente primero). Máximo 200 registros.
  Future<void> addChanges(String email, List<ProfileChange> newOnes) async {
    final list = getChanges(email)..insertAll(0, newOnes);
    final trimmed = list.length > 200 ? list.sublist(0, 200) : list;
    await _prefs.setString(_changesKey(email), jsonEncode(trimmed.map((c) => c.toJson()).toList()));
  }

  // ------------------------------------------------------------ Entrenamientos
  List<WorkoutRecord> getWorkouts(String email) {
    final raw = _prefs.getString(_workoutsKey(email));
    if (raw == null || raw.isEmpty) return <WorkoutRecord>[];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => WorkoutRecord.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return <WorkoutRecord>[];
    }
  }

  Future<void> addWorkout(String email, WorkoutRecord record) async {
    final list = getWorkouts(email)..insert(0, record);
    final trimmed = list.length > 100 ? list.sublist(0, 100) : list;
    await _prefs.setString(_workoutsKey(email), jsonEncode(trimmed.map((w) => w.toJson()).toList()));
  }

  // ------------------------------------------------------ Acumulado por día
  Map<String, DailyStats> getDaily(String email) {
    final raw = _prefs.getString(_dailyKey(email));
    if (raw == null || raw.isEmpty) return <String, DailyStats>{};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, DailyStats.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return <String, DailyStats>{};
    }
  }

  Future<void> saveDaily(String email, Map<String, DailyStats> daily) async {
    final encoded = daily.map((k, v) => MapEntry(k, v.toJson()));
    await _prefs.setString(_dailyKey(email), jsonEncode(encoded));
  }
}