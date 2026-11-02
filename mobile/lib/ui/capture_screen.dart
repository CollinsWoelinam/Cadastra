import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app.dart';
import '../data/db.dart';
import '../geo/encroachment.dart';
import '../geo/polygon_math.dart';
import '../geo/tiles.dart';
import '../services/capture_controller.dart';
import 'format.dart';
import 'survey_map.dart';

class CaptureScreen extends StatefulWidget {
  final String surveyId;

  const CaptureScreen({super.key, required this.surveyId});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late final CaptureController capture;
  final _map = MapController();
  bool _mapReady = false;
  bool _follow = true;
  Survey? _survey;

  // Registered parcels within ~1.5 km, re-centred if the surveyor moves 1 km away.
  static const _areaRadiusM = 1500.0;
  LatLng? _areaCentre;
  StreamSubscription<List<RegisteredParcel>>? _neighbourSub;
  List<RegisteredParcel> _neighbours = const [];

  /// Null until the first refresh finishes; false if the registry was unreachable.
  bool? _neighboursLive;

  /// The status panel folds to one line so it does not hide the boundary being walked.
  bool _panelCollapsed = false;

  @override
  void initState() {
    super.initState();
    final services = Services.read(context);
    capture = CaptureController(services.db, services.positionSource(), widget.surveyId)
      ..addListener(_onCaptureChanged)
      ..start();
    services.db.survey(widget.surveyId).then((s) => mounted ? setState(() => _survey = s) : null);
    WakelockPlus.enable().ignore();
  }

  @override
  void dispose() {
    _neighbourSub?.cancel();
    capture
      ..removeListener(_onCaptureChanged)
      ..dispose();
    WakelockPlus.disable().ignore();
    super.dispose();
  }

  void _onCaptureChanged() {
    final fix = capture.lastFix;
    if (_follow && _mapReady && fix != null) _map.move(fix.position, _map.camera.zoom);
    final here = capture.nodes.isNotEmpty ? capture.nodes.last.position : fix?.position;
    if (here != null && (_areaCentre == null || PolygonMath.distance(_areaCentre!, here) > 1000)) _watchArea(here);
  }

  void _watchArea(LatLng centre) {
    final services = Services.read(context);
    _areaCentre = centre;
    final area = GeoBounds.around(centre, _areaRadiusM);
    _neighbourSub?.cancel();
    _neighbourSub = services.db.watchRegisteredParcelsIn(area).listen((parcels) {
      if (!mounted) return;
      // A resubmitted survey must not be compared with its own earlier upload.
      setState(
        () => _neighbours = [
          for (final p in parcels)
            if (p.id != _survey?.serverParcelId) p,
        ],
      );
    });
    services.neighbours.refresh(area).then((n) => mounted ? setState(() => _neighboursLive = n != null) : null);
  }

  String? get _neighbourNote {
    final n = _neighbours.length;
    final parcels = '$n registered parcel${n == 1 ? '' : 's'}';
    return switch (_neighboursLive) {
      null when n == 0 => null,
      false when n == 0 => 'Offline — no registered parcels saved for this area',
      false => 'Offline — showing $parcels saved on this device',
      _ => n == 0 ? 'No registered parcels nearby' : '$parcels nearby',
    };
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _recordCorner() async {
    final error = await capture.dropCorner();
    if (error != null && mounted) _snack(error);
  }

  Future<void> _finish() async {
    final blocking = findEncroachments(capture.ring, _neighbours).where((e) => e.blocking).toList();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish survey?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${capture.nodes.length} corners · ${formatArea(capture.areaSqm)}\n'
              'The boundary will be uploaded for validation as soon as the device is online.',
            ),
            if (blocking.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'It overlaps approved parcel${blocking.length == 1 ? '' : 's'} '
                '${blocking.map((e) => e.parcel.titleDeedNo).join(', ')}, so the registry cannot approve it as is. '
                'If that is GPS error along a shared boundary, re-take those corners first.',
                key: const Key('finish-overlap-warning'),
                style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep surveying')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finish')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final error = await capture.finish();
    if (!mounted) return;
    if (error != null) return _snack(error);
    Services.read(context).sync.sync();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_survey?.titleDeedNo ?? 'Survey'),
        actions: [IconButton(tooltip: 'Capture settings', icon: const Icon(Icons.tune), onPressed: _settings)],
      ),
      body: ListenableBuilder(
        listenable: capture,
        builder: (context, _) {
          final encroachments = findEncroachments(capture.ring, _neighbours);
          return Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  // Panning by hand stops the map following the GPS.
                  onPointerMove: (_) => _follow ? setState(() => _follow = false) : null,
                  child: SurveyMap(
                    controller: _map,
                    boundary: capture.ring,
                    position: capture.lastFix,
                    onMapReady: () => _mapReady = true,
                    neighbours: _neighbours,
                    encroached: {for (final e in encroachments) e.parcel.id},
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                top: 12,
                child: _StatusPanel(
                  capture,
                  encroachments: encroachments,
                  neighbourNote: _neighbourNote,
                  collapsed: _panelCollapsed,
                  onToggle: () => setState(() => _panelCollapsed = !_panelCollapsed),
                ),
              ),
            ],
          );
        },
      ),
      // As Scaffold slots (not Stack children) these keep snackbars from covering them.
      floatingActionButton: FloatingActionButton.small(
        heroTag: 'follow',
        tooltip: 'Follow my position',
        onPressed: () => setState(() => _follow = true),
        child: Icon(_follow ? Icons.my_location : Icons.location_searching),
      ),
      bottomNavigationBar: ListenableBuilder(listenable: capture, builder: (context, _) => _controls(context)),
    );
  }

  Widget _controls(BuildContext context) {
    final walkMode = capture.mode == CaptureMode.walk;
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<CaptureMode>(
                segments: const [
                  ButtonSegment(value: CaptureMode.corner, icon: Icon(Icons.place), label: Text('Corners')),
                  ButtonSegment(value: CaptureMode.walk, icon: Icon(Icons.directions_walk), label: Text('Walk')),
                ],
                selected: {capture.mode},
                onSelectionChanged: (s) => capture.setMode(s.single),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: walkMode
                    ? FilledButton.icon(
                        key: const Key('walk'),
                        onPressed: capture.locationProblem == null ? capture.toggleWalking : null,
                        icon: Icon(capture.walking ? Icons.pause : Icons.play_arrow),
                        label: Text(capture.walking ? 'Pause walking' : 'Start walking the boundary'),
                      )
                    : FilledButton.icon(
                        key: const Key('corner'),
                        onPressed: capture.locationProblem == null && !capture.averaging ? _recordCorner : null,
                        icon: capture.averaging
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.add_location),
                        label: Text(
                          capture.averaging ? 'Hold still — averaging…' : 'Record corner ${capture.nodes.length + 1}',
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: capture.nodes.isEmpty ? null : capture.undo,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('finish'),
                      onPressed: capture.nodes.length >= 3 ? _finish : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Finish'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _settings() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: capture,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reject fixes worse than', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in const [0.05, 1.0, 3.0, 5.0, 10.0, 20.0])
                    ChoiceChip(
                      label: Text(m < 1 ? '±${(m * 100).round()} cm (RTK)' : '±${m.round()} m'),
                      selected: capture.maxAccuracyM == m,
                      onSelected: (_) => capture.setMaxAccuracy(m),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Walk mode: drop a node every ${capture.walkSpacingM.round()} m',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Slider(
                value: capture.walkSpacingM,
                min: 1,
                max: 20,
                divisions: 19,
                label: '${capture.walkSpacingM.round()} m',
                onChanged: capture.setWalkSpacing,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatusPanel extends StatelessWidget {
  final CaptureController capture;
  final List<Encroachment> encroachments;
  final String? neighbourNote;
  final bool collapsed;
  final VoidCallback onToggle;

  const _StatusPanel(
    this.capture, {
    required this.encroachments,
    this.neighbourNote,
    required this.collapsed,
    required this.onToggle,
  });

  static String _describe(Encroachment e) {
    final what = e.blocking ? 'approved' : 'pending';
    final d = e.depthM;
    if (d == 0) return 'Crosses $what ${e.parcel.titleDeedNo}';
    return 'Inside $what ${e.parcel.titleDeedNo} by ${d < 1 ? '${(d * 100).round()} cm' : '${d.toStringAsFixed(1)} m'}';
  }

  @override
  Widget build(BuildContext context) {
    final fix = capture.lastFix;
    final (gpsText, gpsColor) = switch (fix) {
      _ when capture.locationProblem != null => (capture.locationProblem!, Colors.red),
      null => ('Waiting for GPS…', Colors.grey),
      _ when !capture.isUsable(fix) => (
        'GPS ±${fix.accuracyM.toStringAsFixed(1)} m — too poor, not recording',
        Colors.red,
      ),
      _ when fix.accuracyM <= 1 => ('GPS ±${fix.accuracyM.toStringAsFixed(2)} m', Colors.green),
      _ => ('GPS ±${fix.accuracyM.toStringAsFixed(1)} m', Colors.orange.shade800),
    };
    final gpsRow = Row(
      children: [
        Icon(Icons.satellite_alt, size: 18, color: gpsColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            gpsText,
            key: const Key('gps'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: gpsColor, fontWeight: FontWeight.w600),
          ),
        ),
        if (capture.walking) const Chip(label: Text('Recording'), visualDensity: VisualDensity.compact),
        Icon(collapsed ? Icons.expand_more : Icons.expand_less, color: Colors.black45),
      ],
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('status-panel'),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: collapsed ? _summary(gpsRow) : _details(context, gpsRow),
        ),
      ),
    );
  }

  /// One line: GPS, corners, and overlaps (never hidden while there are any).
  Widget _summary(Widget gpsRow) {
    final blocking = encroachments.where((e) => e.blocking).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        gpsRow,
        const SizedBox(height: 4),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${capture.nodes.length} corners · ${capture.areaSqm.toStringAsFixed(1)} m²'),
              if (encroachments.isNotEmpty)
                TextSpan(
                  text: ' · ${encroachments.length} overlap${encroachments.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: blocking > 0 ? Colors.red.shade700 : Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (capture.loopClosed)
                const TextSpan(
                  text: ' · closed',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          key: const Key('status-summary'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _details(BuildContext context, Widget gpsRow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        gpsRow,
        const SizedBox(height: 6),
        Text(
          '${capture.nodes.length} corners · ${formatArea(capture.areaSqm)} · ${formatLength(capture.perimeterM)} perimeter',
          key: const Key('measures'),
        ),
        if (capture.loopClosed)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Back at the first corner — boundary closed. Review and tap Finish.',
              key: Key('loop-closed'),
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
            ),
          ),
        if (capture.selfIntersects)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Boundary lines cross — undo the last corners.', style: TextStyle(color: Colors.red)),
          ),
        // Kept short: the panel sits over the map the surveyor is following.
        for (final (i, e) in encroachments.take(2).indexed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _describe(e),
              key: i == 0 ? const Key('encroachment') : null,
              style: TextStyle(
                color: e.blocking ? Colors.red.shade700 : Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (encroachments.length > 2)
          Text(
            'and ${encroachments.length - 2} more overlap${encroachments.length == 3 ? '' : 's'}',
            style: TextStyle(color: Colors.red.shade700),
          ),
        if (capture.storageError != null) Text(capture.storageError!, style: const TextStyle(color: Colors.red)),
        if (neighbourNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              neighbourNote!,
              key: const Key('neighbours'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
