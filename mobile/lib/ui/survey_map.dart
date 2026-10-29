import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../location/position_source.dart';

const _accra = LatLng(5.6037, -0.1870);

class SurveyMap extends StatelessWidget {
  final MapController? controller;
  final List<LatLng> boundary;
  final List<List<LatLng>> conflicts;
  final Fix? position;
  final VoidCallback? onMapReady;

  const SurveyMap(
      {super.key, this.controller, required this.boundary, this.conflicts = const [], this.position, this.onMapReady});

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).colorScheme.primary;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: position?.position ?? (boundary.isNotEmpty ? boundary.first : _accra),
        initialZoom: 18,
        maxZoom: 21,
        onMapReady: onMapReady,
        initialCameraFit: boundary.length >= 2
            ? CameraFit.coordinates(coordinates: boundary, padding: const EdgeInsets.all(56), maxZoom: 20)
            : null,
      ),
      children: [
        if (Services.of(context).showBasemap)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.cadastra.cadastra_field',
            maxNativeZoom: 19,
          ),
        PolygonLayer(polygons: [
          if (boundary.length >= 3)
            Polygon(points: boundary, color: blue.withValues(alpha: 0.15), borderColor: blue, borderStrokeWidth: 3),
          for (final ring in conflicts)
            Polygon(points: ring, color: Colors.red.withValues(alpha: 0.5), borderColor: Colors.red.shade900, borderStrokeWidth: 1.5),
        ]),
        if (boundary.length == 2)
          PolylineLayer(polylines: [Polyline(points: boundary, color: blue, strokeWidth: 3)]),
        if (position != null)
          CircleLayer(circles: [
            CircleMarker(
              point: position!.position,
              radius: position!.accuracyM,
              useRadiusInMeter: true,
              color: Colors.lightBlue.withValues(alpha: 0.2),
              borderColor: Colors.lightBlue,
              borderStrokeWidth: 1,
            ),
          ]),
        MarkerLayer(markers: [
          // Numbers help with a few corners; a dense walked trail gets plain dots.
          for (final (i, p) in boundary.indexed)
            boundary.length <= 12
                ? Marker(point: p, width: 22, height: 22, child: _NodeLabel(i + 1, blue))
                : Marker(point: p, width: 8, height: 8, child: _NodeDot(blue)),
          if (position != null)
            Marker(
              point: position!.position,
              width: 18,
              height: 18,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.lightBlue.shade600,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
                ),
              ),
            ),
        ]),
        // flutter_map's SimpleAttributionWidget overflows on phone-width maps.
        if (Services.of(context).showBasemap)
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              color: Colors.white70,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
            ),
          ),
      ],
    );
  }
}

class _NodeLabel extends StatelessWidget {
  final int number;
  final Color color;

  const _NodeLabel(this.number, this.color);

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
}

class _NodeDot extends StatelessWidget {
  final Color color;

  const _NodeDot(this.color);

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white)),
      );
}
