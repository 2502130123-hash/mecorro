import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../controllers/workout_controller.dart';
import '../models/activity_mode.dart';
import '../models/motion_data.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/metric_tile.dart';
import '../widgets/mode_selector_bar.dart';
import '../widgets/retro.dart';
import '../widgets/route_map.dart';

/// Sección 1 (la que se abre por defecto): selección de actividad + métricas en tiempo real.
/// El carrusel empieza en Caminata; al deslizar a la izquierda pasa a Correr y luego a Ciclismo.
class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workout = ServiceLocator.workout;
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 76, 16, 120),
          child: Column(
            children: [
              const _PermissionBanner(),
              SizedBox(
                height: 210,
                child: PageView(
                  controller: ServiceLocator.modePageController,
                  onPageChanged: (i) => workout.setMode(ActivityMode.values[i]),
                  children: [
                    for (final m in ActivityMode.values) _ModePage(mode: m),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _PageDots(),
              const SizedBox(height: 16),
              const _MetricsGrid(),
              const SizedBox(height: 14),
              const _WorkoutControls(),
              const SizedBox(height: 14),
              const _RouteCard(),
              const SizedBox(height: 14),
              const _SensorsCard(),
            ],
          ),
        ),
        // Menú flotante superior con iconos del modo seleccionado
        const Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: Center(child: ModeSelectorBar()),
        ),
      ],
    );
  }
}

// ======================================================================
//  Aviso de permisos
// ======================================================================
class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner();

  @override
  Widget build(BuildContext context) {
    final workout = ServiceLocator.workout;
    return ListenableBuilder(
      listenable: workout,
      builder: (context, _) {
        if (workout.permissionsOk) return const SizedBox.shrink();
        final missing = <String>[
          if (!workout.activityGranted) 'actividad física',
          if (!workout.locationGranted) 'ubicación',
        ].join(' y ');
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            color: AppColors.orange.withValues(alpha: 0.14),
            child: Row(
              children: [
                const Icon(Icons.privacy_tip_outlined, color: AppColors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Falta el permiso de $missing para medir con todos los sensores.',
                    style: const TextStyle(fontSize: 13, color: AppColors.navy),
                  ),
                ),
                TextButton(
                  onPressed: () => PermissionFlow.request(context),
                  child: const Text(
                    'Conceder',
                    style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ======================================================================
//  Carrusel de modos
// ======================================================================
class _ModePage extends StatelessWidget {
  const _ModePage({required this.mode});

  final ActivityMode mode;

  @override
  Widget build(BuildContext context) {
    final workout = ServiceLocator.workout;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: LcdScreen(
        padding: const EdgeInsets.all(20),
        radius: 18,
        child: Stack(
          children: [
            Positioned(
              right: -6,
              bottom: -6,
              child: Icon(
                mode.icon,
                size: 120,
                color: AppColors.white.withValues(alpha: 0.10),
              ),
            ),
            ListenableBuilder(
              listenable: workout,
              builder: (context, _) {
                final primary = _primary(workout);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(mode.icon, color: AppColors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          mode.label,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: primary.value,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 46,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${primary.unit}',
                                  style: const TextStyle(
                                    color: AppColors.silver,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          primary.label,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.swipe_rounded, color: AppColors.silver, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            mode.hint,
                            style: const TextStyle(color: AppColors.silver, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  ({String value, String unit, String label}) _primary(WorkoutController w) {
    final scope = w.showingSession ? 'SESIÓN' : 'HOY';
    switch (mode) {
      case ActivityMode.walking:
        return (
        value: Formatters.thousands(w.displaySteps),
        unit: 'pasos',
        label: 'PASOS · $scope',
        );
      case ActivityMode.running:
        return (
        value: w.speedKmh.toStringAsFixed(1),
        unit: 'km/h',
        label: 'VELOCIDAD ACTUAL',
        );
      case ActivityMode.cycling:
        return (
        value: w.displayDistanceKm.toStringAsFixed(2),
        unit: 'km',
        label: 'DISTANCIA · $scope',
        );
    }
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    final workout = ServiceLocator.workout;
    return ListenableBuilder(
      listenable: workout,
      builder: (context, _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final m in ActivityMode.values)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: m == workout.mode ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: m == workout.mode
                    ? AppColors.orange
                    : AppColors.silver.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        ],
      ),
    );
  }
}

// ======================================================================
//  Métricas: pasos, velocidad, calorías y distancia
// ======================================================================
class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    final w = ServiceLocator.workout;
    return ListenableBuilder(
      listenable: w,
      builder: (context, _) {
        final scope = w.showingSession ? 'sesión' : 'hoy';
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.directions_walk_rounded,
                    value: Formatters.thousands(w.displaySteps),
                    unit: '',
                    label: 'Pasos · $scope',
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: Icons.speed_rounded,
                    value: w.speedKmh.toStringAsFixed(1),
                    unit: 'km/h',
                    label: 'Velocidad',
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.local_fire_department_rounded,
                    value: w.displayCalories.toStringAsFixed(0),
                    unit: 'kcal',
                    label: 'Calorías · $scope',
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: Icons.route_rounded,
                    value: w.displayDistanceKm.toStringAsFixed(2),
                    unit: 'km',
                    label: 'Distancia · $scope',
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ======================================================================
//  Controles: iniciar / pausar / finalizar
// ======================================================================
class _WorkoutControls extends StatelessWidget {
  const _WorkoutControls();

  @override
  Widget build(BuildContext context) {
    final w = ServiceLocator.workout;
    return AppCard(
      child: ListenableBuilder(
        listenable: w,
        builder: (context, _) {
          final status = !w.isActive ? 'Listo' : (w.isPaused ? 'En pausa' : 'En curso');
          final statusColor = !w.isActive
              ? AppColors.slate
              : (w.isPaused ? AppColors.warning : AppColors.success);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiempo',
                        style: TextStyle(color: AppColors.slate, fontSize: 13),
                      ),
                      LcdScreen(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        radius: 8,
                        child: Text(
                          Formatters.duration(w.elapsedSeconds),
                          style: const TextStyle(
                            fontFamily: RetroStyle.mono,
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!w.isActive)
                ElevatedButton.icon(
                  style: AppDecor.primaryButton(),
                  onPressed: () => _start(context),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: Text('INICIAR ${w.mode.label.toUpperCase()}'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: AppDecor.primaryButton(
                          color: w.isPaused ? AppColors.orange : AppColors.slate,
                        ),
                        onPressed: () => w.isPaused ? w.resumeWorkout() : w.pauseWorkout(),
                        icon: Icon(
                          w.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          size: 26,
                        ),
                        label: Text(w.isPaused ? 'REANUDAR' : 'PAUSAR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: AppDecor.primaryButton(color: AppColors.navy),
                        onPressed: () => _finish(context),
                        icon: const Icon(Icons.stop_rounded, size: 26),
                        label: const Text('FINALIZAR'),
                      ),
                    ),
                  ],
                ),
              if (w.gpsStatus != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      w.gpsFixed ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
                      size: 18,
                      color: w.gpsFixed ? AppColors.success : AppColors.slate,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.gpsStatus!,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _start(BuildContext context) async {
    final w = ServiceLocator.workout;
    if (!w.permissionsOk) await PermissionFlow.request(context);
    if (!context.mounted) return;
    await w.startWorkout();
    if (!context.mounted) return;
    if (!w.locationGranted) {
      showAppSnack(
        context,
        'Sin ubicación: la distancia se estimará con tus pasos.',
        aboveNav: true,
      );
    }
  }

  Future<void> _finish(BuildContext context) async {
    final w = ServiceLocator.workout;
    final ok = await showConfirmDialog(
      context,
      title: '¿Finalizar entrenamiento?',
      message: 'Se guardará en tu historial con la distancia, los pasos y las calorías.',
      confirmLabel: 'Finalizar',
    );
    if (!ok || !context.mounted) return;
    final record = await w.finishWorkout();
    if (!context.mounted) return;
    if (record == null) {
      showAppSnack(context, 'Entrenamiento muy corto: no se guardó.', aboveNav: true);
      return;
    }
    showAppSnack(
      context,
      'Guardado: ${(record.distanceM / 1000).toStringAsFixed(2)} km · '
          '${Formatters.thousands(record.steps)} pasos · '
          '${record.calories.toStringAsFixed(0)} kcal',
      aboveNav: true,
    );
  }
}

// ======================================================================
//  Mapa de la ruta
// ======================================================================
class _RouteCard extends StatelessWidget {
  const _RouteCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Ruta en vivo', icon: Icons.map_outlined),
        AppCard(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(height: 250, child: RouteMap()),
          ),
        ),
      ],
    );
  }
}

// ======================================================================
//  Sensores: acelerómetro, podómetro/zancada y giroscopio
// ======================================================================
class _SensorsCard extends StatelessWidget {
  const _SensorsCard();

  @override
  Widget build(BuildContext context) {
    final w = ServiceLocator.workout;
    return AppCard(
      child: ValueListenableBuilder<MotionData>(
        valueListenable: w.motion,
        builder: (context, m, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors_rounded, color: AppColors.orange),
                  SizedBox(width: 8),
                  Text(
                    'Sensores en tiempo real',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---- Acelerómetro
              _SensorHeader(
                icon: Icons.vibration_rounded,
                title: 'Acelerómetro',
                trailing: m.accelAvailable
                    ? (m.isActive ? 'Activo' : 'Reposo')
                    : 'No disponible',
                trailingColor: m.accelAvailable && m.isActive
                    ? AppColors.success
                    : AppColors.slate,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: m.accelAvailable ? m.intensityLevel : 0,
                  minHeight: 10,
                  backgroundColor: AppColors.silver.withValues(alpha: 0.5),
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Intensidad: ${m.intensityLabel} (${m.intensity.toStringAsFixed(1)} m/s²)',
                style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
              ),
              const Divider(height: 28),

              // ---- Podómetro / zancada
              ListenableBuilder(
                listenable: w,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SensorHeader(
                      icon: Icons.directions_walk_rounded,
                      title: 'Podómetro y zancada',
                      trailing: '${w.cadence.round()} pasos/min',
                      trailingColor: AppColors.navy,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Zancada estimada: ${w.strideM.toStringAsFixed(2)} m · '
                          'Fuente: ${w.stepSourceLabel}',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              const Divider(height: 28),

              // ---- Giroscopio
              _SensorHeader(
                icon: Icons.screen_rotation_alt_rounded,
                title: 'Giroscopio',
                trailing: m.gyroAvailable
                    ? '${m.gyroDegPerSec.toStringAsFixed(0)} °/s'
                    : 'No disponible',
                trailingColor: AppColors.navy,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white,
                      border: Border.all(color: AppColors.silver, width: 2),
                    ),
                    child: Transform.rotate(
                      angle: m.yawDeg * math.pi / 180,
                      child: Icon(
                        Icons.navigation_rounded,
                        size: 36,
                        color: m.turning ? AppColors.orange : AppColors.slate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.turning ? 'Giro detectado' : 'Sin giros bruscos',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: m.turning ? AppColors.orange : AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inclinación: ${m.pitchDeg.toStringAsFixed(0)}° adelante/atrás · '
                              '${m.rollDeg.toStringAsFixed(0)}° lateral',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SensorHeader extends StatelessWidget {
  const _SensorHeader({
    required this.icon,
    required this.title,
    required this.trailing,
    required this.trailingColor,
  });

  final IconData icon;
  final String title;
  final String trailing;
  final Color trailingColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.slate),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Text(
          trailing,
          style: TextStyle(fontWeight: FontWeight.w700, color: trailingColor),
        ),
      ],
    );
  }
}