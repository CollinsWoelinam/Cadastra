import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../data/db.dart';
import 'polygon_math.dart';
import 'tiles.dart';

/// A captured boundary overlapping a parcel already in the registry.
class Encroachment {
  final RegisteredParcel parcel;

  /// How far the two boundaries reach into each other, in metres. Zero when the
  /// boundary lines cross without either one's corners lying inside the other.
  final double depthM;

  const Encroachment(this.parcel, this.depthM);

  /// An approved parcel; the registry will refuse to approve the new survey.
  bool get blocking => parcel.status == 'APPROVED';
}

/// Registered parcels that [boundary] overlaps, worst first.
///
/// A rough on-device check to warn the surveyor while still on site; the Core
/// Engine measures the exact overlap on upload. Corners within [toleranceM] of a
/// neighbour's edge are not counted, so a shared boundary surveyed point for
/// point is not flagged.
List<Encroachment> findEncroachments(List<LatLng> boundary, List<RegisteredParcel> parcels,
    {double toleranceM = 0.01}) {
  if (boundary.isEmpty) return const [];
  // ~10 m margin: cheap pre-filter before projecting.
  final b = GeoBounds.of(boundary);
  final near = GeoBounds(b.south - 1e-4, b.west - 1e-4, b.north + 1e-4, b.east + 1e-4);
  final found = <Encroachment>[];
  for (final parcel in parcels) {
    final ring = parcel.ring;
    if (ring.length < 3 || !GeoBounds.of(ring).intersects(near)) continue;
    final pts = PolygonMath.toLocalPlane([...boundary, ...ring]);
    final ours = pts.sublist(0, boundary.length), theirs = pts.sublist(boundary.length);
    final closed = ours.length >= 3;

    var depth = 0.0;
    var overlaps = false;
    void inside(math.Point<double> p, List<math.Point<double>> polygon) {
      if (!pointInPolygon(p, polygon)) return;
      final d = distanceToRing(p, polygon);
      if (d <= toleranceM) return;
      overlaps = true;
      depth = math.max(depth, d);
    }

    // Points along the edges too, not only corners: a strip overlap can have every
    // corner exactly on the other parcel's edge lines.
    for (final p in _densify(ours, closed: closed)) {
      inside(p, theirs);
    }
    if (closed) {
      for (final p in _densify(theirs, closed: true)) {
        inside(p, ours);
      }
    }
    if (!overlaps && ours.length >= 2) {
      final legs = closed ? ours.length : ours.length - 1;
      outer:
      for (var i = 0; i < legs; i++) {
        for (var j = 0; j < theirs.length; j++) {
          if (PolygonMath.segmentsCross(ours[i], ours[(i + 1) % ours.length], theirs[j], theirs[(j + 1) % theirs.length])) {
            overlaps = true;
            break outer;
          }
        }
      }
    }
    if (overlaps) found.add(Encroachment(parcel, depth));
  }
  found.sort((a, b) => a.blocking != b.blocking ? (a.blocking ? -1 : 1) : b.depthM.compareTo(a.depthM));
  return found;
}

/// The ring's corners plus points at most ~1 m apart along its edges (at most 50 per edge).
List<math.Point<double>> _densify(List<math.Point<double>> pts, {required bool closed}) {
  final out = <math.Point<double>>[];
  final legs = closed ? pts.length : pts.length - 1;
  for (var i = 0; i < legs; i++) {
    final a = pts[i], b = pts[(i + 1) % pts.length];
    final n = math.min(a.distanceTo(b).floor(), 50);
    for (var k = 0; k < math.max(n, 1); k++) {
      final t = k / math.max(n, 1);
      out.add(math.Point(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t));
    }
  }
  if (!closed) out.add(pts.last);
  return out;
}
