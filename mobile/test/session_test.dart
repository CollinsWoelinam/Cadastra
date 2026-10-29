import 'dart:convert';

import 'package:cadastra_field/auth/session.dart';
import 'package:cadastra_field/services/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late FakeCore core;
  setUp(() => core = FakeCore());

  test('login stores the session and survives a restart', () async {
    final store = MemoryTokenStore();
    final session = AuthSession('http://core', store, core.client);
    expect(await session.login('kojo@test.gh', 'right-password'), isNull);
    expect(session.user!.fullName, 'Kojo');

    final restarted = AuthSession('http://core', store, core.client);
    await restarted.load();
    expect(restarted.signedIn, isTrue);
    expect(restarted.accessToken, 'access-1');
  });

  test('wrong password is reported and nothing is stored', () async {
    final store = MemoryTokenStore();
    final session = AuthSession('http://core', store, core.client);
    expect(await session.login('kojo@test.gh', 'nope'), 'Incorrect email or password.');
    expect(session.signedIn, isFalse);
    expect(store.value, isNull);
  });

  test('accounts that cannot submit are refused and their token revoked', () async {
    core.user = {'id': 'u-9', 'email': 'r@test.gh', 'full_name': 'Rev', 'role': 'REVIEWER'};
    final session = AuthSession('http://core', MemoryTokenStore(), core.client);
    expect(await session.login('r@test.gh', 'right-password'), contains('cannot submit'));
    expect(session.signedIn, isFalse);
    expect(core.requests.map((r) => r.url.path), contains('/auth/logout'));
  });

  test('concurrent 401s trigger a single refresh', () async {
    core.handler = (_) async => jsonResponse({'id': 'p', 'status': 'PENDING'});
    final session = await core.signedInSession();
    final api = ApiClient('http://core', session, core.client);
    core.expireAccess();
    await Future.wait([for (var i = 0; i < 5; i++) api.parcel('p')]);
    // A second refresh would replay the rotated token and end the session server-side.
    expect(core.refreshCalls, 1);
    expect(session.expired, isFalse);
  });

  test('a rejected refresh ends the session but keeps the identity', () async {
    final store = MemoryTokenStore();
    final session = AuthSession('http://core', store, core.client);
    await session.login('kojo@test.gh', 'right-password');
    core.refresh = 'revoked';
    expect(await session.refresh(), isFalse);
    expect(session.expired, isTrue);
    expect(session.accessToken, isNull);
    expect(session.user!.id, 'u-1');
    expect((jsonDecode(store.value!) as Map)['refresh_token'], isNull);
    await expectLater(ApiClient('http://core', session, core.client).parcel('p'), throwsA(isA<AuthRequiredException>()));
  });

  test('logout clears local tokens and revokes the refresh token', () async {
    final store = MemoryTokenStore();
    final session = AuthSession('http://core', store, core.client);
    await session.login('kojo@test.gh', 'right-password');
    await session.logout();
    expect(session.signedIn, isFalse);
    expect(store.value, isNull);
    final logout = core.requests.lastWhere((r) => r.url.path == '/auth/logout');
    expect(jsonDecode(logout.body)['refresh_token'], 'refresh-1');
  });
}
