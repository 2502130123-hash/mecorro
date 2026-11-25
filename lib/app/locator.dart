import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import '../controllers/workout_controller.dart';
import '../models/activity_mode.dart';
import '../services/biometric_service.dart';
import '../services/location_service.dart';
import '../services/permission_service.dart';
import '../services/sensor_service.dart';
import '../services/storage_service.dart';

/// Localizador de servicios muy sencillo (sin paquetes extra).
/// Como todas las pantallas son StatelessWidget, el estado vive aquí, en objetos
/// que notifican cambios (ChangeNotifier / ValueNotifier) y las pantallas se
/// redibujan con ListenableBuilder / ValueListenableBuilder.
class ServiceLocator {
  ServiceLocator._();

  static late final StorageService storage;
  static late final BiometricService biometric;
  static late final PermissionService permissions;
  static late final SessionController session;
  static late final WorkoutController workout;

  /// Pestaña actual del menú flotante inferior (0 = Actividad, 1 = Perfil, 2 = Historial).
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  /// Controla el carrusel Caminata / Correr / Ciclismo.
  static final PageController modePageController = PageController();

  static String? _attachedEmail;

  static Future<void> init() async {
    storage = await StorageService.create();
    biometric = BiometricService();
    permissions = PermissionService();
    session = SessionController(storage: storage);
    workout = WorkoutController(
      storage: storage,
      permissions: permissions,
      sensors: SensorService(),
      location: LocationService(),
    );
    await session.load();
    session.addListener(_syncWorkout);
    _syncWorkout();
  }

  /// Conecta / desconecta el WorkoutController según haya sesión activa.
  static void _syncWorkout() {
    final user = session.currentUser;
    if (user == null) {
      if (_attachedEmail != null) {
        _attachedEmail = null;
        workout.detach();
      }
    } else if (_attachedEmail != user.email) {
      _attachedEmail = user.email;
      workout.attach(user);
    } else {
      workout.updateUser(user);
    }
  }

  /// Deja la interfaz lista para una nueva sesión (pestaña inicial y modo caminata).
  static void resetUi() {
    tabIndex.value = 0;
    workout.setMode(ActivityMode.walking);
    if (modePageController.hasClients) modePageController.jumpToPage(0);
  }
}