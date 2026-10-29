import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Geodesic measurements for survey-sized polygons on the WGS 84 ellipsoid.
///
/// Vertices are projected onto a local east-north tangent plane at the polygon's
/// centroid (via ECEF), which keeps distortion far below survey accuracy for
/// parcels up to a few kilometres across. This matches PostGIS
/// `ST_Area(geography)` to well under a square centimetre at parcel scale.
class PolygonMath {
  static const _a = 6378137.0;
  static const _f = 1 / 298.257223563;
  static const _e2 = _f * (2 - _f);
  // Vincenty on WGS 84. latlong2 rounds to whole metres unless told not to.
  static const _distance = Distance(roundResult: false);

  static double area(List<LatLng> ring) {
    if (ring.length < 3) return 0;
    final pts = toLocalPlane(ring);
    var sum = 0.0;
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i], q = pts[(i + 1) % pts.length];
      sum += p.x * q.y - q.x * p.y;
    }
    return sum.abs() / 2;
  }

  /// Closed-ring perimeter in metres (includes the closing leg).
  static double perimeter(List<LatLng> ring) {
    if (ring.length < 2) return 0;
    var total = 0.0;
    for (var i = 0; i < ring.length; i++) {
      if (i == ring.length - 1 && ring.length < 3) break;
      total += distance(ring[i], ring[(i + 1) % ring.length]);
    }
    return total;
  }

  static double distance(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

  /// True when any two non-adjacent boundary legs cross (a "bow-tie").
  static bool selfIntersects(List<LatLng> ring) {
    final n = ring.length;
    if (n < 4) return false;
    final pts = toLocalPlane(ring);
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        // Skip legs that share a vertex.
        if (j == i + 1 || (i == 0 && j == n - 1)) continue;
        if (_segmentsCross(pts[i], pts[(i + 1) % n], pts[j], pts[(j + 1) % n])) return true;
      }
    }
    return false;
  }

  static List<math.Point<double>> toLocalPlane(List<LatLng> ring) {
    final lat0 = ring.map((p) => p.latitude).reduce((a, b) => a + b) / ring.length;
    final lon0 = ring.map((p) => p.longitude).reduce((a, b) => a + b) / ring.length;
    final o = _ecef(lat0, lon0);
    final phi = lat0 * math.pi / 180, lam = lon0 * math.pi / 180;
    final sinPhi = math.sin(phi), cosPhi = math.cos(phi);
    final sinLam = math.sin(lam), cosLam = math.cos(lam);
    return ring.map((p) {
      final e = _ecef(p.latitude, p.longitude);
      final dx = e[0] - o[0], dy = e[1] - o[1], dz = e[2] - o[2];
      final east = -sinLam * dx + cosLam * dy;
      final north = -sinPhi * cosLam * dx - sinPhi * sinLam * dy + cosPhi * dz;
      return math.Point(east, north);
    }).toList();
  }

  static List<double> _ecef(double latDeg, double lonDeg) {
    final phi = latDeg * math.pi / 180, lam = lonDeg * math.pi / 180;
    final sinPhi = math.sin(phi);
    final n = _a / math.sqrt(1 - _e2 * sinPhi * sinPhi);
    return [
      n * math.cos(phi) * math.cos(lam),
      n * math.cos(phi) * math.sin(lam),
      n * (1 - _e2) * sinPhi,
    ];
  }

  static bool _segmentsCross(math.Point<double> p1, math.Point<double> p2,
      math.Point<double> p3, math.Point<double> p4) {
    double orient(math.Point<double> a, math.Point<double> b, math.Point<double> c) =>
        (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
    final d1 = orient(p3, p4, p1), d2 = orient(p3, p4, p2);
    final d3 = orient(p1, p2, p3), d4 = orient(p1, p2, p4);
    return ((d1 > 0) != (d2 > 0)) && ((d3 > 0) != (d4 > 0)) &&
        d1 != 0 && d2 != 0 && d3 != 0 && d4 != 0;
  }
}

const sqmPerAcre = 4046.8564224;
const ftPerM = 3.280839895013123;
