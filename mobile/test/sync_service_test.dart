import 'dart:convert';
import 'dart:io';

import 'package:cadastra_field/auth/session.dart';
import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/services/api_client.dart';
import 'package:cadastra_field/services/sync_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'helpers.dart';

Future<Survey> queuedSurvey(AppDatabase db, {String deed = 'GA/T/1', String owner = 'u-1', String? id}) async {
  final s = await createSurvey(db, deed: deed, owner: owner, id: id ?? 'a1b2c3d4-0000-4000-8000-000000000001');
  for (final (i, (x, y)) in [(0.0, 0.0), (30.0, 0.0), (30.0, 36.0), (0.0, 36.0)].indexed) {
    final p = offset(x, y);
    await db.into(db.nodes).insert(NodesCompanion.insert(
        surveyId: s.id, seq: i + 1, lat: p.latitude, lon: p.longitude, accuracyM: 0.5, capturedAt: DateTime.now()));
  }
  await db.updateSurvey(s.id, const SurveysCompanion(syncState: Value(SyncState.queued)));
  return db.survey(s.id);
}

Map<String, dynamic> parcel(String status) => {'id': 'p-1', 'status': status, 'review_note': null};

void main() {
  late AppDatabase db;
  late FakeCore core;
  late SyncService sync;

  setUp(() async {
    db = memoryDb();
    core = FakeCore();
    sync = SyncService(db, ApiClient('http://core', await core.signedInSession(), core.client));
  });
  tearDown(() => db.close());

  test('uploads queued surveys with client_ref, a closed ring and the bearer token', () async {
    final survey = await queuedSurvey(db);
    late Map<String, dynamic> sent;
    late String? auth;
    core.handler = (req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      auth = req.headers['Authorization'];
      return jsonResponse({'parcel': parcel('PENDING'), 'conflicts': []}, 201);
    };
    await sync.sync();

    expect(auth, 'Bearer access-1');
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
    final offline = SyncService(db, ApiClient('http://core', await core.signedInSession(),
        MockClient((_) => throw const SocketException('down'))));
    await offline.sync();
    expect((await db.survey(survey.id)).syncState, SyncState.queued);
    expect(offline.offlineReason, contains('Offline'));
    expect(offline.needsSignIn, isFalse);
  });

  test('server errors are retried, not treated as refusals', () async {
    final survey = await queuedSurvey(db);
    core.handler = (_) async => http.Response('boom', 503);
    await sync.sync();
    expect((await db.survey(survey.id)).syncState, SyncState.queued);
  });

  test('a refusal marks the survey failed; retry with a corrected deed succeeds', () async {
    final survey = await queuedSurvey(db);
    var posts = 0;
    core.handler = (req) async {
      if (req.method == 'GET') return jsonResponse(req.url.path.endsWith('/conflicts') ? [] : parcel('PENDING'));
      posts++;
      final deed = (jsonDecode(req.body) as Map)['title_deed_no'];
      return deed == 'GA/T/1'
          ? jsonResponse({'detail': 'duplicate: parcels_title_deed_no_key'}, 409)
          : jsonResponse({'parcel': parcel('PENDING'), 'conflicts': []}, 201);
    };
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
    core.handler = (req) async {
      if (req.method == 'POST') return jsonResponse({'parcel': parcel('PENDING'), 'conflicts': []}, 201);
      if (req.url.path.endsWith('/conflicts')) return jsonResponse([{'parcel_id': 'x', 'overlap_area_sqm': 1.5}]);
      return jsonResponse(parcel(status));
    };
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
    core.handler = (req) async {
      if (req.method == 'POST') posts++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return jsonResponse({'parcel': parcel('APPROVED'), 'conflicts': []}, 201);
    };
    await Future.wait([sync.sync(), sync.sync(), sync.sync()]);
    expect(posts, 1);
  });

  test('an expired access token is refreshed once and the upload retried', () async {
    final survey = await queuedSurvey(db);
    core.handler = (_) async => jsonResponse({'parcel': parcel('APPROVED'), 'conflicts': []}, 201);
    core.expireAccess();
    await sync.sync();
    expect(core.refreshCalls, 1);
    expect((await db.survey(survey.id)).syncState, SyncState.synced);
  });

  test('an ended session keeps surveys queued and asks for sign-in', () async {
    final survey = await queuedSurvey(db);
    core
      ..expireAccess()
      ..refresh = 'revoked-elsewhere';
    await sync.sync();
    expect((await db.survey(survey.id)).syncState, SyncState.queued);
    expect(sync.needsSignIn, isTrue);
    expect(sync.api.session.expired, isTrue);
    expect(sync.api.session.signedIn, isTrue, reason: 'identity kept so local surveys stay visible');

    // Signing in again resumes the upload.
    core.handler = (_) async => jsonResponse({'parcel': parcel('APPROVED'), 'conflicts': []}, 201);
    expect(await sync.api.session.login('kojo@test.gh', 'right-password'), isNull);
    await sync.sync();
    expect((await db.survey(survey.id)).syncState, SyncState.synced);
    expect(sync.needsSignIn, isFalse);
  });

  test("uploads only the signed-in surveyor's own surveys", () async {
    await queuedSurvey(db, owner: 'u-1', id: 'a1b2c3d4-0000-4000-8000-000000000001', deed: 'MINE');
    final theirs = await queuedSurvey(db, owner: 'u-2', id: 'a1b2c3d4-0000-4000-8000-000000000002', deed: 'THEIRS');
    final deeds = <String>[];
    core.handler = (req) async {
      deeds.add((jsonDecode(req.body) as Map)['title_deed_no'] as String);
      return jsonResponse({'parcel': parcel('APPROVED'), 'conflicts': []}, 201);
    };
    await sync.sync();
    expect(deeds, ['MINE']);
    expect((await db.survey(theirs.id)).syncState, SyncState.queued);
  });

  test('signed-out sync does nothing', () async {
    await queuedSurvey(db);
    final signedOut = SyncService(db, ApiClient('http://core', AuthSession('http://core', MemoryTokenStore(), core.client), core.client));
    await signedOut.sync();
    expect(core.requests, isEmpty);
  });
}
