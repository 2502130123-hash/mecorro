import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/locator.dart';
import '../app/theme.dart';
import '../utils/formatters.dart';
import '../utils/validators.dart';
import '../widgets/app_card.dart';
import '../widgets/auth_header.dart';
import '../widgets/dialogs.dart';
import '../widgets/password_strength_meter.dart';
import 'login_screen.dart';

/// Estado del formulario. Como la pantalla es StatelessWidget, los controladores
/// viven en este objeto (ValueNotifier / TextEditingController) y la UI escucha con
/// ValueListenableBuilder.
class _RegisterForm {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final nickname = TextEditingController();
  final email = TextEditingController();
  final weight = TextEditingController();
  final height = TextEditingController();
  final age = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final gender = ValueNotifier<String>('Masculino');
  final hidePassword = ValueNotifier<bool>(true); // oculta por defecto
  final hideConfirm = ValueNotifier<bool>(true);
  final loading = ValueNotifier<bool>(false);
}

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key}) : form = _RegisterForm();

  final _RegisterForm form;

  static final List<TextInputFormatter> _decimalOnly = [
    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
  ];
  static final List<TextInputFormatter> _digitsOnly = [
    FilteringTextInputFormatter.digitsOnly,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          children: [
            const AuthHeader(
              title: 'Crea tu cuenta',
              subtitle:
              'Con tus datos calculamos tus pasos, calorías e IMC con más precisión.',
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
              child: Form(
                key: form.formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Datos personales', icon: Icons.person_outline),
                    AppCard(child: _personalFields()),
                    const SizedBox(height: 18),
                    const SectionTitle('Datos físicos', icon: Icons.monitor_weight_outlined),
                    AppCard(child: _bodyFields()),
                    const SizedBox(height: 18),
                    const SectionTitle('Seguridad', icon: Icons.lock_outline),
                    AppCard(child: _securityFields()),
                    const SizedBox(height: 24),
                    ValueListenableBuilder<bool>(
                      valueListenable: form.loading,
                      builder: (context, loading, _) => ElevatedButton(
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
                            : const Text('Crear cuenta'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes una cuenta?',
                            style: TextStyle(color: AppColors.slate),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => LoginScreen(
                                  prefillEmail: ServiceLocator.session.lastUser?.email,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Iniciar sesión',
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
      ),
    );
  }

  // ------------------------------------------------------------ Secciones
  Widget _personalFields() {
    return Column(
      children: [
        TextFormField(
          controller: form.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: AppDecor.input(label: 'Nombre completo', icon: Icons.badge_outlined),
          validator: Validators.name,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: form.nickname,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: AppDecor.input(
            label: 'Apodo (opcional)',
            hint: 'Así te saludaremos',
            icon: Icons.tag_faces_outlined,
          ),
        ),
        const SizedBox(height: 14),
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
      ],
    );
  }

  Widget _bodyFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: form.weight,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimalOnly,
                textInputAction: TextInputAction.next,
                decoration: AppDecor.input(
                  label: 'Peso',
                  icon: Icons.monitor_weight_outlined,
                  suffixText: 'kg',
                ),
                validator: Validators.weight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: form.height,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimalOnly,
                textInputAction: TextInputAction.next,
                decoration: AppDecor.input(
                  label: 'Estatura',
                  icon: Icons.height_rounded,
                  suffixText: 'cm',
                ),
                validator: Validators.height,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: form.age,
          keyboardType: TextInputType.number,
          inputFormatters: _digitsOnly,
          textInputAction: TextInputAction.next,
          decoration: AppDecor.input(
            label: 'Edad',
            icon: Icons.cake_outlined,
            suffixText: 'años',
          ),
          validator: Validators.age,
        ),
        const SizedBox(height: 16),
        const Text(
          'Género',
          style: TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<String>(
          valueListenable: form.gender,
          builder: (context, gender, _) => SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.orange,
                selectedForegroundColor: AppColors.white,
                foregroundColor: AppColors.slate,
              ),
              segments: const [
                ButtonSegment<String>(value: 'Masculino', label: Text('Hombre')),
                ButtonSegment<String>(value: 'Femenino', label: Text('Mujer')),
                ButtonSegment<String>(value: 'Otro', label: Text('Otro')),
              ],
              selected: {gender},
              onSelectionChanged: (selection) => form.gender.value = selection.first,
            ),
          ),
        ),
      ],
    );
  }

  Widget _securityFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contraseña (oculta por defecto + icono de ojo)
        ValueListenableBuilder<bool>(
          valueListenable: form.hidePassword,
          builder: (context, hidden, _) => TextFormField(
            controller: form.password,
            obscureText: hidden,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            decoration: AppDecor.input(
              label: 'Contraseña',
              icon: Icons.lock_outline,
              suffix: IconButton(
                tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.slate,
                ),
                onPressed: () => form.hidePassword.value = !hidden,
              ),
            ),
            validator: Validators.password,
          ),
        ),
        const SizedBox(height: 12),
        // Semáforo + requisitos, se actualizan al escribir cada carácter
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: form.password,
          builder: (context, value, _) =>
              PasswordStrengthMeter(report: PasswordValidator.evaluate(value.text)),
        ),
        const SizedBox(height: 16),
        // Confirmación
        ValueListenableBuilder<bool>(
          valueListenable: form.hideConfirm,
          builder: (context, hidden, _) => TextFormField(
            controller: form.confirm,
            obscureText: hidden,
            enableSuggestions: false,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            decoration: AppDecor.input(
              label: 'Confirmar contraseña',
              icon: Icons.lock_reset_rounded,
              suffix: IconButton(
                tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                icon: Icon(
                  hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AppColors.slate,
                ),
                onPressed: () => form.hideConfirm.value = !hidden,
              ),
            ),
            validator: (v) => Validators.confirm(v, form.password.text),
          ),
        ),
        const SizedBox(height: 8),
        // Indicador en vivo de coincidencia
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: form.confirm,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            final match = value.text == form.password.text;
            return Row(
              children: [
                Icon(
                  match ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 17,
                  color: match ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: 6),
                Text(
                  match ? 'Las contraseñas coinciden' : 'Las contraseñas no coinciden',
                  style: TextStyle(
                    fontSize: 13,
                    color: match ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------- Acción
  Future<void> _submit(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final valid = form.formKey.currentState?.validate() ?? false;
    if (!valid) {
      showAppSnack(context, 'Revisa los campos marcados en rojo.', error: true);
      return;
    }
    form.loading.value = true;
    final email = form.email.text.trim();
    final error = await ServiceLocator.session.register(
      name: form.name.text,
      nickname: form.nickname.text,
      email: email,
      password: form.password.text,
      weightKg: Formatters.parseDouble(form.weight.text) ?? 70,
      heightCm: Formatters.parseDouble(form.height.text) ?? 170,
      age: int.tryParse(form.age.text.trim()) ?? 25,
      gender: form.gender.value,
    );
    form.loading.value = false;
    if (!context.mounted) return;
    if (error != null) {
      showAppSnack(context, error, error: true);
      return;
    }
    showAppSnack(context, '¡Cuenta creada! Ahora inicia sesión.');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen(prefillEmail: email.toLowerCase())),
    );
  }
}