import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Sensor GPS (RF-05). Durante un entrenamiento se usa un servicio en primer plano
/// con notificación para que Android no detenga el rastreo con la pantalla apagada.
class LocationService {
  StreamSubscription<Position>? _sub;

  Future<bool> isServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  void start({
    required void Function(Position position) onPosition,
    required void Function(Object error) onError,
  }) {
    _sub?.cancel();
    final settings = AndroidSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 3,
      intervalDuration: const Duration(seconds: 2),
      foregroundNotificationConfig: ForegroundNotificationConfig(
        notificationTitle: 'mecorro',
        notificationText: 'Registrando tu recorrido…',
        enableWakeLock: true,
        setOngoing: true,
      ),
    );
    try {
      _sub = Geolocator.getPositionStream(locationSettings: settings).listen(
        onPosition,
        onError: onError,
        cancelOnError: false,
      );
    } catch (e) {
      onError(e);
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) =>
      Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
}