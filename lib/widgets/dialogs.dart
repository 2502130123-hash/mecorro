import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/locator.dart';
import '../app/theme.dart';

/// SnackBar flotante de la app. [aboveNav] lo sube para no tapar el menú inferior.
void showAppSnack(
    BuildContext context,
    String message, {
      bool error = false,
      bool aboveNav = false,
      SnackBarAction? action,
    }) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message, style: const TextStyle(color: AppColors.white)),
      backgroundColor: error ? AppColors.danger : AppColors.navy,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(16, 0, 16, aboveNav ? 104 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      action: action,
    ),
  );
}

/// Diálogo con un campo para editar un dato (peso, edad, nombre...).
Future<String?> showEditValueDialog(
    BuildContext context, {
      required String title,
      required String label,
      required String initial,
      IconData? icon,
      String? suffix,
      TextInputType keyboard = TextInputType.text,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator,
      TextCapitalization capitalization = TextCapitalization.none,
    }) {
  final controller = TextEditingController(text: initial);
  final formKey = GlobalKey<FormState>();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Form(
        key: formKey,
        child: TextFormField(
          controller: controller,
          autofocus: true,
          keyboardType: keyboard,
          inputFormatters: formatters,
          textCapitalization: capitalization,
          validator: validator,
          decoration: AppDecor.input(label: label, icon: icon, suffixText: suffix),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              Navigator.pop(ctx, controller.text.trim());
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<String?> showGenderDialog(BuildContext context, String current) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Género'),
      children: [
        for (final g in const ['Masculino', 'Femenino', 'Otro'])
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, g),
            child: Row(
              children: [
                Icon(
                  g == current ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 12),
                Text(g, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Confirmación simple (Sí / No).
Future<bool> showConfirmDialog(
    BuildContext context, {
      required String title,
      required String message,
      required String confirmLabel,
      bool destructive = false,
    }) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? AppColors.danger : AppColors.navy,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Acciones delicadas (cerrar sesión / eliminar cuenta):
/// 1) pregunta "¿Estás seguro?"  2) pide confirmar con huella
/// (o con la contraseña si el teléfono no tiene huella registrada).
class SecurityGate {
  SecurityGate._();

  static Future<bool> confirmSensitiveAction(
      BuildContext context, {
        required String title,
        required String message,
        required String confirmLabel,
        bool destructive = false,
      }) async {
    final accepted = await showConfirmDialog(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      destructive: destructive,
    );
    if (!accepted || !context.mounted) return false;
    return verifyIdentity(context, reason: title);
  }

  static Future<bool> verifyIdentity(BuildContext context, {required String reason}) async {
    final bio = ServiceLocator.biometric;
    if (await bio.isAvailable()) {
      final result = await bio.authenticate('Confirma con tu huella: $reason');
      if (!context.mounted) return false;
      if (result.success) {
        showAppSnack(context, 'Huella verificada correctamente.', aboveNav: true);
        return true;
      }
      showAppSnack(
        context,
        result.message ?? 'No se pudo verificar la huella.',
        error: true,
        aboveNav: true,
      );
      return false;
    }

    // Respaldo: este teléfono no tiene huella registrada -> contraseña
    final password = await _askPassword(context);
    if (password == null || !context.mounted) return false;
    final ok = ServiceLocator.session.verifyPassword(password);
    if (!ok) {
      showAppSnack(context, 'Contraseña incorrecta.', error: true, aboveNav: true);
    }
    return ok;
  }

  static Future<String?> _askPassword(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirma tu identidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Este teléfono no tiene huella registrada. Escribe tu contraseña para continuar.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: AppDecor.input(label: 'Contraseña', icon: Icons.lock_outline),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

/// Flujo de permisos en tiempo de ejecución (RNF-02):
/// primero un diálogo informativo y después las solicitudes del sistema.
class PermissionFlow {
  PermissionFlow._();

  static Future<void> request(BuildContext context) async {
    final workout = ServiceLocator.workout;
    await workout.refreshPermissions();
    if (workout.permissionsOk || !context.mounted) return;

    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permisos necesarios'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('mecorro usa los sensores de tu teléfono para medir tu actividad:'),
            SizedBox(height: 14),
            _PermissionRow(
              icon: Icons.directions_walk_rounded,
              title: 'Actividad física',
              text: 'Para contar tus pasos con el podómetro.',
            ),
            _PermissionRow(
              icon: Icons.my_location_rounded,
              title: 'Ubicación (GPS)',
              text: 'Para calcular distancia y velocidad y dibujar tu ruta.',
            ),
            _PermissionRow(
              icon: Icons.notifications_active_outlined,
              title: 'Notificaciones',
              text: 'Para avisarte mientras registras un recorrido.',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ahora no')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (go != true) return;

    final perms = ServiceLocator.permissions;
    await perms.requestActivity();
    await perms.requestLocation();
    await perms.requestNotifications();
    await workout.onPermissionsChanged();

    if (!context.mounted) return;
    if (!workout.permissionsOk) {
      showAppSnack(
        context,
        'Faltan permisos. Actívalos en Ajustes para usar todos los sensores.',
        error: true,
        aboveNav: true,
        action: SnackBarAction(
          label: 'Ajustes',
          textColor: AppColors.white,
          onPressed: () {
            perms.openSettings();
          },
        ),
      );
    }
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(text, style: const TextStyle(color: AppColors.slate, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}