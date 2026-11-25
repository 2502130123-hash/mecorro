import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Cifrado de contraseñas con el paquete `crypto`:
/// SHA-256 + sal aleatoria + varias iteraciones. Nunca se guarda la contraseña real.
class SecurityService {
  SecurityService._();

  static const int _iterations = 3000;

  static String generateSalt([int length = 16]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String hashPassword(String password, String salt) {
    List<int> data = utf8.encode('$salt:$password');
    for (var i = 0; i < _iterations; i++) {
      data = sha256.convert(<int>[...data, ...utf8.encode(salt)]).bytes;
    }
    return base64UrlEncode(data);
  }

  static bool verify(String password, String salt, String expectedHash) {
    final candidate = hashPassword(password, salt);
    return _constantTimeEquals(candidate, expectedHash);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}