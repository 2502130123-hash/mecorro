import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../controllers/workout_controller.dart';
import '../models/daily_stats.dart';
import '../models/user_profile.dart';
import '../utils/formatters.dart';
import '../utils/health_calculator.dart';
import '../utils/validators.dart';
import '../widgets/app_card.dart';
import '../widgets/dialogs.dart';
import '../widgets/donut_progress.dart';
import '../widgets/metric_tile.dart';

/// Sección 2 (centro): saludo, datos relevantes, IMC automático y datos editables.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = ServiceLocator.session;
    final workout = ServiceLocator.workout;
    return ListenableBuilder(
      listenable: Listenable.merge([session, workout]),
      builder: (context, _) {
        final user = session.currentUser;
        if (user == null) return const SizedBox.shrink();
        final today = workout.today;
        final bmr = HealthCalculator.bmr(
          weightKg: user.weightKg,
          heightCm: user.heightCm,
          age: user.age,
          gender: user.gender,
        );
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _Greeting(name: user.displayName),
            const SizedBox(height: 18),
            const SectionTitle('Meta diaria de pasos', icon: Icons.flag_rounded),
            _GoalCard(
              steps: today.steps,
              calories: today.calories,
              distanceKm: today.distanceM / 1000,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.directions_walk_rounded,
                    value: Formatters.thousands(today.steps),
                    unit: '',
                    label: 'Pasos hoy',
                    color: AppColors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: Icons.local_fire_department_rounded,
                    value: today.calories.toStringAsFixed(0),
                    unit: 'kcal',
                    label: 'Calorías quemadas',
                    color: AppColors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    icon: Icons.insights_rounded,
                    value: Formatters.thousands(workout.averageSteps),
                    unit: '',
                    label: 'Promedio de pasos',
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MetricTile(
                    icon: Icons.route_rounded,
                    value: (today.distanceM / 1000).toStringAsFixed(2),
                    unit: 'km',
                    label: 'Distancia hoy',
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('Índice de masa corporal', icon: Icons.monitor_heart_outlined),
            _BmiCard(bmi: user.bmi),
            const SizedBox(height: 18),
            const SectionTitle('Últimos 7 días', icon: Icons.bar_chart_rounded),
            _WeekChart(bars: workout.last7Days(), goal: WorkoutController.dailyStepGoal),
            const SizedBox(height: 18),
            const SectionTitle('Mis datos (toca para editar)', icon: Icons.edit_outlined),
            _EditableData(user: user, bmr: bmr),
          ],
        );
      },
    );
  }
}

// ======================================================================
class _Greeting extends StatelessWidget {
  const _Greeting({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Hola, $name!',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          Formatters.longDate(DateTime.now()),
          style: const TextStyle(color: AppColors.slate, fontSize: 14),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.steps, required this.calories, required this.distanceKm});

  final int steps;
  final double calories;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    const goal = WorkoutController.dailyStepGoal;
    final progress = steps / goal;
    final percent = (progress * 100).clamp(0, 999).round();
    return AppCard(
      child: Row(
        children: [
          DonutProgress(
            progress: progress,
            size: 142,
            stroke: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Formatters.thousands(steps),
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                Text(
                  '/ ${Formatters.thousands(goal)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.orange,
                  label: 'Calorías',
                  value: '${calories.toStringAsFixed(0)} kcal',
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  icon: Icons.route_rounded,
                  color: AppColors.navy,
                  label: 'Distancia',
                  value: '${distanceKm.toStringAsFixed(2)} km',
                ),
                const SizedBox(height: 12),
                _LegendRow(
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.slate,
                  label: 'Meta',
                  value: '$percent %',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================================
//  IMC
// ======================================================================
class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});

  final double bmi;

  Color _color(BmiCategory c) => switch (c) {
    BmiCategory.underweight => AppColors.slate,
    BmiCategory.normal => AppColors.success,
    BmiCategory.overweight => AppColors.warning,
    BmiCategory.obese => AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final category = HealthCalculator.bmiCategory(bmi);
    final color = _color(category);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bmi.toStringAsFixed(1),
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  HealthCalculator.bmiLabel(category),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BmiScale(bmi: bmi),
          const SizedBox(height: 10),
          const Text(
            'Se calcula con tu peso y estatura y se actualiza solo cuando los editas.',
            style: TextStyle(fontSize: 12.5, color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.bmi});

  final double bmi;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final t = ((bmi - 12) / 28).clamp(0.0, 1.0).toDouble();
        final left = (width * t - 11).clamp(0.0, width - 22).toDouble();
        return Column(
          children: [
            SizedBox(
              height: 22,
              child: Stack(
                children: [
                  Positioned(
                    left: left,
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 22,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(flex: 65, child: Container(height: 10, color: AppColors.slate)),
                  Expanded(flex: 65, child: Container(height: 10, color: AppColors.success)),
                  Expanded(flex: 50, child: Container(height: 10, color: AppColors.warning)),
                  Expanded(flex: 100, child: Container(height: 10, color: AppColors.danger)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('12', style: TextStyle(fontSize: 11, color: AppColors.slate)),
                Text('18.5', style: TextStyle(fontSize: 11, color: AppColors.slate)),
                Text('25', style: TextStyle(fontSize: 11, color: AppColors.slate)),
                Text('30', style: TextStyle(fontSize: 11, color: AppColors.slate)),
                Text('40', style: TextStyle(fontSize: 11, color: AppColors.slate)),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ======================================================================
//  Gráfica semanal
// ======================================================================
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.bars, required this.goal});

  final List<DayBar> bars;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final maxSteps = bars.fold<int>(goal, (m, b) => math.max(m, b.steps));
    return AppCard(
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < bars.length; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 18,
                      height: math.max(4.0, 90.0 * bars[i].steps / maxSteps),
                      decoration: BoxDecoration(
                        color: i == bars.length - 1
                            ? AppColors.orange
                            : AppColors.slate.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Formatters.weekdayInitial(bars[i].date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == bars.length - 1 ? FontWeight.w800 : FontWeight.w500,
                        color: i == bars.length - 1 ? AppColors.orange : AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
//  Datos editables
// ======================================================================
class _EditableData extends StatelessWidget {
  const _EditableData({required this.user, required this.bmr});

  final UserProfile user;
  final double bmr;

  static final List<TextInputFormatter> _decimal = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      child: Column(
        children: [
          _EditRow(
            icon: Icons.badge_outlined,
            label: 'Nombre',
            value: user.name,
            onTap: () => _editName(context),
          ),
          _EditRow(
            icon: Icons.tag_faces_outlined,
            label: 'Apodo',
            value: user.nickname.isEmpty ? 'Sin apodo' : user.nickname,
            onTap: () => _editNickname(context),
          ),
          _EditRow(
            icon: Icons.monitor_weight_outlined,
            label: 'Peso',
            value: '${Formatters.number(user.weightKg)} kg',
            onTap: () => _editWeight(context),
          ),
          _EditRow(
            icon: Icons.height_rounded,
            label: 'Estatura',
            value: '${Formatters.number(user.heightCm)} cm',
            onTap: () => _editHeight(context),
          ),
          _EditRow(
            icon: Icons.cake_outlined,
            label: 'Edad',
            value: '${user.age} años',
            onTap: () => _editAge(context),
          ),
          _EditRow(
            icon: Icons.wc_rounded,
            label: 'Género',
            value: user.gender,
            onTap: () => _editGender(context),
          ),
          const Divider(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.orange),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Metabolismo basal estimado',
                    style: TextStyle(color: AppColors.slate),
                  ),
                ),
                Text(
                  '${bmr.toStringAsFixed(0)} kcal/día',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final value = await showEditValueDialog(
      context,
      title: 'Editar nombre',
      label: 'Nombre completo',
      initial: user.name,
      icon: Icons.badge_outlined,
      capitalization: TextCapitalization.words,
      validator: Validators.name,
    );
    if (value == null || !context.mounted) return;
    await ServiceLocator.session.updateProfile(name: value);
    if (!context.mounted) return;
    showAppSnack(context, 'Nombre actualizado.', aboveNav: true);
  }

  Future<void> _editNickname(BuildContext context) async {
    final value = await showEditValueDialog(
      context,
      title: 'Editar apodo',
      label: 'Apodo (déjalo vacío para quitarlo)',
      initial: user.nickname,
      icon: Icons.tag_faces_outlined,
      capitalization: TextCapitalization.words,
    );
    if (value == null || !context.mounted) return;
    await ServiceLocator.session.updateProfile(nickname: value);
    if (!context.mounted) return;
    showAppSnack(context, 'Apodo actualizado.', aboveNav: true);
  }

  Future<void> _editWeight(BuildContext context) async {
    final value = await showEditValueDialog(
      context,
      title: 'Actualizar peso',
      label: 'Peso',
      initial: Formatters.number(user.weightKg),
      icon: Icons.monitor_weight_outlined,
      suffix: 'kg',
      keyboard: const TextInputType.numberWithOptions(decimal: true),
      formatters: _decimal,
      validator: Validators.weight,
    );
    final weight = Formatters.parseDouble(value);
    if (weight == null || !context.mounted) return;
    await ServiceLocator.session.updateProfile(weightKg: weight);
    if (!context.mounted) return;
    _announceBmi(context, 'Peso actualizado');
  }

  Future<void> _editHeight(BuildContext context) async {
    final value = await showEditValueDialog(
      context,
      title: 'Actualizar estatura',
      label: 'Estatura',
      initial: Formatters.number(user.heightCm),
      icon: Icons.height_rounded,
      suffix: 'cm',
      keyboard: const TextInputType.numberWithOptions(decimal: true),
      formatters: _decimal,
      validator: Validators.height,
    );
    final height = Formatters.parseDouble(value);
    if (height == null || !context.mounted) return;
    await ServiceLocator.session.updateProfile(heightCm: height);
    if (!context.mounted) return;
    _announceBmi(context, 'Estatura actualizada');
  }

  Future<void> _editAge(BuildContext context) async {
    final value = await showEditValueDialog(
      context,
      title: 'Actualizar edad',
      label: 'Edad',
      initial: '${user.age}',
      icon: Icons.cake_outlined,
      suffix: 'años',
      keyboard: TextInputType.number,
      formatters: [FilteringTextInputFormatter.digitsOnly],
      validator: Validators.age,
    );
    final age = int.tryParse(value ?? '');
    if (age == null || !context.mounted) return;
    await ServiceLocator.session.updateProfile(age: age);
    if (!context.mounted) return;
    showAppSnack(context, 'Edad actualizada.', aboveNav: true);
  }

  Future<void> _editGender(BuildContext context) async {
    final value = await showGenderDialog(context, user.gender);
    if (value == null || !context.mounted) return;
    await ServiceLocator.session.updateProfile(gender: value);
    if (!context.mounted) return;
    showAppSnack(context, 'Género actualizado.', aboveNav: true);
  }

  void _announceBmi(BuildContext context, String prefix) {
    final bmi = ServiceLocator.session.currentUser?.bmi ?? 0;
    showAppSnack(
      context,
      '$prefix. Tu IMC ahora es ${bmi.toStringAsFixed(1)}.',
      aboveNav: true,
    );
  }
}

class _EditRow extends StatelessWidget {
  const _EditRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.slate),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppColors.slate)),
            ),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_rounded, size: 18, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}