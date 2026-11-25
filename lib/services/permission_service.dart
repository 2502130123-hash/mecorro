import 'package:permission_handler/permission_handler.dart';

/// Permisos en tiempo de ejecución (RNF-02): actividad física, ubicación y notificaciones.
class PermissionService {
  Future<bool> hasActivity() async {
    try {
      return await Permission.activityRecognition.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasLocation() async {
    try {
      return await Permission.locationWhenInUse.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestActivity() async {
    try {
      return (await Permission.activityRecognition.request()).isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestLocation() async {
    try {
      return (await Permission.locationWhenInUse.request()).isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestNotifications() async {
    try {
      return (await Permission.notification.request()).isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openSettings() => openAppSettings();
}