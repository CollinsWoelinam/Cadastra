import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/db.dart';
import '../geo/polygon_math.dart';

String formatArea(double sqm) =>
    '${sqm.toStringAsFixed(1)} m² · ${(sqm / sqmPerAcre).toStringAsFixed(3)} ac';

String formatLength(double m) => '${m.toStringAsFixed(1)} m';

class Conflict {
  final String titleDeedNo;
  final String ownerName;
  final double overlapSqm;
  final bool blocking;
  final List<List<LatLng>> rings;

  Conflict.fromJson(Map<String, dynamic> json)
      : titleDeedNo = json['title_deed_no'] as String? ?? '?',
        ownerName = json['owner_name'] as String? ?? '',
        overlapSqm = (json['overlap_area_sqm'] as num?)?.toDouble() ?? 0,
        blocking = json['blocking'] as bool? ?? false,
        rings = _outerRings(json['overlap_geometry']);

  static List<List<LatLng>> _outerRings(dynamic geometry) {
    if (geometry is! Map) return [];
    final coords = geometry['coordinates'] as List? ?? [];
    final polygons = geometry['type'] == 'MultiPolygon' ? coords : [coords];
    return [
      for (final polygon in polygons)
        if ((polygon as List).isNotEmpty)
          [for (final p in polygon.first as List) LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble())],
    ];
  }

  static List<Conflict> listFrom(Survey s) => s.conflictsJson == null
      ? []
      : [for (final c in jsonDecode(s.conflictsJson!) as List) Conflict.fromJson(c as Map<String, dynamic>)];
}

/// One-line status and colour for a survey, as shown in lists and headers.
(String, Color) surveyStatus(Survey s, List<Conflict> conflicts) => switch (s.syncState) {
      SyncState.draft => ('Draft — capture in progress', Colors.blueGrey),
      SyncState.queued => ('Waiting to upload', Colors.orange),
      SyncState.failed => ('Refused: ${s.lastError ?? 'unknown error'}', Colors.red),
      SyncState.synced => switch (s.serverStatus) {
          'APPROVED' => ('Approved', Colors.green),
          'REJECTED' => ('Rejected by registry', Colors.grey),
          _ when conflicts.any((c) => c.blocking) => ('Pending review — encroaches on approved land', Colors.red),
          _ when conflicts.isNotEmpty => ('Pending review — overlaps another claim', Colors.orange),
          _ => ('Pending review', Colors.amber.shade800),
        },
    };
