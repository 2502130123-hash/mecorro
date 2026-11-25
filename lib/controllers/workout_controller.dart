import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart' show MapController;
import 'package:geolocator/geolocator.dart' show Position;
import 'package:latlong2/latlong.dart' show LatLng;

import '../models/activity_mode.dart';
import '../models/daily_stats.dart';
import '../models/motion_data.dart';
import '../models/user_profile.dart';
import '../models/workout_record.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';
import '../utils/formatters.dart';
import '../utils/health_calculator.dart';

/// Cerebro de la actividad deportiva. Combina 5 fuentes en tiempo real:
///  - Podómetro (STEP_COUNTER)  -> pasos
///  - Acelerómetro              -> intensidad, zancada y respaldo de pasos
///  - Giroscopio                -> giros / orientación
///  - GPS                       -> ruta, distancia y velocidad
///  - Huella (en SessionController / BiometricService)
///
/// RNF-01: implementa WidgetsBindingObserver para liberar los listeners cuando la app
/// pasa a segundo plano (si no hay un entrenamiento activo) y en detach()/dispose().
class WorkoutController extends ChangeNotifier with WidgetsBindingObserver {
  WorkoutController({
    required StorageService storage,
    required PermissionService permissions,
    required SensorService sensors,
    required LocationService location,
  })  : _storage = storage,
        _permissions = permissions,
        _sensors = sensors,
        _location = location;

  static const double _gravity = 9.80665;
  static const int dailyStepGoal = 10000;

  final StorageService _storage;
  final PermissionService _permissions;
  final SensorService _sensors;
  final LocationService _location;

  UserProfile? _user;
  bool _observing = false;
  bool _foreground = true;
  Timer? _ticker;

  // ------------------------------------------------------------------ Modo
  ActivityMode _mode = ActivityMode.walking;
  ActivityMode get mode => _mode;

  void setMode(ActivityMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }

  // -------------------------------------------------------------- Permisos
  bool activityGranted = false;
  bool locationGranted = false;
  bool get permissionsOk => activityGranted && locationGranted;

  // ------------------------------------------------------ Acumulado diario
  Map<String, DailyStats> _daily = <String, DailyStats>{};
  String _todayKey = '';
  bool _dirty = false;
  int _ticksSinceSave = 0;
  List<WorkoutRecord> _workouts = <WorkoutRecord>[];

  DailyStats get today => _daily[Formatters.dateKey(DateTime.now())] ?? DailyStats();
  List<WorkoutRecord> get history => List.unmodifiable(_workouts);

  int get averageSteps {
    final days = _daily.values.where((d) => d.steps > 0).toList();
    if (days.isEmpty) return 0;
    final total = days.fold<int>(0, (sum, d) => sum + d.steps);
    return (total / days.length).round();
  }

  List<DayBar> last7Days() {
    final now = DateTime.now();
    return List<DayBar>.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final stats = _daily[Formatters.dateKey(date)];
      return DayBar(date: date, steps: stats?.steps ?? 0);
    });
  }

  // --------------------------------------------------- Entrenamiento activo
  bool _active = false;
  bool _paused = false;
  DateTime? _startedAt;
  int _elapsedSec = 0;
  int _wSteps = 0;
  double _wDistanceM = 0;
  double _wCalories = 0;
  double _maxSpeedKmh = 0;
  double _speedKmh = 0;
  double _cadence = 0; // pasos por minuto
  final List<DateTime> _stepTimes = <DateTime>[];

  bool get isActive => _active;
  bool get isPaused => _paused;
  int get elapsedSeconds => _elapsedSec;
  double get speedKmh => _speedKmh;
  double get cadence => _cadence;

  /// Lo que se muestra en pantalla: la sesión si hay una activa, si no el total de hoy.
  bool get showingSession => _active;
  int get displaySteps => _active ? _wSteps : today.steps;
  double get displayDistanceKm => (_active ? _wDistanceM : today.distanceM) / 1000;
  double get displayCalories => _active ? _wCalories : today.calories;

  double get strideM {
    final user = _user;
    if (user == null) return 0.7;
    return HealthCalculator.strideLengthM(
      heightCm: user.heightCm,
      gender: user.gender,
      mode: _active ? _mode : ActivityMode.walking,
    );
  }

  // ------------------------------------------------------------------- GPS
  final List<LatLng> _route = <LatLng>[];
  LatLng? _lastPoint;
  DateTime? _lastPointTime;
  DateTime? _lastFix;
  double _gpsSpeedKmh = 0;
  String? _gpsStatus;

  /// Se incrementa cada vez que llega un punto GPS (para redibujar solo el mapa).
  final ValueNotifier<int> routeTick = ValueNotifier<int>(0);
  final MapController mapController = MapController();
  bool mapReady = false;

  List<LatLng> get route => List<LatLng>.unmodifiable(_route);
  LatLng? get lastPoint => _lastPoint;
  String? get gpsStatus => _gpsStatus;
  bool get gpsFixed =>
      _lastFix != null && DateTime.now().difference(_lastFix!).inSeconds <= 8;

  // --------------------------------------------- Acelerómetro y giroscopio
  final ValueNotifier<MotionData> motion = ValueNotifier<MotionData>(MotionData.zero);
  double _intensity = 0;
  double _pitchDeg = 0;
  double _rollDeg = 0;
  double _gyroDegS = 0;
  double _yawDeg = 0;
  bool _turning = false;
  bool _accelFailed = false;
  bool _gyroFailed = false;
  DateTime? _lastGyro;
  DateTime _lastPublish = DateTime.fromMillisecondsSinceEpoch(0);

  // ------------------------------------------------------ Fuente de pasos
  int? _lastRawSteps;
  bool _hwStepsSeen = false;
  bool _useAccelSteps = false;
  double _filtered = _gravity;
  bool _aboveThreshold = false;
  DateTime _lastAccelStep = DateTime.fromMillisecondsSinceEpoch(0);

  String get stepSourceLabel {
    if (_useAccelSteps) {
      return activityGranted
          ? 'Acelerómetro (respaldo)'
          : 'Acelerómetro (sin permiso de actividad)';
    }
    return _hwStepsSeen ? 'Podómetro del dispositivo' : 'Podómetro (esperando pasos)';
  }

  // =====================================================================
  //  CICLO DE VIDA
  // =====================================================================

  /// Se llama cuando un usuario inicia sesión.
  Future<void> attach(UserProfile user) async {
    _user = user;
    _mode = ActivityMode.walking;
    _daily = _storage.getDaily(user.email);
    _workouts = _storage.getWorkouts(user.email);
    _todayKey = Formatters.dateKey(DateTime.now());
    _resetWorkout();
    _foreground = true;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    notifyListeners();
    await refreshPermissions();
    await _startSensors();
  }

  /// Se llama al cerrar sesión o borrar la cuenta: guarda y libera TODO.
  Future<void> detach() async {
    final user = _user;
    if (user == null) return;
    final record = _active ? _buildRecord() : null;
    _persistDailyFor(user.email);
    _user = null;
    _ticker?.cancel();
    _ticker = null;
    await _location.stop();
    await _sensors.stopAll();
    if (record != null) await _storage.addWorkout(user.email, record);
    _resetWorkout();
    _speedKmh = 0;
    _daily = <String, DailyStats>{};
    _workouts = <WorkoutRecord>[];
    motion.value = MotionData.zero;
    notifyListeners();
  }

  /// El perfil cambió (peso, estatura...): los cálculos usan los nuevos datos.
  void updateUser(UserProfile user) {
    _user = user;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_user == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _foreground = true;
        unawaited(_resume());
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _foreground = false;
        _enterBackground();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _resume() async {
    await refreshPermissions();
    await _startSensors();
  }

  /// RNF-01: sin entrenamiento activo se des-suscriben TODOS los sensores.
  void _enterBackground() {
    _persistDaily();
    if (_active) {
      // Entrenando con pantalla apagada: seguimos con GPS y podómetro, soltamos el giroscopio.
      unawaited(_sensors.stopGyroscope());
    } else {
      unawaited(_stopSensors());
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    unawaited(_location.stop());
    unawaited(_sensors.stopAll());
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    routeTick.dispose();
    motion.dispose();
    super.dispose();
  }

  // =====================================================================
  //  PERMISOS
  // =====================================================================
  Future<void> refreshPermissions() async {
    activityGranted = await _permissions.hasActivity();
    locationGranted = await _permissions.hasLocation();
    notifyListeners();
  }

  /// Se llama después de que el usuario concede (o niega) permisos.
  Future<void> onPermissionsChanged() async {
    await refreshPermissions();
    await _startSensors();
  }

  Future<void> openLocationSettings() => _location.openLocationSettings();

  // =====================================================================
  //  SENSORES
  // =====================================================================
  Future<void> _startSensors() async {
    if (_user == null) return;
    _accelFailed = false;
    _gyroFailed = false;
    _useAccelSteps = !activityGranted;

    if (activityGranted) {
      _sensors.startPedometer(onSteps: _onRawSteps, onError: _onPedometerError);
    } else {
      await _sensors.stopPedometer();
    }
    _sensors.startAccelerometer(onData: _onAccel, onError: _onAccelError);
    if (_foreground) {
      _lastGyro = null;
      _sensors.startGyroscope(onData: _onGyro, onError: _onGyroError);
    }
    _ticker ??= Timer.periodic(const Duration(seconds: 1), _onTick);
    notifyListeners();
  }

  Future<void> _stopSensors() async {
    _ticker?.cancel();
    _ticker = null;
    await _sensors.stopAll();
  }

  // ---- Podómetro (hardware) ----
  void _onRawSteps(int raw) {
    _hwStepsSeen = true;
    final last = _lastRawSteps;
    _lastRawSteps = raw;
    if (last == null) return; // la primera lectura solo fija la referencia
    final delta = raw - last;
    if (delta <= 0 || delta > 20000) return; // reinicio del contador o dato absurdo
    _registerSteps(delta);
  }

  void _onPedometerError(Object error) {
    // RNF-04: el teléfono no tiene podómetro -> usamos el acelerómetro como respaldo
    _useAccelSteps = true;
    notifyListeners();
  }

  // ---- Acelerómetro ----
  void _onAccel(double x, double y, double z) {
    final now = DateTime.now();
    final magnitude = math.sqrt(x * x + y * y + z * z);

    // Intensidad: cuánto se aleja la aceleración de la gravedad (suavizada)
    final deviation = (magnitude - _gravity).abs();
    _intensity = _intensity * 0.85 + deviation * 0.15;

    // Inclinación del teléfono
    final pitch = math.atan2(-x, math.sqrt(y * y + z * z)) * 180 / math.pi;
    final roll = math.atan2(y, z) * 180 / math.pi;
    _pitchDeg = _pitchDeg * 0.8 + pitch * 0.2;
    _rollDeg = _rollDeg * 0.8 + roll * 0.2;

    // Respaldo: detección de zancadas por picos de aceleración
    if (_useAccelSteps && _mode != ActivityMode.cycling) {
      _filtered = _filtered * 0.5 + magnitude * 0.5;
      final isPeak = _filtered > _gravity + 1.3;
      if (isPeak &&
          !_aboveThreshold &&
          now.difference(_lastAccelStep).inMilliseconds > 320) {
        _lastAccelStep = now;
        _registerSteps(1);
      }
      _aboveThreshold = isPeak;
    }
    _publishMotion(now);
  }

  void _onAccelError(Object error) {
    _accelFailed = true;
    _publishMotion(DateTime.now(), force: true);
  }

  // ---- Giroscopio ----
  void _onGyro(double x, double y, double z) {
    final now = DateTime.now();
    final last = _lastGyro;
    final dt = last == null ? 0.0 : now.difference(last).inMicroseconds / 1000000.0;
    _lastGyro = now;

    final magnitudeDegS = math.sqrt(x * x + y * y + z * z) * 180 / math.pi;
    _gyroDegS = _gyroDegS * 0.7 + magnitudeDegS * 0.3;
    _yawDeg = (_yawDeg + z * dt * 180 / math.pi) % 360;
    _turning = z.abs() > 1.2; // ~70°/s alrededor del eje vertical
    _publishMotion(now);
  }

  void _onGyroError(Object error) {
    _gyroFailed = true;
    _publishMotion(DateTime.now(), force: true);
  }

  void _publishMotion(DateTime now, {bool force = false}) {
    if (!force && now.difference(_lastPublish).inMilliseconds < 200) return;
    _lastPublish = now;
    motion.value = MotionData(
      intensity: _intensity,
      pitchDeg: _pitchDeg,
      rollDeg: _rollDeg,
      gyroDegPerSec: _gyroDegS,
      yawDeg: _yawDeg,
      turning: _turning,
      accelAvailable: !_accelFailed,
      gyroAvailable: !_gyroFailed,
    );
  }

  // =====================================================================
  //  PASOS, VELOCIDAD, CALORÍAS (tick de 1 segundo)
  // =====================================================================
  DailyStats _todayStats() {
    final key = Formatters.dateKey(DateTime.now());
    if (key != _todayKey) {
      _persistDaily(); // cambió el día: guardamos y empezamos en cero
      _todayKey = key;
    }
    return _daily.putIfAbsent(key, () => DailyStats());
  }

  void _registerSteps(int n) {
    final user = _user;
    if (user == null) return;
    final stats = _todayStats();
    final now = DateTime.now();
    for (var i = 0; i < n && i < 200; i++) {
      _stepTimes.add(now);
    }
    stats.steps += n;
    _dirty = true;

    final stride = strideM;
    if (_active) {
      if (_paused) return;
      _wSteps += n;
      // Sin señal GPS la distancia se estima con la zancada (no aplica a ciclismo)
      if (_mode != ActivityMode.cycling && !gpsFixed) {
        final d = n * stride;
        _wDistanceM += d;
        stats.distanceM += d;
      }
    } else {
      final d = n * stride;
      stats.distanceM += d;
      stats.calories += HealthCalculator.caloriesPerStep(user.weightKg, stride) * n;
    }
  }

  void _onTick(Timer timer) {
    final user = _user;
    if (user == null) return;
    final now = DateTime.now();
    final stats = _todayStats();

    // Cadencia: pasos de los últimos 10 s -> pasos por minuto
    _stepTimes.removeWhere((t) => now.difference(t).inSeconds >= 10);
    _cadence = _stepTimes.length * 6.0;

    // Velocidad: GPS si hay señal fresca; si no, cadencia x zancada
    final fresh = _lastFix != null && now.difference(_lastFix!).inSeconds <= 6;
    if (_active && !_paused && fresh) {
      _speedKmh = _gpsSpeedKmh;
    } else if (!(_active && _paused) && _mode != ActivityMode.cycling && _cadence > 0) {
      _speedKmh = _cadence * strideM * 60 / 1000;
    } else {
      _speedKmh = 0;
    }

    if (_active && !_paused) {
      _elapsedSec++;
      // Calorías = MET x peso(kg) x horas  (aquí 1 segundo = 1/3600 h)
      final kcal = HealthCalculator.met(_mode, _speedKmh) * user.weightKg / 3600;
      _wCalories += kcal;
      stats.calories += kcal;
      _dirty = true;
      if (_speedKmh > _maxSpeedKmh && _speedKmh < 80) _maxSpeedKmh = _speedKmh;
    }

    if (_dirty && ++_ticksSinceSave >= 15) _persistDaily();
    notifyListeners();
  }

  // =====================================================================
  //  ENTRENAMIENTO
  // =====================================================================
  Future<void> startWorkout() async {
    if (_user == null || _active) return;
    _resetWorkout();
    _active = true;
    _paused = false;
    _startedAt = DateTime.now();
    notifyListeners();
    await _startSensors();
    await _startGps();
  }

  Future<void> pauseWorkout() async {
    if (!_active || _paused) return;
    _paused = true;
    _speedKmh = 0;
    _gpsStatus = 'Entrenamiento en pausa';
    await _location.stop();
    notifyListeners();
  }

  Future<void> resumeWorkout() async {
    if (!_active || !_paused) return;
    _paused = false;
    _lastPoint = null; // evita sumar el salto de distancia durante la pausa
    _lastPointTime = null;
    notifyListeners();
    await _startGps();
  }

  Future<WorkoutRecord?> finishWorkout() async {
    final user = _user;
    if (user == null || !_active) return null;
    await _location.stop();
    final record = _buildRecord();
    _resetWorkout();
    _speedKmh = 0;
    if (record != null) {
      _workouts.insert(0, record);
      await _storage.addWorkout(user.email, record);
    }
    _persistDaily();
    notifyListeners();
    return record;
  }

  WorkoutRecord? _buildRecord() {
    if (_elapsedSec < 3 && _wSteps == 0) return null;
    final hours = _elapsedSec / 3600;
    final avg = hours > 0 ? (_wDistanceM / 1000) / hours : 0.0;
    return WorkoutRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      date: _startedAt ?? DateTime.now(),
      mode: _mode.name,
      durationSec: _elapsedSec,
      steps: _wSteps,
      distanceM: _wDistanceM,
      calories: _wCalories,
      avgSpeedKmh: avg,
      maxSpeedKmh: _maxSpeedKmh,
    );
  }

  void _resetWorkout() {
    _active = false;
    _paused = false;
    _startedAt = null;
    _elapsedSec = 0;
    _wSteps = 0;
    _wDistanceM = 0;
    _wCalories = 0;
    _maxSpeedKmh = 0;
    _route.clear();
    _lastPoint = null;
    _lastPointTime = null;
    _lastFix = null;
    _gpsSpeedKmh = 0;
    _gpsStatus = null;
    routeTick.value++;
  }

  // =====================================================================
  //  GPS
  // =====================================================================
  Future<void> _startGps() async {
    if (!locationGranted) {
      _gpsStatus = 'Sin permiso de ubicación: la distancia se estima con tus pasos';
      notifyListeners();
      return;
    }
    if (!await _location.isServiceEnabled()) {
      _gpsStatus = 'GPS apagado: enciende la ubicación del teléfono';
      notifyListeners();
      return;
    }
    _gpsStatus = 'Buscando señal GPS…';
    notifyListeners();
    _location.start(
      onPosition: _onPosition,
      onError: (Object error) {
        _gpsStatus = 'No se pudo leer el GPS';
        notifyListeners();
      },
    );
  }

  void _onPosition(Position p) {
    if (!_active || _paused) return;
    if (p.accuracy > 35) {
      _gpsStatus = 'Señal GPS débil (±${p.accuracy.round()} m)';
      notifyListeners();
      return;
    }
    final now = DateTime.now();
    final point = LatLng(p.latitude, p.longitude);
    var speedMs = p.speed > 0 ? p.speed : 0.0;

    final prev = _lastPoint;
    final prevTime = _lastPointTime;
    if (prev != null && prevTime != null) {
      final d = LocationService.distanceMeters(
          prev.latitude, prev.longitude, p.latitude, p.longitude);
      final dt = math.max(0.5, now.difference(prevTime).inMilliseconds / 1000.0);
      final impliedMs = d / dt;
      if (impliedMs > 25) return; // salto imposible (ruido del GPS): se descarta
      if (d >= 2.0) {
        _wDistanceM += d;
        _todayStats().distanceM += d;
        _dirty = true;
        if (speedMs <= 0) speedMs = impliedMs;
      }
    }

    _lastPoint = point;
    _lastPointTime = now;
    _lastFix = now;
    _gpsSpeedKmh = speedMs * 3.6;
    _route.add(point);
    _gpsStatus = 'GPS activo (±${p.accuracy.round()} m)';
    routeTick.value++;
    if (mapReady) {
      try {
        mapController.move(point, mapController.camera.zoom);
      } catch (_) {
        // el mapa aún no está listo: no pasa nada
      }
    }
    notifyListeners();
  }

  // =====================================================================
  //  PERSISTENCIA (RF-06)
  // =====================================================================
  void _persistDaily() {
    final user = _user;
    if (user == null) return;
    _persistDailyFor(user.email);
  }

  void _persistDailyFor(String email) {
    _dirty = false;
    _ticksSinceSave = 0;
    if (_daily.length > 60) {
      final keys = _daily.keys.toList()..sort();
      for (final key in keys.take(_daily.length - 60)) {
        _daily.remove(key);
      }
    }
    unawaited(_storage.saveDaily(email, _daily));
  }
}