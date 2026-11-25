import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/locator.dart';
import 'app/mecorro_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  await ServiceLocator.init();
  runApp(const MecorroApp());
}