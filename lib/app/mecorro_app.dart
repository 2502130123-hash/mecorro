import 'package:flutter/material.dart';

import '../screens/home_shell.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import 'locator.dart';
import 'theme.dart';

class MecorroApp extends StatelessWidget {
  const MecorroApp({super.key});

  /// Pantalla inicial:
  ///  - con sesión guardada  -> directo a la app (la sesión solo se cierra si el usuario quiere)
  ///  - con cuentas guardadas -> inicio de sesión
  ///  - sin cuentas           -> formulario de registro
  Widget _initialScreen() {
    final session = ServiceLocator.session;
    if (session.isLoggedIn) return const HomeShell();
    if (session.hasUsers) return LoginScreen(prefillEmail: session.lastUser?.email);
    return RegisterScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mecorro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _initialScreen(),
    );
  }
}