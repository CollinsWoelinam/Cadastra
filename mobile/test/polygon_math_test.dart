import 'package:cadastra_field/geo/polygon_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// Corners of seeded parcel GA/EL/2001 and the values PostGIS computed for it
// (ST_Area / ST_Perimeter on geography).
final ga2001 = [
  const LatLng(5.6232781, -0.1706916),
  const LatLng(5.6232768, -0.1704210),
  const LatLng(5.6236020, -0.1704194),
  const LatLng(5.6236033, -0.1706900),
];

void main() {
  test('area matches PostGIS geography area', () {
    // Corner coordinates above are rounded to 1e-7° (~1 cm), hence the tolerance.
    expect(PolygonMath.area(ga2001), closeTo(1078.24, 0.5));
  });

  test('perimeter matches PostGIS geography perimeter', () {
    expect(PolygonMath.perimeter(ga2001), closeTo(131.89, 0.05));
  });

  test('area is independent of vertex order', () {
    expect(PolygonMath.area(ga2001.reversed.toList()), closeTo(PolygonMath.area(ga2001), 1e-9));
  });

  test('fewer than three vertices has no area', () {
    expect(PolygonMath.area(ga2001.take(2).toList()), 0);
    expect(PolygonMath.perimeter(ga2001.take(2).toList()), closeTo(29.976, 0.01));
  });

  test('detects a bow-tie boundary', () {
    final bowtie = [ga2001[0], ga2001[2], ga2001[1], ga2001[3]];
    expect(PolygonMath.selfIntersects(bowtie), isTrue);
    expect(PolygonMath.selfIntersects(ga2001), isFalse);
  });

  test('large plot stays accurate (1 km square near Kumasi)', () {
    // ~1 km square: 0.009043° lat × 0.009043/cos(6.7°) lon.
    const lat = 6.7, lon = -1.62;
    final dLat = 0.009043, dLon = 0.009043 / 0.99317;
    final square = [
      const LatLng(lat, lon),
      LatLng(lat, lon + dLon),
      LatLng(lat + dLat, lon + dLon),
      LatLng(lat + dLat, lon),
    ];
    final side = PolygonMath.distance(square[0], square[3]);
    expect(PolygonMath.area(square), closeTo(side * PolygonMath.distance(square[0], square[1]), 50));
  });
}
