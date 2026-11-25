import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../models/activity_mode.dart';
import '../models/profile_change.dart';
import '../models/user_profile.dart';
import '../models/workout_record.dart';
import '../utils/formatters.dart';
import '../widgets/app_card.dart';
import '../widgets/dialogs.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Sección 3: cronograma de cambios, entrenamientos y opciones de cuenta
/// (huella, cerrar sesión y eliminar cuenta con confirmación biométrica).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = ServiceLocator.session;
    final workout = ServiceLocator.workout;
    return ListenableBuilder(
      listenable: Listenable.merge([session, workout]),
      builder: (context, _) {
        final user = session.currentUser;
        if (user == null) return const SizedBox.shrink();
        final changes = session.changes;
        final workouts = workout.history;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            const Text(
              'Historial',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            const SectionTitle('Cuenta y seguridad', icon: Icons.shield_outlined),
            _AccountCard(user: user),
            const SizedBox(height: 18),
            const SectionTitle('Cronograma de cambios', icon: Icons.timeline_rounded),
            if (changes.isEmpty)
              const AppCard(
                child: Text(
                  'Aún no hay cambios. Edita tus datos en el perfil y aparecerán aquí.',
                  style: TextStyle(color: AppColors.slate),
                ),
              )
            else
              for (var i = 0; i < changes.length; i++)
                _TimelineItem(change: changes[i], isLast: i == changes.length - 1),
            const SizedBox(height: 18),
            const SectionTitle('Entrenamientos', icon: Icons.fitness_center_rounded),
            if (workouts.isEmpty)
              const AppCard(
                child: Text(
                  'Todavía no has terminado ningún entrenamiento. '
                      'Inicia uno en la pestaña Actividad.',
                  style: TextStyle(color: AppColors.slate),
                ),
              )
            else
              for (final record in workouts.take(30))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WorkoutTile(record: record),
                ),
          ],
        );
      },
    );
  }
}

// ======================================================================
//  Cuenta
// ======================================================================
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.fingerprint_rounded, color: AppColors.orange, size: 30),
            title: const Text('Acceso con huella', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              user.biometricEnabled
                  ? 'Activado para tus próximos inicios de sesión'
                  : 'Desactivado',
              style: const TextStyle(fontSize: 12.5),
            ),
            value: user.biometricEnabled,
            onChanged: (value) => _toggleBiometric(context, value),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.logout_rounded, color: AppColors.slate),
            title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
            onTap: () => _logout(context),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            title: const Text(
              'Eliminar cuenta',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.danger),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleBiometric(BuildContext context, bool enable) async {
    final session = ServiceLocator.session;
    final bio = ServiceLocator.biometric;

    if (enable) {
      if (!await bio.isAvailable()) {
        if (!context.mounted) return;
        showAppSnack(
          context,
          'Este teléfono no tiene huella registrada. Agrégala en Ajustes del sistema.',
          error: true,
          aboveNav: true,
        );
        return;
      }
      final result = await bio.authenticate('Verifica tu huella para activar el acceso rápido');
      if (!context.mounted) return;
      if (!result.success) {
        showAppSnack(
          context,
          result.message ?? 'No se pudo activar la huella.',
          error: true,
          aboveNav: true,
        );
        return;
      }
      await session.setBiometricEnabled(true);
      if (!context.mounted) return;
      showAppSnack(context, '¡Huella activada!', aboveNav: true);
    } else {
      final ok = await SecurityGate.verifyIdentity(
        context,
        reason: 'Desactivar el acceso con huella',
      );
      if (!ok || !context.mounted) return;
      await session.setBiometricEnabled(false);
      if (!context.mounted) return;
      showAppSnack(context, 'Acceso con huella desactivado.', aboveNav: true);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await SecurityGate.confirmSensitiveAction(
      context,
      title: 'Cerrar sesión',
      message: '¿Estás seguro de que quieres cerrar tu sesión? '
          'Para volver a entrar necesitarás tu contraseña o tu huella.',
      confirmLabel: 'Cerrar sesión',
    );
    if (!ok || !context.mounted) return;

    await ServiceLocator.session.logout();
    ServiceLocator.resetUi();
    if (!context.mounted) return;
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(prefillEmail: ServiceLocator.session.lastUser?.email),
      ),
          (route) => false,
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final ok = await SecurityGate.confirmSensitiveAction(
      context,
      title: 'Eliminar cuenta',
      message: '¿Estás seguro? Se borrarán tu perfil, tu historial y tus entrenamientos '
          'de este teléfono. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!ok || !context.mounted) return;

    final session = ServiceLocator.session;
    await session.deleteAccount();
    ServiceLocator.resetUi();
    if (!context.mounted) return;
    final Widget next = session.hasUsers
        ? LoginScreen(prefillEmail: session.lastUser?.email)
        : RegisterScreen();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => next),
          (route) => false,
    );
  }
}

// ======================================================================
//  Cronograma
// ======================================================================
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.change, required this.isLast});

  final ProfileChange change;
  final bool isLast;

  IconData get _icon => switch (change.field) {
    'Peso' => Icons.monitor_weight_outlined,
    'Estatura' => Icons.height_rounded,
    'Edad' => Icons.cake_outlined,
    'IMC' => Icons.monitor_heart_outlined,
    'Género' => Icons.wc_rounded,
    'Nombre' => Icons.badge_outlined,
    'Apodo' => Icons.tag_faces_outlined,
    'Acceso con huella' => Icons.fingerprint_rounded,
    _ => Icons.person_add_alt_1_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                    boxShadow: [BoxShadow(color: AppColors.softShadow, blurRadius: 4)],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.silver.withValues(alpha: 0.7)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    Icon(_icon, color: AppColors.slate),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            change.field,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          if (change.oldValue.isEmpty)
                            Text(change.newValue, style: const TextStyle(color: AppColors.slate))
                          else
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: change.oldValue,
                                    style: const TextStyle(
                                      color: AppColors.slate,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const TextSpan(text: '  →  '),
                                  TextSpan(
                                    text: change.newValue,
                                    style: const TextStyle(
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            Formatters.dateTime(change.date),
                            style: const TextStyle(fontSize: 12, color: AppColors.slate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
//  Entrenamientos guardados
// ======================================================================
class _WorkoutTile extends StatelessWidget {
  const _WorkoutTile({required this.record});

  final WorkoutRecord record;

  @override
  Widget build(BuildContext context) {
    final mode = ActivityMode.values.asNameMap()[record.mode] ?? ActivityMode.walking;
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(mode.icon, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${mode.label} · ${(record.distanceM / 1000).toStringAsFixed(2)} km',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateTime(record.date),
                  style: const TextStyle(fontSize: 12, color: AppColors.slate),
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.duration(record.durationSec)} · '
                      '${Formatters.thousands(record.steps)} pasos · '
                      '${record.calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.avgSpeedKmh.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Text('km/h', style: TextStyle(fontSize: 11, color: AppColors.slate)),
            ],
          ),
        ],
      ),
    );
  }
}