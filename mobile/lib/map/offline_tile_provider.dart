import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

import 'tile_store.dart';

/// Serves tiles saved for offline use from disk, and everything else from the network
/// (with flutter_map's ordinary HTTP caching).
class OfflineFirstTileProvider extends NetworkTileProvider {
  final TileStore store;

  OfflineFirstTileProvider(this.store) : super(silenceExceptions: true);

  @override
  ImageProvider getImageWithCancelLoadingSupport(
      TileCoordinates coordinates, TileLayer options, Future<void> cancelLoading) {
    final file = store.stored(coordinates.z, coordinates.x, coordinates.y);
    return file != null ? FileImage(file) : super.getImageWithCancelLoadingSupport(coordinates, options, cancelLoading);
  }
}
