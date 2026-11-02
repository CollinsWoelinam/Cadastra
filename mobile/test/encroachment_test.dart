import 'dart:convert';

import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/geo/encroachment.dart';
import 'package:cadastra_field/geo/tiles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'helpers.dart';

/// A w × h rectangle with its south-west corner [x], [y] metres from the origin.
List<LatLng> rect(double x, double y, double w, double h) =>
    [offset(x, y), offset(x + w, y), offset(x + w, y + h), offset(x, y + h)];

RegisteredParcel parcel(String deed, List<LatLng> ring, {String status = 'APPROVED'}) {
  final b = GeoBounds.of(ring);
  return RegisteredParcel(
    id: deed,
    titleDeedNo: deed,
    ownerName: 'Owner',
    status: status,
    ringJson: jsonEncode([for (final p in [...ring, ring.first]) [p.longitude, p.latitude]]),
    south: b.south,
    west: b.west,
    north: b.north,
    east: b.east,
    fetchedAt: DateTime(2026),
  );
}

void main() {
  final neighbour = parcel('GA/1', rect(0, 0, 30, 30));

  test('a shared boundary surveyed exactly is not an overlap', () {
    expect(findEncroachments(rect(30, 0, 30, 30), [neighbour]), isEmpty);
  });

  test('a boundary reaching into an approved parcel is flagged with its depth', () {
    final found = findEncroachments(rect(29.5, 5, 30, 20), [neighbour]);
    expect(found.single.blocking, isTrue);
    expect(found.single.depthM, closeTo(0.5, 0.01));
  });

  test('a parcel wholly inside the new boundary is flagged', () {
    // Depth is the furthest any point reaches in: corner (30, 30) is 20 m from the outer edges.
    final found = findEncroachments(rect(-10, -10, 60, 60), [neighbour]);
    expect(found.single.depthM, closeTo(20, 0.05));
  });

  test('boundaries that cross without corners inside are measured along their edges', () {
    // A tall thin strip across a wide thin one: a plus sign. No corner lies inside the
    // other parcel, but points along the edges reach 2 m in (half the 4 m width).
    final wide = parcel('GA/W', rect(0, 10, 30, 4));
    final found = findEncroachments(rect(12, 0, 4, 30), [wide]);
    expect(found.single.depthM, closeTo(2, 0.02));
  });

  test('a corner strip overlap is measured even with every corner on an edge line', () {
    final found = findEncroachments(rect(29.5, 0, 30, 30), [neighbour]);
    expect(found.single.depthM, closeTo(0.5, 0.01));
  });

  test('corners are checked while walking, before the boundary closes', () {
    expect(findEncroachments([offset(-5, 5), offset(3, 5)], [neighbour]).single.depthM, closeTo(3, 0.02));
    expect(findEncroachments([offset(-5, 5), offset(-1, 5)], [neighbour]), isEmpty);
  });

  test('approved overlaps sort before pending ones', () {
    final pending = parcel('GA/P', rect(-20, 0, 15, 30), status: 'PENDING');
    final found = findEncroachments(rect(-10, 5, 15, 10), [pending, neighbour]);
    expect([for (final e in found) e.parcel.titleDeedNo], ['GA/1', 'GA/P']);
    expect(found.last.blocking, isFalse);
  });

  test('distant parcels are ignored', () {
    expect(findEncroachments(rect(500, 500, 30, 30), [neighbour]), isEmpty);
  });

  group('tiles', () {
    test('an area is covered at every zoom', () {
      final area = GeoBounds.around(origin, 1000);
      final tiles = tilesCovering(area, 13, 19).toList();
      expect(tiles.length, countTiles(area, 13, 19));
      expect(tiles.map((t) => t.z).toSet(), {13, 14, 15, 16, 17, 18, 19});
      // ~76 m tiles at z19 near the equator: a 2 km square needs ~27 across.
      final z19 = tiles.where((t) => t.z == 19);
      final across = z19.map((t) => t.x).toSet().length;
      expect(across, inInclusiveRange(27, 29));
    });

    test('around() spans the requested distance', () {
      final b = GeoBounds.around(origin, 500);
      expect(const Distance().as(LengthUnit.Meter, LatLng(b.south, b.west), LatLng(b.south, b.east)), closeTo(1000, 5));
      expect(const Distance().as(LengthUnit.Meter, LatLng(b.south, b.west), LatLng(b.north, b.west)), closeTo(1000, 5));
    });
  });
}
