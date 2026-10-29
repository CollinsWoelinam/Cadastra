import 'dart:async';
import 'dart:math' as math;

import 'package:cadastra_field/app.dart';
import 'package:cadastra_field/auth/session.dart';
import 'package:cadastra_field/config.dart';
import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/location/position_source.dart';
import 'package:cadastra_field/services/api_client.dart';
import 'package:cadastra_field/services/sync_service.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';

/// Runs against a live Core Engine seeded with `python -m scripts.seed` (which also
/// creates the dev surveyor account used here).
/// Walks a plot over the seeded approved parcels near GA/EL/2001 and checks that
/// the server's encroachment verdict reaches the app.
class PushedPositionSource implements PositionSource {
  final _controller = StreamController<Fix>.broadcast();

  @override
  Future<String?> prepare() async => null;

  @override
  Stream<Fix> get fixes => _controller.stream;

  void emit(LatLng p, double accuracy) => _controller.add(Fix(p, accuracy, DateTime.now()));
}

const _start = LatLng(5.6230, -0.1708);

LatLng _offset(double east, double north) => LatLng(
      _start.latitude + north / 110574.0,
      _start.longitude + east / (111320.0 * math.cos(_start.latitude * math.pi / 180)),
    );

Future<void> _checkpoint(WidgetTester tester, String name) async {
  // ignore: avoid_print
  print('CHECKPOINT $name');
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder, {int tries = 60}) async {
  for (var i = 0; i < tries && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('field survey against the live Core Engine', (tester) async {
    final runId = DateTime.now().millisecondsSinceEpoch;
    final db = AppDatabase(driftDatabase(name: 'it_$runId'));
    final gps = PushedPositionSource();
    final session = AuthSession(apiBaseUrl, MemoryTokenStore());
    final sync = SyncService(db, ApiClient(apiBaseUrl, session));
    await tester.pumpWidget(
        CadastraApp(services: AppServices(db: db, session: session, sync: sync, positionSource: () => gps)));
    await tester.pump();

    // Dev account created by scripts.seed.
    await tester.enterText(find.byKey(const Key('login-email')), 'surveyor@cadastra.local');
    await tester.enterText(find.byKey(const Key('login-password')), 'cadastra-dev-password');
    await tester.tap(find.byKey(const Key('login-submit')));
    await _pumpUntil(tester, find.text('New survey'));

    final deed = 'GA/IT/${runId % 100000}';
    await tester.tap(find.text('New survey'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('deed')), deed);
    await tester.enterText(find.byKey(const Key('owner')), 'Yaw Darko');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Stand at the start for a moment, then walk a 30 m × 36 m rectangle in 1 m steps.
    gps.emit(_offset(0, 0), 2.4);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Walk'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('walk')));
    await tester.pump();
    final corners = [(0.0, 0.0), (30.0, 0.0), (30.0, 36.0), (0.0, 36.0), (0.0, 0.0)];
    for (var c = 0; c < corners.length - 1; c++) {
      final (x0, y0) = corners[c];
      final (x1, y1) = corners[c + 1];
      final len = math.sqrt(math.pow(x1 - x0, 2) + math.pow(y1 - y0, 2));
      for (var d = 0.0; d <= len; d += 1) {
        gps.emit(_offset(x0 + (x1 - x0) * d / len, y0 + (y1 - y0) * d / len), 2.4);
        await tester.pump(const Duration(milliseconds: 40));
      }
      if (c == 1) await _checkpoint(tester, 'walking');
    }
    await _pumpUntil(tester, find.byKey(const Key('loop-closed')));
    await _checkpoint(tester, 'closed');

    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Finish')));
    await tester.pump(const Duration(seconds: 1));

    await _pumpUntil(tester, find.text('Pending review — encroaches on approved land'));
    await _checkpoint(tester, 'list');

    await tester.tap(find.text(deed));
    await _pumpUntil(tester, find.textContaining('Overlaps an approved parcel'));
    await _checkpoint(tester, 'detail');

    final survey = (await db.surveysIn(SyncState.synced, session.user!.id)).single;
    expect(survey.serverParcelId, isNotNull);
    expect(survey.titleDeedNo, deed);
  });
}
