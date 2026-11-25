import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class BiometricResult {
  const BiometricResult(this.success, [this.message]);

  final bool success;
  final String? message;
}

/// Sensor 1 (RF-01): huella dactilar con la Biometric API de Android.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// true si el teléfono tiene sensor y al menos una huella/rostro registrado.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false; // RNF-04: nunca debe tronar si no hay sensor
    }
  }

  Future<BiometricResult> authenticate(String reason) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        authMessages: [
          AndroidAuthMessages(
            signInTitle: 'Verificación biométrica',
            cancelButton: 'Cancelar',
          ),
        ],
        biometricOnly: true,
      );
      if (ok) return const BiometricResult(true);
      return const BiometricResult(false, 'Huella no reconocida. Inténtalo de nuevo.');
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('cancel')) {
        return const BiometricResult(false, 'Verificación cancelada.');
      }
      if (text.contains('enrolled') || text.contains('nobiometrics')) {
        return const BiometricResult(false, 'No hay huellas registradas en este teléfono.');
      }
      if (text.contains('lock')) {
        return const BiometricResult(false, 'Demasiados intentos. Espera unos segundos.');
      }
      return const BiometricResult(false, 'No se pudo usar el sensor de huella.');
    }
  }
}