import 'dart:async';
import 'dart:io';

import 'package:cadastra_field/app.dart';
import 'package:cadastra_field/auth/session.dart';
import 'package:cadastra_field/config.dart';
import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/geo/tiles.dart';
import 'package:cadastra_field/location/position_source.dart';
import 'package:cadastra_field/map/tile_store.dart';
import 'package:cadastra_field/services/api_client.dart';
import 'package:cadastra_field/services/offline_maps.dart';
import 'package:cadastra_field/services/sync_service.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';

/// Saves an area for offline use against the live Core Engine (seeded) and a tile
/// server that permits bulk download. Run with:
///   --dart-define=BASEMAP_URL=http://localhost:8091/{z}/{x}/{y}.png --dart-define=BASEMAP_OFFLINE=true
class PushedPositionSource implements PositionSource {
  final _controller = StreamController<Fix>.broadcast();

  @override
  Future<String?> prepare() async => null;

  @override
  Stream<Fix> get fixes => _controller.stream;

  void emit(LatLng p) => _controller.add(Fix(p, 2, DateTime.now()));
}

// Among the seeded East Legon parcels.
const _site = LatLng(5.6230, -0.1708);

// The test binding draws frames only when pumped. Pump at display rate so the map
// behaves as in the running app (flutter_map prunes tiles on timers against the
// last drawn camera).
Future<void> _frames(WidgetTester tester, Duration duration) async {
  for (var t = Duration.zero; t < duration; t += const Duration(milliseconds: 16)) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> _checkpoint(WidgetTester tester, String name) async {
  // ignore: avoid_print
  print('CHECKPOINT $name');
  await _frames(tester, const Duration(seconds: 4));
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder, {int tries = 240}) async {
  for (var i = 0; i < tries && finder.evaluate().isEmpty; i++) {
    await _frames(tester, const Duration(milliseconds: 500));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('save an area for offline fieldwork', (tester) async {
    expect(basemapAllowsOfflineDownload, isTrue, reason: 'run with BASEMAP_URL and BASEMAP_OFFLINE');
    final runId = DateTime.now().millisecondsSinceEpoch;
    final tileDir = Directory.systemTemp.createTempSync('it_tiles_');
    final db = AppDatabase(driftDatabase(name: 'it_offline_$runId'));
    final gps = PushedPositionSource();
    final session = AuthSession(apiBaseUrl, MemoryTokenStore());
    final services = AppServices(
      db: db,
      session: session,
      sync: SyncService(db, ApiClient(apiBaseUrl, session)),
      positionSource: () => gps,
      tileStore: TileStore(tileDir, basemapUrl),
    );
    await tester.pumpWidget(CadastraApp(services: services));
    await tester.pump();

    await tester.enterText(find.byKey(const Key('login-email')), 'surveyor@cadastra.local');
    await tester.enterText(find.byKey(const Key('login-password')), 'cadastra-dev-password');
    await tester.tap(find.byKey(const Key('login-submit')));
    await _pumpUntil(tester, find.text('New survey'));

    // Offline maps tab → Save an area.
    await _checkpoint(tester, 'surveys');
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Offline maps')));
    await tester.pumpAndSettle();
    expect(find.text('No saved areas yet.'), findsOneWidget);
    await tester.tap(find.text('Save an area'));
    await tester.pumpAndSettle();
    gps.emit(_site); // the screen centres on the surveyor
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextField), 'East Legon test block');
    await tester.tap(find.text('1 km'));
    await tester.pump(const Duration(seconds: 1));
    final area = GeoBounds.around(_site, 500);
    final expected = countTiles(area, OfflineMaps.minZoom, OfflineMaps.maxZoom);
    expect(tester.widget<Text>(find.byKey(const Key('estimate'))).data, startsWith('About ${_fmt(expected)} map tiles'));
    await _checkpoint(tester, 'save-area');

    await tester.tap(find.byKey(const Key('save-area')));
    await tester.pump(const Duration(milliseconds: 600));
    await _checkpoint(tester, 'saving');
    await _pumpUntil(tester, find.textContaining('Saved East Legon test block'));
    await _checkpoint(tester, 'saved');

    final saved = (await db.select(db.offlineAreas).get()).single;
    expect(saved.complete, isTrue);
    expect(saved.tileCount, expected);
    expect(saved.parcelCount, greaterThan(5));
    final missing = tilesCovering(area, 13, 19).where((t) => services.tileStore!.stored(t.z, t.x, t.y) == null);
    expect(missing, isEmpty);
    // ignore: avoid_print
    print('SAVED tiles=${saved.tileCount} bytes=${saved.bytes} parcels=${saved.parcelCount}');

    // Survey inside the saved area: the map comes from disk and the parcels from the cache.
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Surveys')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New survey'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('deed')), 'GA/IT/OFF${runId % 1000}');
    await tester.enterText(find.byKey(const Key('owner')), 'Akosua Mensah');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    gps.emit(_site);
    await _pumpUntil(tester, find.byKey(const Key('neighbours')));
    await _checkpoint(tester, 'capture-in-saved-area');
    // Leave the draft; it stays on the device of this test-only database.
    await tester.tap(find.byTooltip('Back to surveys'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Account')));
    await _checkpoint(tester, 'account');
    await tester.pumpWidget(const SizedBox());
    await db.close();
    tileDir.deleteSync(recursive: true);
  });
}

String _fmt(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
