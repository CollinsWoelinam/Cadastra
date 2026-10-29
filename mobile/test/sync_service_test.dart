import 'dart:convert';
import 'dart:io';

import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/services/api_client.dart';
import 'package:cadastra_field/services/sync_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

Future<Survey> queuedSurvey(AppDatabase db, {String deed = 'GA/T/1'}) async {
  final s = await createSurvey(db, deed: deed);
  for (final (i, (x, y)) in [(0.0, 0.0), (30.0, 0.0), (30.0, 36.0), (0.0, 36.0)].indexed) {
    final p = offset(x, y);
    await db.into(db.nodes).insert(NodesCompanion.insert(
        surveyId: s.id, seq: i + 1, lat: p.latitude, lon: p.longitude, accuracyM: 0.5, capturedAt: DateTime.now()));
  }
  await db.updateSurvey(s.id, const SurveysCompanion(syncState: Value(SyncState.queued)));
  return db.survey(s.id);
}

http.Response json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> parcel(String status) => {'id': 'p-1', 'status': status, 'review_note': null};

void main() {
  late AppDatabase db;
  setUp(() => db = memoryDb());
  tearDown(() => db.close());

  test('uploads queued surveys with client_ref and a closed ring', () async {
    final survey = await queuedSurvey(db);
    late Map<String, dynamic> sent;
    final api = ApiClient('http://core', MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      return json({'parcel': parcel('PENDING'), 'conflicts': []}, 201);
    }));
    await SyncService(db, api).sync();

    expect(sent['client_ref'], survey.id);
    final ring = (sent['boundary']['coordinates'] as List).first as List;
    expect(ring.length, 5);
    expect(ring.first, ring.last);
    expect((sent['survey_points'] as List).first['accuracy_m'], 0.5);

    final after = await db.survey(survey.id);
    expect(after.syncState, SyncState.synced);
    expect(after.serverParcelId, 'p-1');
    expect(after.serverStatus, 'PENDING');
  });

  test('network failure keeps the survey queued', () async {
    final survey = await queuedSurvey(db);
    final sync = SyncService(db, ApiClient('http://core', MockClient((_) => throw const SocketException('down'))));
    await sync.sync();
    expect((await db.survey(survey.id)).syncState, SyncState.queued);
    expect(sync.offlineReason, contains('Offline'));
  });

  test('server errors are retried, not treated as refusals', () async {
    final survey = await queuedSurvey(db);
    await SyncService(db, ApiClient('http://core', MockClient((_) async => http.Response('boom', 503)))).sync();
    expect((await db.survey(survey.id)).syncState, SyncState.queued);
  });

  test('a refusal marks the survey failed; retry with a corrected deed succeeds', () async {
    final survey = await queuedSurvey(db);
    var posts = 0;
    final api = ApiClient('http://core', MockClient((req) async {
      if (req.method == 'GET') return json(req.url.path.endsWith('/conflicts') ? [] : parcel('PENDING'));
      posts++;
      final deed = (jsonDecode(req.body) as Map)['title_deed_no'];
      return deed == 'GA/T/1'
          ? json({'detail': 'duplicate: parcels_title_deed_no_key'}, 409)
          : json({'parcel': parcel('PENDING'), 'conflicts': []}, 201);
    }));
    final sync = SyncService(db, api);
    await sync.sync();
    var after = await db.survey(survey.id);
    expect(after.syncState, SyncState.failed);
    expect(after.lastError, contains('duplicate'));

    await sync.retry(survey.id, titleDeedNo: 'GA/T/2');
    after = await db.survey(survey.id);
    expect(after.syncState, SyncState.synced);
    expect(after.titleDeedNo, 'GA/T/2');
    expect(after.lastError, isNull);
    expect(posts, 2);
  });

  test('refreshes review status and conflicts of pending parcels', () async {
    final survey = await queuedSurvey(db);
    var status = 'PENDING';
    final api = ApiClient('http://core', MockClient((req) async {
      if (req.method == 'POST') return json({'parcel': parcel('PENDING'), 'conflicts': []}, 201);
      if (req.url.path.endsWith('/conflicts')) return json([{'parcel_id': 'x', 'overlap_area_sqm': 1.5}]);
      return json(parcel(status));
    }));
    final sync = SyncService(db, api);
    await sync.sync();
    status = 'APPROVED';
    await sync.sync();
    final after = await db.survey(survey.id);
    expect(after.serverStatus, 'APPROVED');
    expect(jsonDecode(after.conflictsJson!), hasLength(1));
  });

  test('concurrent sync calls share one pass', () async {
    await queuedSurvey(db);
    var posts = 0;
    final api = ApiClient('http://core', MockClient((req) async {
      if (req.method == 'POST') posts++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return json({'parcel': parcel('APPROVED'), 'conflicts': []}, 201);
    }));
    final sync = SyncService(db, api);
    await Future.wait([sync.sync(), sync.sync(), sync.sync()]);
    expect(posts, 1);
  });
}
