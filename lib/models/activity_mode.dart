import 'package:flutter/material.dart';

/// Tipos de ejercicio. El orden define el orden del carrusel:
/// caminata -> (deslizar izquierda) correr -> (deslizar izquierda) ciclismo.
enum ActivityMode { walking, running, cycling }

extension ActivityModeX on ActivityMode {
  String get label => switch (this) {
    ActivityMode.walking => 'Caminata',
    ActivityMode.running => 'Correr',
    ActivityMode.cycling => 'Ciclismo',
  };

  IconData get icon => switch (this) {
    ActivityMode.walking => Icons.directions_walk_rounded,
    ActivityMode.running => Icons.directions_run_rounded,
    ActivityMode.cycling => Icons.directions_bike_rounded,
  };

  String get hint => switch (this) {
    ActivityMode.walking => 'Desliza a la izquierda para correr',
    ActivityMode.running => 'Desliza a la izquierda para ciclismo',
    ActivityMode.cycling => 'Desliza a la derecha para volver',
  };
}