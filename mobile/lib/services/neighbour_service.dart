import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../data/db.dart';
import '../geo/tiles.dart';
import 'api_client.dart';

/// Keeps registered parcels around the surveyor cached on the device.
class NeighbourService {
  final AppDatabase db;
  final ApiClient api;

  /// Matches the API's maximum page; a full page means the area was truncated.
  static const pageLimit = 5000;

  NeighbourService(this.db, this.api);

  /// Downloads the approved and pending parcels in [area] into the local cache.
  /// Returns how many were saved, or null if the registry could not be reached
  /// (the cache is then left as it was).
  Future<int?> refresh(GeoBounds area) async {
    try {
      return await _refresh(area);
    } catch (_) {
      // Unreachable, signed out, or an unexpected reply: this runs in the background
      // while the surveyor works, so it must never break the screen.
      return null;
    }
  }

  Future<int> _refresh(GeoBounds area) async {
    final features = await api.parcelsIn(area, limit: pageLimit);
    final now = DateTime.now();
    final rows = <RegisteredParcelsCompanion>[];
    for (final f in features) {
      final props = f['properties'] as Map<String, dynamic>;
      final status = props['status'] as String;
      if (status == 'REJECTED') continue;
      final ring = ((f['geometry'] as Map)['coordinates'] as List).first as List;
      final b = GeoBounds.of([for (final p in ring) _latLng(p as List)]);
      rows.add(RegisteredParcelsCompanion.insert(
        id: props['id'] as String,
        titleDeedNo: props['title_deed_no'] as String,
        ownerName: props['owner_name'] as String,
        status: status,
        ringJson: jsonEncode(ring),
        south: b.south,
        west: b.west,
        north: b.north,
        east: b.east,
        fetchedAt: now,
      ));
    }
    await db.replaceRegisteredParcels(area, rows, complete: features.length < pageLimit);
    return rows.length;
  }
}

LatLng _latLng(List p) => LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble());
