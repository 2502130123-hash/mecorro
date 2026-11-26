import 'package:flutter/material.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../utils/validators.dart';
import '../widgets/auth_header.dart';
import '../widgets/dialogs.dart';
import '../widgets/retro.dart';
import 'home_shell.dart';
import 'register_screen.dart';

class _LoginForm {
  _LoginForm(String? prefillEmail) : email = TextEditingController(text: prefillEmail ?? '');

  final formKey = GlobalKey<FormState>();
  final TextEditingController email;
  final password = TextEditingController();
  final hidePassword = ValueNotifier<bool>(true);
  final loading = ValueNotifier<bool>(false);
}

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key, String? prefillEmail}) : form = _LoginForm(prefillEmail);

  // ignore: library_private_types_in_public_api
  final _LoginForm form;

  @override
  Widget build(BuildContext context) {
    final session = ServiceLocator.session;
    final lastUser = session.lastUser;
    final showBiometric = session.canLoginWithBiometrics && lastUser != null;

    return RetroPage(
      title: 'mecorro / acceso',
      child: Column(
        children: [
          const AuthHeader(
            title: 'Bienvenido de nuevo',
            subtitle: 'Inicia sesión para continuar con tu entrenamiento.',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Form(
              key: form.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: form.email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: AppDecor.input(
                      label: 'Correo electrónico',
                      icon: Icons.alternate_email_rounded,
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  ValueListenableBuilder<bool>(
                    valueListenable: form.hidePassword,
                    builder: (context, hidden, _) => TextFormField(
                      controller: form.password,
                      obscureText: hidden,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(context),
                      decoration: AppDecor.input(
                        label: 'Contraseña',
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.slate,
                          ),
                          onPressed: () => form.hidePassword.value = !hidden,
                        ),
                      ),
                      validator: Validators.loginPassword,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<bool>(
                    valueListenable: form.loading,
                    builder: (context, loading, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          style: AppDecor.primaryButton(),
                          onPressed: loading ? null : () => _submit(context),
                          child: loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.white,
                            ),
                          )
                              : const Text('Iniciar sesión'),
                        ),
                        if (showBiometric) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            style: AppDecor.outlineButton(),
                            onPressed: loading ? null : () => _biometricLogin(context),
                            icon: const Icon(Icons.fingerprint_rounded, size: 28),
                            label: Text('Entrar con huella · ${lastUser.displayName}'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          '¿Aún no tienes cuenta?',
                          style: TextStyle(color: AppColors.slate),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => RegisterScreen()),
                          ),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: AppColors.orange,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------- Inicio con contraseña
  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    if (!(form.formKey.currentState?.validate() ?? false)) return;

    form.loading.value = true;
    final result = await ServiceLocator.session.login(form.email.text, form.password.text);
    form.loading.value = false;
    if (!context.mounted) return;

    if (!result.ok) {
      showAppSnack(context, result.message ?? 'No se pudo iniciar sesión.', error: true);
      return;
    }
    showAppSnack(context, '¡Sesión iniciada correctamente!');

    // Primer inicio de sesión: ofrecer la huella para los siguientes
    if (result.firstLogin) {
      await _offerBiometrics(context);
      if (!context.mounted) return;
    }
    await _enterApp(context);
  }

  Future<void> _offerBiometrics(BuildContext context) async {
    final session = ServiceLocator.session;
    final available = await ServiceLocator.biometric.isAvailable();
    if (!context.mounted) return;

    if (!available) {
      await session.markBiometricPrompted();
      return;
    }

    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.fingerprint_rounded, size: 56, color: AppColors.orange),
        title: const Text('¿Activar acceso con huella?'),
        content: const Text(
          'Es tu primer inicio de sesión. Si lo activas, la próxima vez podrás entrar '
              'a tu perfil con solo tocar el sensor de huella.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, activar'),
          ),
        ],
      ),
    );
    await session.markBiometricPrompted();
    if (accepted != true || !context.mounted) return;

    final result = await ServiceLocator.biometric
        .authenticate('Verifica tu huella para activar el acceso rápido');
    if (!context.mounted) return;
    if (result.success) {
      await session.setBiometricEnabled(true);
      if (!context.mounted) return;
      showAppSnack(context, '¡Huella activada! Ya puedes entrar con ella.');
    } else {
      showAppSnack(
        context,
        result.message ?? 'No se pudo activar la huella.',
        error: true,
      );
    }
  }

  // ------------------------------------------------- Inicio con huella (RF-01)
  Future<void> _biometricLogin(BuildContext context) async {
    final session = ServiceLocator.session;
    final user = session.lastUser;
    if (user == null) return;

    form.loading.value = true;
    final auth = await ServiceLocator.biometric
        .authenticate('Verifica tu identidad para entrar a mecorro');
    form.loading.value = false;
    if (!context.mounted) return;

    if (!auth.success) {
      showAppSnack(context, auth.message ?? 'No se reconoció la huella.', error: true);
      return;
    }
    final result = await session.startSessionForLastUser();
    if (!context.mounted) return;
    if (!result.ok) {
      showAppSnack(context, result.message ?? 'No se pudo iniciar sesión.', error: true);
      return;
    }
    showAppSnack(context, '¡Huella verificada! Hola, ${user.displayName}.');
    await _enterApp(context);
  }

  Future<void> _enterApp(BuildContext context) async {
    await PermissionFlow.request(context);
    if (!context.mounted) return;
    ServiceLocator.resetUi();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeShell()),
          (route) => false,
    );
  }
}