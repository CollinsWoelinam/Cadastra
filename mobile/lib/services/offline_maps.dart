import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../data/db.dart';
import '../geo/tiles.dart';
import '../map/tile_store.dart';
import 'neighbour_service.dart';

/// Saves areas for offline fieldwork: registered parcels always, basemap tiles when
/// the provider allows bulk download.
class OfflineMaps extends ChangeNotifier {
  final AppDatabase db;
  final NeighbourService neighbours;

  /// Null when basemap tiles may not be saved (see [basemapAllowsOfflineDownload]).
  final TileStore? tiles;

  static const minZoom = 13;
  static const maxZoom = 19;

  /// Rough size of a raster tile, for estimates before downloading.
  static const avgTileBytes = 15 * 1024;
  static const maxTiles = 12000;

  OfflineMaps(this.db, this.neighbours, this.tiles);

  bool get savesTiles => tiles != null;

  /// Progress of the download in flight, if any.
  ({int done, int total})? progress;
  bool _cancel = false;

  bool get downloading => progress != null;

  int tileCount(GeoBounds area) => savesTiles ? countTiles(area, minZoom, maxZoom) : 0;

  void cancel() => _cancel = true;

  /// Saves [area]; returns a one-line summary for the surveyor.
  Future<String> download(String name, GeoBounds area) async {
    if (downloading) throw StateError('a download is already running');
    _cancel = false;
    progress = (done: 0, total: tileCount(area));
    notifyListeners();
    final id = await db.into(db.offlineAreas).insert(OfflineAreasCompanion.insert(
          name: name,
          south: area.south,
          west: area.west,
          north: area.north,
          east: area.east,
          minZoom: minZoom,
          maxZoom: maxZoom,
          tileSource: Value(tiles?.urlTemplate),
          updatedAt: DateTime.now(),
        ));
    try {
      final parcels = await neighbours.refresh(area);
      TileDownloadResult? result;
      if (tiles != null && !_cancel) {
        result = await tiles!.download(
          tilesCovering(area, minZoom, maxZoom),
          isCancelled: () => _cancel,
          onProgress: (done, total) {
            progress = (done: done, total: total);
            notifyListeners();
          },
        );
      }
      final complete = parcels != null && !_cancel && (result == null || result.failed == 0);
      await (db.update(db.offlineAreas)..where((a) => a.id.equals(id))).write(OfflineAreasCompanion(
        tileCount: Value(result?.stored ?? 0),
        bytes: Value(result?.bytes ?? 0),
        parcelCount: Value(parcels ?? 0),
        complete: Value(complete),
        updatedAt: Value(DateTime.now()),
      ));
      if (_cancel) return 'Download cancelled. What was saved is kept.';
      if (parcels == null) return 'Could not reach the registry; registered parcels were not saved. Try again online.';
      if (result != null && result.failed > 0) {
        return '${result.failed} map tiles could not be downloaded. Try again to fill the gaps.';
      }
      return 'Saved $name: $parcels registered parcels'
          '${result == null ? '' : ' and ${result.stored} map tiles'}.';
    } finally {
      progress = null;
      notifyListeners();
    }
  }

  /// Fetches the latest registered parcels for a saved area.
  Future<int?> refreshParcels(OfflineArea area) async {
    final n = await neighbours.refresh(area.bounds);
    if (n != null) {
      await (db.update(db.offlineAreas)..where((a) => a.id.equals(area.id)))
          .write(OfflineAreasCompanion(parcelCount: Value(n), updatedAt: Value(DateTime.now())));
    }
    return n;
  }

  /// Removes a saved area and the tiles no other saved area needs.
  Future<void> delete(OfflineArea area) async {
    if (tiles != null && area.tileSource == tiles!.urlTemplate) {
      final others = await (db.select(db.offlineAreas)
            ..where((a) => a.id.isNotValue(area.id) & a.tileSource.equals(area.tileSource!)))
          .get();
      final keep = {for (final o in others) ...tilesCovering(o.bounds, o.minZoom, o.maxZoom)};
      await tiles!.delete(tilesCovering(area.bounds, area.minZoom, area.maxZoom), keep: keep);
    }
    await (db.delete(db.offlineAreas)..where((a) => a.id.equals(area.id))).go();
  }
}
