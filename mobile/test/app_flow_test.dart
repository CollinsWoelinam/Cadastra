import 'dart:convert';

import 'package:cadastra_field/app.dart';
import 'package:cadastra_field/services/api_client.dart';
import 'package:cadastra_field/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

void main() {
  testWidgets('walk a boundary, finish, upload and see the review result', (tester) async {
    // Phone-shaped viewport so the detail screen's conflict list is on screen.
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final db = memoryDb();
    final gps = TestPositionSource();
    Map<String, dynamic>? uploaded;
    final conflicts = [
      {
        'parcel_id': 'x', 'title_deed_no': 'GA/EL/1005', 'owner_name': 'Efua Addo', 'status': 'APPROVED',
        'overlap_area_sqm': 127.79, 'blocking': true,
        'overlap_geometry': {'type': 'Polygon', 'coordinates': [[[-0.17, 5.624], [-0.1699, 5.624], [-0.1699, 5.6241], [-0.17, 5.624]]]},
      },
    ];
    final api = ApiClient('http://core', MockClient((req) async {
      if (req.method == 'POST') {
        uploaded = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'parcel': {'id': 'p-9', 'status': 'PENDING'}, 'conflicts': conflicts}), 201);
      }
      final body = req.url.path.endsWith('/conflicts') ? conflicts : {'id': 'p-9', 'status': 'PENDING'};
      return http.Response(jsonEncode(body), 200);
    }));
    final services = AppServices(db: db, sync: SyncService(db, api), positionSource: () => gps, showBasemap: false);

    await tester.pumpWidget(CadastraApp(services: services));
    await tester.pump();
    expect(find.textContaining('No surveys yet'), findsOneWidget);

    // New survey
    await tester.tap(find.text('New survey'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('deed')), 'GA/EL/3001');
    await tester.enterText(find.byKey(const Key('owner')), 'Kofi Boateng');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for GPS…'), findsOneWidget);

    // Walk the perimeter
    await tester.tap(find.text('Walk'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('walk')));
    await tester.pump();
    walkRectangle(30, 36).forEach(gps.emit);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('loop-closed')), findsOneWidget);
    final measures = tester.widget<Text>(find.byKey(const Key('measures'))).data!;
    expect(measures, matches(RegExp(r'^2\d corners · 10[67]\d\.\d m²')));
    expect(find.text('GPS ±3.0 m'), findsOneWidget);

    // Finish → list, uploaded
    await tester.tap(find.byKey(const Key('finish')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Finish')));
    await tester.pumpAndSettle();
    expect(find.text('GA/EL/3001'), findsOneWidget);
    expect(find.text('Pending review — encroaches on approved land'), findsOneWidget);
    expect(uploaded!['title_deed_no'], 'GA/EL/3001');
    expect((uploaded!['survey_points'] as List).length, greaterThan(20));

    // Detail
    await tester.tap(find.text('GA/EL/3001'));
    await tester.pumpAndSettle();
    expect(find.text('Pending review — encroaches on approved land'), findsOneWidget);
    expect(find.text('GA/EL/1005 · Efua Addo'), findsOneWidget);
    expect(find.text('127.79 m²'), findsOneWidget);

    // Drift's stream-query cleanup runs on timers in the test's fake-async zone,
    // so advance fake time while the database closes.
    await tester.pumpWidget(const SizedBox());
    final closed = db.close();
    await tester.pump(const Duration(seconds: 1));
    await closed;
  });
}
