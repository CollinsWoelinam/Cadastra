import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../data/db.dart';
import '../geo/polygon_math.dart';
import 'widgets.dart';

String formatArea(double sqm) =>
    '${sqm.toStringAsFixed(1)} m² · ${(sqm / sqmPerAcre).toStringAsFixed(3)} ac';

String formatLength(double m) => '${m.toStringAsFixed(1)} m';

/// "1,077.6 m²"
String formatSqm(double sqm) {
  final whole = sqm.truncate();
  return '${formatCount(whole)}.${((sqm - whole) * 10).round().clamp(0, 9)} m²';
}

/// "09:12", "Yesterday", "28 Oct".
String formatWhen(DateTime t, [DateTime? now]) {
  now ??= DateTime.now();
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  if (days == 0) return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  if (days == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${t.day} ${months[t.month - 1]}';
}

String formatDistance(double m) => m < 1000 ? '${m.round()} m' : '${(m / 1000).toStringAsFixed(m < 10000 ? 1 : 0)} km';

String formatBytes(int bytes) => bytes < 1024 * 1024
    ? '${(bytes / 1024).ceil()} KB'
    : '${(bytes / (1024 * 1024)).toStringAsFixed(bytes < 100 * 1024 * 1024 ? 1 : 0)} MB';

String formatCount(int n) => n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

String formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

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

typedef SurveyStatus = ({String label, String short, Tone tone, IconData icon});

/// How a survey is described in lists and headers: a line, a pill label, a colour and an icon.
SurveyStatus surveyStatus(Survey s, List<Conflict> conflicts) => switch (s.syncState) {
      SyncState.draft => (label: 'Capturing · tap to continue', short: 'Draft', tone: Tone.blue, icon: Icons.polyline_outlined),
      SyncState.queued =>
        (label: 'Finished · waiting to upload', short: 'Waiting to upload', tone: Tone.neutral, icon: Icons.cloud_upload_outlined),
      SyncState.failed =>
        (label: 'Refused: ${s.lastError ?? 'unknown error'}', short: 'Refused', tone: Tone.red, icon: Icons.error_outline),
      SyncState.synced => switch (s.serverStatus) {
          'APPROVED' =>
            (label: 'Approved by the registry', short: 'Approved', tone: Tone.green, icon: Icons.check_circle_outline),
          'REJECTED' => (label: 'Rejected by the registry', short: 'Rejected', tone: Tone.neutral, icon: Icons.block),
          _ when conflicts.any((c) => c.blocking) => (
              label: 'Pending review · encroaches on approved land',
              short: 'Pending review',
              tone: Tone.red,
              icon: Icons.warning_amber_rounded
            ),
          _ when conflicts.isNotEmpty => (
              label: 'Pending review · overlaps another claim',
              short: 'Pending review',
              tone: Tone.amber,
              icon: Icons.warning_amber_rounded
            ),
          _ => (label: 'Pending review', short: 'Pending review', tone: Tone.amber, icon: Icons.hourglass_top),
        },
    };
