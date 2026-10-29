import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../data/db.dart';
import 'format.dart';
import 'survey_map.dart';
import 'surveys_screen.dart';

class SurveyDetailScreen extends StatefulWidget {
  final String surveyId;

  const SurveyDetailScreen({super.key, required this.surveyId});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  late final Future<List<Node>> _nodes = Services.read(context).db.nodesOf(widget.surveyId);

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    return StreamBuilder<Survey>(
      stream: services.db.watchSurvey(widget.surveyId),
      builder: (context, snapshot) {
        final survey = snapshot.data;
        if (survey == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final conflicts = Conflict.listFrom(survey);
        final (label, color) = surveyStatus(survey, conflicts);
        return Scaffold(
          appBar: AppBar(
            title: Text(survey.titleDeedNo),
            actions: [
              if (survey.syncState != SyncState.synced)
                IconButton(tooltip: 'Delete survey', icon: const Icon(Icons.delete_outline), onPressed: () => _delete(survey)),
            ],
          ),
          body: FutureBuilder<List<Node>>(
            future: _nodes,
            builder: (context, nodes) {
              final ring = [for (final n in nodes.data ?? <Node>[]) LatLng(n.lat, n.lon)];
              final worstAccuracy = (nodes.data ?? []).fold<double>(0, (m, n) => n.accuracyM > m ? n.accuracyM : m);
              return RefreshIndicator(
                onRefresh: services.sync.sync,
                child: ListView(children: [
                  SizedBox(
                    height: 300,
                    child: nodes.hasData
                        ? SurveyMap(boundary: ring, conflicts: [for (final c in conflicts) ...c.rings])
                        : const Center(child: CircularProgressIndicator()),
                  ),
                  Container(
                    width: double.infinity,
                    color: color.withValues(alpha: 0.12),
                    padding: const EdgeInsets.all(16),
                    child: Text(label, key: const Key('status'), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                  ),
                  ListTile(title: const Text('Owner'), trailing: Text(survey.ownerName)),
                  ListTile(title: const Text('Area'), trailing: Text(formatArea(survey.areaSqm))),
                  ListTile(title: const Text('Perimeter'), trailing: Text(formatLength(survey.perimeterM))),
                  ListTile(
                    title: const Text('Corners'),
                    trailing: Text('${ring.length} · worst ±${worstAccuracy.toStringAsFixed(2)} m'),
                  ),
                  if (survey.reviewNote != null)
                    ListTile(title: const Text('Registry note'), subtitle: Text(survey.reviewNote!)),
                  if (survey.syncState == SyncState.failed)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: () => _editAndRetry(survey),
                        icon: const Icon(Icons.edit),
                        label: const Text('Correct details and resubmit'),
                      ),
                    ),
                  if (conflicts.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text('Boundary conflicts', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    for (final c in conflicts)
                      ListTile(
                        leading: Icon(Icons.warning_amber, color: c.blocking ? Colors.red : Colors.orange),
                        title: Text('${c.titleDeedNo} · ${c.ownerName}'),
                        subtitle: Text(c.blocking ? 'Overlaps an approved parcel' : 'Overlaps another pending claim'),
                        trailing: Text('${c.overlapSqm.toStringAsFixed(2)} m²'),
                      ),
                  ],
                  const SizedBox(height: 24),
                ]),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editAndRetry(Survey survey) async {
    final details = await showDialog<(String, String)>(
      context: context,
      builder: (_) => SurveyDetailsDialog(
        title: 'Correct and resubmit',
        titleDeedNo: survey.titleDeedNo,
        ownerName: survey.ownerName,
      ),
    );
    if (details == null || !mounted) return;
    await Services.read(context).sync.retry(survey.id, titleDeedNo: details.$1, ownerName: details.$2);
  }

  Future<void> _delete(Survey survey) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete survey?'),
        content: Text('${survey.titleDeedNo} and its captured corners will be removed from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final db = Services.read(context).db;
    Navigator.of(context).pop();
    await (db.delete(db.surveys)..where((s) => s.id.equals(survey.id))).go();
  }
}
