import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A latitude/longitude rectangle.
class GeoBounds {
  final double south, west, north, east;

  const GeoBounds(this.south, this.west, this.north, this.east);

  /// The square reaching [radiusM] metres north, south, east and west of [centre].
  factory GeoBounds.around(LatLng centre, double radiusM) {
    final dLat = radiusM / 110574.0;
    final dLon = radiusM / (111320.0 * math.cos(centre.latitude * math.pi / 180));
    return GeoBounds(centre.latitude - dLat, centre.longitude - dLon, centre.latitude + dLat, centre.longitude + dLon);
  }

  factory GeoBounds.of(Iterable<LatLng> points) {
    var s = 90.0, w = 180.0, n = -90.0, e = -180.0;
    for (final p in points) {
      s = math.min(s, p.latitude);
      n = math.max(n, p.latitude);
      w = math.min(w, p.longitude);
      e = math.max(e, p.longitude);
    }
    return GeoBounds(s, w, n, e);
  }

  bool intersects(GeoBounds o) => south <= o.north && north >= o.south && west <= o.east && east >= o.west;

  /// The smallest bounds covering both.
  GeoBounds expand(GeoBounds o) => GeoBounds(
      math.min(south, o.south), math.min(west, o.west), math.max(north, o.north), math.max(east, o.east));

  LatLng get centre => LatLng((south + north) / 2, (west + east) / 2);

  @override
  String toString() => 'GeoBounds($south, $west, $north, $east)';
}

typedef TileKey = ({int z, int x, int y});

/// Slippy-map (Web Mercator) tiles covering [bounds] at each zoom in [minZoom]..[maxZoom].
Iterable<TileKey> tilesCovering(GeoBounds bounds, int minZoom, int maxZoom) sync* {
  for (var z = minZoom; z <= maxZoom; z++) {
    final (x0, y0) = _tile(bounds.north, bounds.west, z);
    final (x1, y1) = _tile(bounds.south, bounds.east, z);
    for (var x = x0; x <= x1; x++) {
      for (var y = y0; y <= y1; y++) {
        yield (z: z, x: x, y: y);
      }
    }
  }
}

int countTiles(GeoBounds bounds, int minZoom, int maxZoom) {
  var n = 0;
  for (var z = minZoom; z <= maxZoom; z++) {
    final (x0, y0) = _tile(bounds.north, bounds.west, z);
    final (x1, y1) = _tile(bounds.south, bounds.east, z);
    n += (x1 - x0 + 1) * (y1 - y0 + 1);
  }
  return n;
}

(int, int) _tile(double lat, double lon, int z) {
  final n = 1 << z;
  final latRad = lat.clamp(-85.05112878, 85.05112878) * math.pi / 180;
  final x = ((lon + 180) / 360 * n).floor().clamp(0, n - 1);
  final y = ((1 - math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi) / 2 * n).floor().clamp(0, n - 1);
  return (x, y);
}
