import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Envoltorio de los sensores de movimiento:
/// podómetro (STEP_COUNTER), acelerómetro y giroscopio.
/// Cada start*() cancela la suscripción anterior, así que es seguro llamarlo varias veces.
/// stopAll() libera TODOS los listeners (RNF-01: ahorro de batería).
class SensorService {
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<AccelerometerEvent>? _accSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  void startPedometer({
    required void Function(int rawSteps) onSteps,
    required void Function(Object error) onError,
  }) {
    _stepSub?.cancel();
    try {
      _stepSub = Pedometer.stepCountStream.listen(
            (event) => onSteps(event.steps),
        onError: onError,
        cancelOnError: false,
      );
    } catch (e) {
      onError(e);
    }
  }

  void startAccelerometer({
    required void Function(double x, double y, double z) onData,
    required void Function(Object error) onError,
  }) {
    _accSub?.cancel();
    try {
      _accSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
            (e) => onData(e.x, e.y, e.z),
        onError: onError,
        cancelOnError: false,
      );
    } catch (e) {
      onError(e);
    }
  }

  void startGyroscope({
    required void Function(double x, double y, double z) onData,
    required void Function(Object error) onError,
  }) {
    _gyroSub?.cancel();
    try {
      _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.normalInterval).listen(
            (e) => onData(e.x, e.y, e.z),
        onError: onError,
        cancelOnError: false,
      );
    } catch (e) {
      onError(e);
    }
  }

  Future<void> stopPedometer() async {
    await _stepSub?.cancel();
    _stepSub = null;
  }

  Future<void> stopAccelerometer() async {
    await _accSub?.cancel();
    _accSub = null;
  }

  Future<void> stopGyroscope() async {
    await _gyroSub?.cancel();
    _gyroSub = null;
  }

  Future<void> stopAll() async {
    await stopPedometer();
    await stopAccelerometer();
    await stopGyroscope();
  }
}