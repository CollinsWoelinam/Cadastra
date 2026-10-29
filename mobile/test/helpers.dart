import 'dart:async';
import 'dart:math' as math;

import 'dart:convert';

import 'package:cadastra_field/auth/session.dart';
import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/location/position_source.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const origin = LatLng(5.6240, -0.1700); // Accra

/// Offset [origin] by metres east/north.
LatLng offset(double east, double north) => LatLng(
      origin.latitude + north / 110574.0,
      origin.longitude + east / (111320.0 * math.cos(origin.latitude * math.pi / 180)),
    );

/// Fixes every [step] metres around a w × h rectangle, ending back at the start.
List<Fix> walkRectangle(double w, double h, {double step = 1, double accuracy = 3}) {
  final corners = [(0.0, 0.0), (w, 0.0), (w, h), (0.0, h), (0.0, 0.0)];
  final fixes = <Fix>[];
  for (var i = 0; i < corners.length - 1; i++) {
    final (x0, y0) = corners[i];
    final (x1, y1) = corners[i + 1];
    final len = math.sqrt(math.pow(x1 - x0, 2) + math.pow(y1 - y0, 2));
    for (var d = 0.0; d < len; d += step) {
      fixes.add(Fix(offset(x0 + (x1 - x0) * d / len, y0 + (y1 - y0) * d / len), accuracy, DateTime.now()));
    }
  }
  fixes.add(Fix(offset(0, 0), accuracy, DateTime.now()));
  return fixes;
}

class TestPositionSource implements PositionSource {
  final controller = StreamController<Fix>.broadcast(sync: true);
  String? problem;

  @override
  Future<String?> prepare() async => problem;

  @override
  Stream<Fix> get fixes => controller.stream;

  void emit(Fix fix) => controller.add(fix);
}

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

const surveyor = {'id': 'u-1', 'email': 'kojo@test.gh', 'full_name': 'Kojo', 'role': 'SURVEYOR'};

Future<Survey> createSurvey(AppDatabase db,
    {String id = 'a1b2c3d4-0000-4000-8000-000000000001', String deed = 'GA/T/1', String owner = 'u-1'}) async {
  final now = DateTime.now();
  await db.into(db.surveys).insert(SurveysCompanion.insert(
        id: id,
        ownerUserId: Value(owner),
        titleDeedNo: deed,
        ownerName: 'Ama Mensah',
        syncState: SyncState.draft,
        createdAt: now,
        updatedAt: now,
      ));
  return db.survey(id);
}


http.Response jsonResponse(Object? body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

/// A stand-in Core Engine that enforces bearer tokens and rotates refresh tokens
/// like the real one, delegating everything else to [handler].
class FakeCore {
  String access = 'access-1';
  String refresh = 'refresh-1';
  int refreshCalls = 0;
  Map<String, dynamic> user = Map.of(surveyor);
  Future<http.Response> Function(http.Request req) handler = (_) async => jsonResponse({'detail': 'no route'}, 404);
  final requests = <http.Request>[];

  late final MockClient client = MockClient((req) async {
    requests.add(req);
    final body = req.body.isEmpty ? <String, dynamic>{} : jsonDecode(req.body) as Map<String, dynamic>;
    switch (req.url.path) {
      case '/auth/login':
        return body['password'] == 'right-password'
            ? jsonResponse(_pair())
            : jsonResponse({'detail': 'incorrect email or password'}, 401);
      case '/auth/refresh':
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        if (body['refresh_token'] != refresh) return jsonResponse({'detail': 'invalid'}, 401);
        access = 'access-${refreshCalls + 1}';
        refresh = 'refresh-${refreshCalls + 1}';
        return jsonResponse(_pair());
      case '/auth/logout':
        return http.Response('', 204);
    }
    if (req.headers['Authorization'] != 'Bearer $access') return jsonResponse({'detail': 'token expired'}, 401);
    return handler(req);
  });

  Map<String, dynamic> _pair() => {'access_token': access, 'refresh_token': refresh, 'user': user};

  /// Expires the current access token, as if 15 minutes had passed.
  void expireAccess() => access = 'access-rotated-${DateTime.now().microsecondsSinceEpoch}';

  /// A session that is already signed in with this server's current tokens.
  Future<AuthSession> signedInSession() async {
    final session = AuthSession('http://core', MemoryTokenStore(jsonEncode({
      'user': user, 'access_token': access, 'refresh_token': refresh,
    })), client);
    await session.load();
    return session;
  }
}
