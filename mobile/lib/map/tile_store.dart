import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../geo/tiles.dart';

typedef TileDownloadResult = ({int stored, int failed, int bytes, bool cancelled});

/// Basemap tiles saved on the device for offline use, one file per tile.
///
/// Lives in application support storage, which the OS does not purge the way it
/// purges caches. Tiles from different basemap sources are kept apart.
class TileStore {
  final String urlTemplate;
  final Directory root;
  final http.Client _http;

  static const userAgent = 'cadastra_field/0.1 (com.cadastra.cadastra_field)';

  TileStore(Directory base, this.urlTemplate, {http.Client? client})
      : root = Directory('${base.path}/${_fnv1a(urlTemplate)}'),
        _http = client ?? http.Client();

  File _file(int z, int x, int y) => File('${root.path}/$z/$x/$y.tile');

  /// The stored tile, if any. Synchronous so the map can choose a source per tile.
  File? stored(int z, int x, int y) {
    final f = _file(z, x, y);
    return f.existsSync() ? f : null;
  }

  String url(int z, int x, int y) => urlTemplate
      .replaceAll('{z}', '$z')
      .replaceAll('{x}', '$x')
      .replaceAll('{y}', '$y')
      .replaceAll('{s}', 'a')
      .replaceAll('{r}', '');

  /// Fetches [tiles] that are not stored yet. Already-stored tiles count as done
  /// (and towards [TileDownloadResult.bytes]). Stops early once [isCancelled] is true.
  Future<TileDownloadResult> download(
    Iterable<TileKey> tiles, {
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
    int concurrency = 4,
  }) async {
    final queue = tiles.toList();
    var next = 0, done = 0, stored = 0, failed = 0, bytes = 0;
    bool cancelled() => isCancelled?.call() ?? false;

    Future<void> worker() async {
      while (next < queue.length && !cancelled()) {
        final t = queue[next++];
        final file = _file(t.z, t.x, t.y);
        if (file.existsSync()) {
          bytes += file.lengthSync();
          stored++;
        } else {
          final body = await _fetch(t);
          if (body == null) {
            failed++;
          } else {
            await file.parent.create(recursive: true);
            // Write then rename, so an interrupted write never leaves a broken tile.
            final tmp = File('${file.path}.part');
            await tmp.writeAsBytes(body, flush: true);
            await tmp.rename(file.path);
            bytes += body.length;
            stored++;
          }
        }
        onProgress?.call(++done, queue.length);
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
    return (stored: stored, failed: failed, bytes: bytes, cancelled: cancelled() && done < queue.length);
  }

  Future<List<int>?> _fetch(TileKey t) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _http
            .get(Uri.parse(url(t.z, t.x, t.y)), headers: {'User-Agent': userAgent})
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) return res.bodyBytes;
        if (res.statusCode >= 400 && res.statusCode < 500) return null; // won't improve on retry
      } on Exception {
        // Retry once, then count it as failed.
      }
    }
    return null;
  }

  /// Deletes stored [tiles], except those in [keep] (still needed by other areas).
  Future<void> delete(Iterable<TileKey> tiles, {Set<TileKey> keep = const {}}) async {
    for (final t in tiles) {
      if (keep.contains(t)) continue;
      final f = _file(t.z, t.x, t.y);
      if (f.existsSync()) await f.delete();
    }
  }
}

/// Stable short hash for directory names (String.hashCode is not stable across runs).
String _fnv1a(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16).padLeft(8, '0');
}
