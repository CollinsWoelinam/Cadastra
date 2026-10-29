import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class Fix {
  final LatLng position;

  /// Horizontal accuracy (68% radius) in metres as reported by the receiver.
  final double accuracyM;
  final DateTime time;

  const Fix(this.position, this.accuracyM, this.time);
}

/// Where position fixes come from. The phone's GNSS today; an external RTK
/// receiver (NMEA over Bluetooth) can implement this later.
abstract class PositionSource {
  /// Returns null when ready, or a message explaining why positions are unavailable.
  Future<String?> prepare();

  Stream<Fix> get fixes;
}

class DevicePositionSource implements PositionSource {
  @override
  Future<String?> prepare() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Location services are turned off.';
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => 'Location permission was denied.',
      LocationPermission.deniedForever => 'Location permission is blocked. Enable it in Settings.',
      _ => null,
    };
  }

  @override
  Stream<Fix> get fixes => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 0),
      ).map((p) => Fix(LatLng(p.latitude, p.longitude), p.accuracy, p.timestamp));
}

/// Replays a scripted list of fixes; used by tests and demos.
class ScriptedPositionSource implements PositionSource {
  final List<Fix> script;
  final Duration interval;

  ScriptedPositionSource(this.script, {this.interval = const Duration(milliseconds: 100)});

  @override
  Future<String?> prepare() async => null;

  @override
  Stream<Fix> get fixes async* {
    for (final fix in script) {
      await Future<void>.delayed(interval);
      yield Fix(fix.position, fix.accuracyM, DateTime.now());
    }
  }
}
