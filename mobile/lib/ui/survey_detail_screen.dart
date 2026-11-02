import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../app.dart';
import '../data/db.dart';
import '../geo/tiles.dart';
import 'format.dart';
import 'survey_map.dart';
import 'surveys_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class SurveyDetailScreen extends StatefulWidget {
  final String surveyId;

  const SurveyDetailScreen({super.key, required this.surveyId});

  @override
  State<SurveyDetailScreen> createState() => _SurveyDetailScreenState();
}

class _SurveyDetailScreenState extends State<SurveyDetailScreen> {
  late final Future<List<Node>> _nodes = Services.read(context).db.nodesOf(widget.surveyId);
  Stream<List<RegisteredParcel>>? _neighbours;

  @override
  void initState() {
    super.initState();
    _nodes.then((nodes) {
      if (nodes.isEmpty || !mounted) return;
      final services = Services.read(context);
      final b = GeoBounds.of([for (final n in nodes) LatLng(n.lat, n.lon)]);
      final area = GeoBounds.around(b.centre, 300).expand(b);
      setState(() => _neighbours = services.db.watchRegisteredParcelsIn(area));
      services.neighbours.refresh(area);
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    return StreamBuilder<Survey>(
      stream: services.db.watchSurvey(widget.surveyId),
      builder: (context, snapshot) {
        final survey = snapshot.data;
        if (survey == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final conflicts = Conflict.listFrom(survey);
        final status = surveyStatus(survey, conflicts);
        return Scaffold(
          body: FutureBuilder<List<Node>>(
            future: _nodes,
            builder: (context, nodes) {
              final ring = [for (final n in nodes.data ?? <Node>[]) LatLng(n.lat, n.lon)];
              final worst = (nodes.data ?? []).fold<double>(0, (m, n) => n.accuracyM > m ? n.accuracyM : m);
              return RefreshIndicator(
                onRefresh: services.sync.sync,
                child: ListView(padding: EdgeInsets.zero, children: [
                  SizedBox(
                    height: 290,
                    child: Stack(children: [
                      Positioned.fill(
                        child: nodes.hasData
                            ? StreamBuilder<List<RegisteredParcel>>(
                                stream: _neighbours,
                                builder: (context, neighbours) => SurveyMap(
                                  boundary: ring,
                                  conflicts: [for (final c in conflicts) ...c.rings],
                                  neighbours: [
                                    for (final p in neighbours.data ?? <RegisteredParcel>[])
                                      if (p.id != survey.serverParcelId) p,
                                  ],
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: MediaQuery.paddingOf(context).top + 8,
                        child: Row(children: [
                          _MapButton(icon: Icons.arrow_back, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
                          const Spacer(),
                          if (survey.syncState != SyncState.synced)
                            _MapButton(icon: Icons.delete_outline, tooltip: 'Delete survey', onPressed: () => _delete(survey)),
                        ]),
                      ),
                    ]),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -22),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Palette.ground,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(survey.titleDeedNo, style: mono.copyWith(fontSize: 22)),
                              Text(survey.ownerName, style: const TextStyle(fontSize: 15)),
                            ]),
                          ),
                          StatusPill(status.short, status.tone == Tone.red ? Tone.amber : status.tone),
                        ]),
                        const SizedBox(height: 14),
                        _Outcome(survey: survey, conflicts: conflicts),
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: Panel(child: Fact('Area', formatSqm(survey.areaSqm)))),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Panel(
                              child: Fact('Corners', '${ring.length} · worst ±${worst.toStringAsFixed(worst < 1 ? 2 : 1)} m'),
                            ),
                          ),
                        ]),
                        if (conflicts.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Panel(
                            padding: EdgeInsets.zero,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(14, 12, 14, 4),
                                child: Text('OVERLAPS FOUND BY THE REGISTRY',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Palette.ink2, letterSpacing: 0.6)),
                              ),
                              for (final (i, c) in conflicts.indexed) ...[
                                if (i > 0) const Divider(height: 1),
                                ListTile(
                                  leading: Container(width: 12, height: 12, color: c.blocking ? Palette.red : Palette.amber),
                                  minLeadingWidth: 12,
                                  title: Text(c.titleDeedNo, style: mono.copyWith(fontSize: 14)),
                                  subtitle: Text('${c.ownerName} · ${c.blocking ? 'approved' : 'pending'}'),
                                  trailing: Text('${c.overlapSqm.toStringAsFixed(2)} m²',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                ),
                              ],
                            ]),
                          ),
                        ],
                        if (survey.reviewNote != null) ...[
                          const SizedBox(height: 14),
                          Panel(child: Fact('Registry note', survey.reviewNote!)),
                        ],
                        const SizedBox(height: 16),
                        _Progress(survey),
                        if (survey.syncState == SyncState.failed) ...[
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: () => _editAndRetry(survey),
                            icon: const Icon(Icons.edit),
                            label: const Text('Correct details and resubmit'),
                          ),
                        ],
                      ]),
                    ),
                  ),
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

/// What the result means for the surveyor, in one coloured box.
class _Outcome extends StatelessWidget {
  final Survey survey;
  final List<Conflict> conflicts;

  const _Outcome({required this.survey, required this.conflicts});

  @override
  Widget build(BuildContext context) {
    final blocking = [for (final c in conflicts) if (c.blocking) c.titleDeedNo];
    final (tone, icon, title, text) = switch (survey.syncState) {
      SyncState.failed => (Tone.red, Icons.error_outline, 'Refused.', survey.lastError ?? 'The registry refused this survey.'),
      SyncState.queued => (Tone.neutral, Icons.cloud_upload_outlined, 'Waiting to upload.', 'It uploads as soon as the device has signal.'),
      SyncState.draft => (Tone.blue, Icons.polyline_outlined, 'Not finished.', 'Open it from the list to keep capturing.'),
      SyncState.synced => switch (survey.serverStatus) {
          'APPROVED' => (Tone.green, Icons.check_circle_outline, 'Approved.', 'The boundary is on the registry.'),
          'REJECTED' => (Tone.neutral, Icons.block, 'Rejected.', 'See the registry note below.'),
          _ when blocking.isNotEmpty => (
              Tone.red,
              Icons.warning_amber_rounded,
              'Encroaches on approved land.',
              'The registry will not approve it until the shared boundary with ${blocking.join(' and ')} is resurveyed.'
            ),
          _ when conflicts.isNotEmpty =>
            (Tone.amber, Icons.warning_amber_rounded, 'Overlaps another claim.', 'A reviewer will decide between the pending surveys.'),
          _ => (Tone.amber, Icons.hourglass_top, 'Waiting for a reviewer.', 'No overlaps were found.'),
        },
    };
    return Callout(
      icon: icon,
      tone: tone,
      child: Text.rich(
        key: const Key('outcome'),
        TextSpan(children: [
          TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: text),
        ]),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final Survey survey;

  const _Progress(this.survey);

  @override
  Widget build(BuildContext context) {
    final synced = survey.syncState == SyncState.synced;
    final decided = synced && survey.serverStatus != 'PENDING';
    Widget step(bool done, String title, String? detail) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Palette.green : null,
                border: done ? null : Border.all(color: Palette.amber, width: 2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(text: title, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (detail != null) TextSpan(text: ' · $detail', style: const TextStyle(color: Palette.muted)),
              ])),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      step(true, 'Captured', formatWhen(survey.createdAt)),
      step(synced, synced ? 'Uploaded' : 'Upload pending', null),
      if (synced) step(decided, decided ? 'Decided by the registry' : 'Waiting for a reviewer', null),
    ]);
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _MapButton({required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 3,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        child: IconButton(tooltip: tooltip, icon: Icon(icon, color: Palette.ink), onPressed: onPressed),
      );
}
