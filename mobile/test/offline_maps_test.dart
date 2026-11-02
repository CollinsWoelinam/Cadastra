import 'dart:convert';
import 'dart:io';

import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/geo/tiles.dart';
import 'package:cadastra_field/map/offline_tile_provider.dart';
import 'package:cadastra_field/map/tile_store.dart';
import 'package:cadastra_field/services/api_client.dart';
import 'package:cadastra_field/services/neighbour_service.dart';
import 'package:cadastra_field/services/offline_maps.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

import 'encroachment_test.dart' show rect;
import 'helpers.dart';

const template = 'https://tiles.test/{z}/{x}/{y}.png';

Map<String, dynamic> feature(String id, List<LatLng> ring, String status) => {
      'type': 'Feature',
      'geometry': {'type': 'Polygon', 'coordinates': [[for (final p in [...ring, ring.first]) [p.longitude, p.latitude]]]},
      'properties': {'id': id, 'title_deed_no': 'GA/$id', 'owner_name': 'Owner', 'status': status},
    };

void main() {
  late Directory dir;
  late List<Uri> tileRequests;
  late Set<String> missing;
  late MockClient tileServer;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tiles');
    tileRequests = [];
    missing = {};
    tileServer = MockClient((req) async {
      tileRequests.add(req.url);
      expect(req.headers['User-Agent'], TileStore.userAgent);
      return missing.contains(req.url.path) ? http.Response('', 404) : http.Response.bytes([1, 2, 3, 4], 200);
    });
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('TileStore', () {
    test('downloads missing tiles once and serves them from disk', () async {
      final store = TileStore(dir, template, client: tileServer);
      final tiles = [(z: 18, x: 1, y: 2), (z: 18, x: 1, y: 3)];
      var progress = 0;
      final first = await store.download(tiles, onProgress: (done, _) => progress = done);
      expect(first, (stored: 2, failed: 0, bytes: 8, cancelled: false));
      expect(progress, 2);
      expect(store.stored(18, 1, 2)!.readAsBytesSync(), [1, 2, 3, 4]);
      expect(store.stored(18, 9, 9), isNull);

      await store.download(tiles);
      expect(tileRequests, hasLength(2), reason: 'stored tiles are not fetched again');
    });

    test('counts tiles the server refuses and does not store them', () async {
      missing.add('/18/1/3.png');
      final result = await TileStore(dir, template, client: tileServer).download([(z: 18, x: 1, y: 2), (z: 18, x: 1, y: 3)]);
      expect((result.stored, result.failed), (1, 1));
    });

    test('stops when cancelled', () async {
      var calls = 0;
      final result = await TileStore(dir, template, client: tileServer).download(
        [for (var x = 0; x < 50; x++) (z: 18, x: x, y: 0)],
        concurrency: 1,
        isCancelled: () => ++calls > 5,
      );
      expect(result.cancelled, isTrue);
      expect(result.stored, lessThan(50));
    });

    test('different basemap sources are kept apart', () async {
      await TileStore(dir, template, client: tileServer).download([(z: 18, x: 1, y: 2)]);
      expect(TileStore(dir, 'https://other.test/{z}/{x}/{y}.png').stored(18, 1, 2), isNull);
    });

    test('the map reads stored tiles from disk and others from the network', () async {
      final store = TileStore(dir, template, client: tileServer);
      await store.download([(z: 18, x: 1, y: 2)]);
      final provider = OfflineFirstTileProvider(store);
      final layer = TileLayer(urlTemplate: template);
      expect(provider.getImageWithCancelLoadingSupport(const TileCoordinates(1, 2, 18), layer, Future.value()),
          isA<FileImage>());
      expect(provider.getImageWithCancelLoadingSupport(const TileCoordinates(1, 3, 18), layer, Future.value()),
          isNot(isA<FileImage>()));
    });
  });

  group('OfflineMaps', () {
    late AppDatabase db;
    late FakeCore core;
    late List<Map<String, dynamic>> registry;

    setUp(() {
      db = memoryDb();
      registry = [
        feature('1', rect(0, 0, 30, 30), 'APPROVED'),
        feature('2', rect(40, 0, 30, 30), 'PENDING'),
        feature('3', rect(80, 0, 30, 30), 'REJECTED'),
      ];
      core = FakeCore()
        ..handler = (req) async =>
            http.Response(jsonEncode({'type': 'FeatureCollection', 'features': registry}), 200);
    });
    tearDown(() => db.close());

    Future<OfflineMaps> offline({TileStore? tiles}) async {
      final api = ApiClient('http://core', await core.signedInSession(), core.client);
      return OfflineMaps(db, NeighbourService(db, api), tiles);
    }

    test('saves registered parcels (not rejected ones) and the map tiles for an area', () async {
      final maps = await offline(tiles: TileStore(dir, template, client: tileServer));
      final area = GeoBounds.around(origin, 200);
      final message = await maps.download('Block C', area);
      expect(message, startsWith('Saved Block C: 2 registered parcels and '));

      final saved = (await db.select(db.offlineAreas).get()).single;
      expect((saved.complete, saved.parcelCount, saved.tileCount), (true, 2, countTiles(area, 13, 19)));
      expect([for (final p in await db.registeredParcelsIn(area)) p.status]..sort(), ['APPROVED', 'PENDING']);
      expect(core.requests.last.url.queryParameters['bbox'], '${area.west},${area.south},${area.east},${area.north}');
    });

    test('without tile permission only parcels are saved', () async {
      final maps = await offline();
      expect(maps.tileCount(GeoBounds.around(origin, 1000)), 0);
      expect(await maps.download('Parcels', GeoBounds.around(origin, 200)), 'Saved Parcels: 2 registered parcels.');
      expect(tileRequests, isEmpty);
    });

    test('an unreachable registry leaves the area incomplete', () async {
      core.handler = (_) async => http.Response('down', 503);
      final maps = await offline();
      expect(await maps.download('X', GeoBounds.around(origin, 200)), startsWith('Could not reach the registry'));
      expect((await db.select(db.offlineAreas).getSingle()).complete, isFalse);
    });

    test('refreshing drops parcels the registry no longer returns', () async {
      final maps = await offline();
      final area = GeoBounds.around(origin, 200);
      await maps.download('A', area);
      registry.removeAt(1); // the pending survey was rejected
      await maps.refreshParcels(await db.select(db.offlineAreas).getSingle());
      expect([for (final p in await db.registeredParcelsIn(area)) p.id], ['1']);
    });

    test('deleting an area keeps tiles another saved area still needs', () async {
      final store = TileStore(dir, template, client: tileServer);
      final maps = await offline(tiles: store);
      final a = GeoBounds.around(origin, 150), b = GeoBounds.around(offset(150, 0), 150);
      await maps.download('A', a);
      await maps.download('B', b);
      final shared = tilesCovering(a, 13, 19).toSet().intersection(tilesCovering(b, 13, 19).toSet());
      final onlyA = tilesCovering(a, 13, 19).toSet().difference(shared);
      expect(shared, isNotEmpty);
      expect(onlyA, isNotEmpty);

      await maps.delete((await db.select(db.offlineAreas).get()).firstWhere((x) => x.name == 'A'));
      expect(onlyA.every((t) => store.stored(t.z, t.x, t.y) == null), isTrue);
      expect(shared.every((t) => store.stored(t.z, t.x, t.y) != null), isTrue);
    });
  });
}
