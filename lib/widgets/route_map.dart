import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app/locator.dart';
import '../app/theme.dart';

/// Mapa interactivo (OpenStreetMap) con la ruta recorrida dibujada en tiempo real (RF-05).
/// Solo se redibuja cuando llega un punto GPS nuevo (routeTick).
class RouteMap extends StatelessWidget {
  const RouteMap({super.key});

  static const LatLng _defaultCenter = LatLng(19.4326, -99.1332);

  @override
  Widget build(BuildContext context) {
    final workout = ServiceLocator.workout;
    return ValueListenableBuilder<int>(
      valueListenable: workout.routeTick,
      builder: (context, _, __) {
        final route = workout.route;
        final current = workout.lastPoint;
        return Stack(
          children: [
            FlutterMap(
              mapController: workout.mapController,
              options: MapOptions(
                initialCenter: current ?? _defaultCenter,
                initialZoom: current == null ? 5 : 16,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () => workout.mapReady = true,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.mecorro',
                ),
                if (route.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route,
                        strokeWidth: 5,
                        color: AppColors.orange,
                      ),
                    ],
                  ),
                if (current != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: current,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.orange.withValues(alpha: 0.25),
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.white, width: 3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SimpleAttributionWidget(
                  source: Text('© OpenStreetMap contributors'),
                ),
              ],
            ),
            if (route.isEmpty)
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Inicia una actividad para dibujar tu ruta en el mapa',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.white, fontSize: 12.5),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}