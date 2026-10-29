import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/session.dart';
import '../data/db.dart';

/// The Core Engine refused the request; retrying unchanged will not help.
class RejectedException implements Exception {
  final int statusCode;
  final String message;

  RejectedException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class SubmissionResult {
  final String parcelId;
  final String status;
  final List<dynamic> conflicts;

  SubmissionResult(this.parcelId, this.status, this.conflicts);
}

class ApiClient {
  final String baseUrl;
  final AuthSession session;
  final http.Client _http;
  static const _timeout = Duration(seconds: 20);

  ApiClient(this.baseUrl, this.session, [http.Client? client]) : _http = client ?? http.Client();

  Future<SubmissionResult> submit(Survey survey, List<Node> nodes) async {
    final ring = [for (final n in nodes) [n.lon, n.lat]];
    final body = await _send('POST', '/parcels', {
      'client_ref': survey.id,
      'title_deed_no': survey.titleDeedNo,
      'owner_name': survey.ownerName,
      'boundary': {'type': 'Polygon', 'coordinates': [[...ring, ring.first]]},
      'survey_points': [
        for (final n in nodes)
          {'lon': n.lon, 'lat': n.lat, 'accuracy_m': n.accuracyM, 'captured_at': n.capturedAt.toUtc().toIso8601String()},
      ],
    }) as Map<String, dynamic>;
    final parcel = body['parcel'] as Map<String, dynamic>;
    return SubmissionResult(parcel['id'] as String, parcel['status'] as String, body['conflicts'] as List<dynamic>);
  }

  Future<Map<String, dynamic>> parcel(String id) async =>
      await _send('GET', '/parcels/$id') as Map<String, dynamic>;

  Future<List<dynamic>> conflicts(String id) async => await _send('GET', '/parcels/$id/conflicts') as List<dynamic>;

  Future<dynamic> _send(String method, String path, [Object? json]) async {
    Future<http.Response> attempt(String token) async {
      final request = http.Request(method, Uri.parse('$baseUrl$path'))
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] = 'Bearer $token';
      if (json != null) request.body = jsonEncode(json);
      return http.Response.fromStream(await _http.send(request).timeout(_timeout));
    }

    var token = session.accessToken;
    var response = token == null ? null : await attempt(token);
    if (response == null || response.statusCode == 401) {
      // One refresh and one retry. If the session is gone, the surveyor must sign in;
      // if the refresh merely couldn't connect, treat it like any network failure.
      if (!await session.refresh()) {
        if (session.expired || !session.signedIn) throw AuthRequiredException();
        throw http.ClientException('Could not refresh session', Uri.parse(baseUrl));
      }
      response = await attempt(session.accessToken!);
      if (response.statusCode == 401) throw AuthRequiredException();
    }
    final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    if (response.statusCode >= 400 && response.statusCode < 500) {
      throw RejectedException(response.statusCode, _detail(decoded) ?? 'HTTP ${response.statusCode}');
    }
    if (response.statusCode >= 500) {
      throw http.ClientException('Server error ${response.statusCode}', Uri.parse('$baseUrl$path'));
    }
    return decoded;
  }

  static String? _detail(dynamic body) {
    final detail = body is Map ? body['detail'] : null;
    if (detail is String) return detail;
    if (detail is Map && detail['message'] is String) return detail['message'] as String;
    if (detail is List && detail.isNotEmpty && detail.first is Map) return '${detail.first['msg']}';
    return null;
  }
}
