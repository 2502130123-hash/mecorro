import '../utils/health_calculator.dart';

/// Usuario registrado. La contraseña NUNCA se guarda en claro:
/// se guarda el hash SHA-256 (con sal) en [passwordHash].
class UserProfile {
  const UserProfile({
    required this.name,
    required this.nickname,
    required this.email,
    required this.gender,
    required this.age,
    required this.weightKg,
    required this.heightCm,
    required this.passwordHash,
    required this.salt,
    required this.createdAt,
    this.biometricEnabled = false,
    this.biometricPrompted = false,
  });

  final String name;
  final String nickname;
  final String email;
  final String gender; // Masculino | Femenino | Otro
  final int age;
  final double weightKg;
  final double heightCm;
  final String passwordHash;
  final String salt;
  final DateTime createdAt;
  final bool biometricEnabled;

  /// true cuando ya se le ofreció activar la huella (primer inicio de sesión).
  final bool biometricPrompted;

  /// Nombre con el que saluda la app: apodo si existe, si no el primer nombre.
  String get displayName {
    final nick = nickname.trim();
    if (nick.isNotEmpty) return nick;
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'atleta' : first;
  }

  /// Índice de masa corporal calculado SIEMPRE a partir de peso y estatura.
  double get bmi => HealthCalculator.bmi(weightKg, heightCm);

  UserProfile copyWith({
    String? name,
    String? nickname,
    String? gender,
    int? age,
    double? weightKg,
    double? heightCm,
    bool? biometricEnabled,
    bool? biometricPrompted,
  }) {
    return UserProfile(
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      email: email,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      passwordHash: passwordHash,
      salt: salt,
      createdAt: createdAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricPrompted: biometricPrompted ?? this.biometricPrompted,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'nickname': nickname,
    'email': email,
    'gender': gender,
    'age': age,
    'weightKg': weightKg,
    'heightCm': heightCm,
    'passwordHash': passwordHash,
    'salt': salt,
    'createdAt': createdAt.toIso8601String(),
    'biometricEnabled': biometricEnabled,
    'biometricPrompted': biometricPrompted,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String? ?? '',
      gender: json['gender'] as String? ?? 'Otro',
      age: (json['age'] as num?)?.toInt() ?? 25,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 170,
      passwordHash: json['passwordHash'] as String? ?? '',
      salt: json['salt'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      biometricEnabled: json['biometricEnabled'] as bool? ?? false,
      biometricPrompted: json['biometricPrompted'] as bool? ?? false,
    );
  }
}