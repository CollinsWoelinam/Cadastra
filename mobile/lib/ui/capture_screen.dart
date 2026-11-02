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
import 'theme.dart';
import 'widgets.dart';

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
                top: MediaQuery.paddingOf(context).top + 8,
                child: Column(
                  children: [
                    _TopBar(survey: _survey, onSettings: _settings),
                    const SizedBox(height: 10),
                    _StatusPanel(
                      capture,
                      encroachments: encroachments,
                      neighbourNote: _neighbourNote,
                      collapsed: _panelCollapsed,
                      onToggle: () => setState(() => _panelCollapsed = !_panelCollapsed),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 14,
                bottom: 14,
                child: Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  child: IconButton(
                    tooltip: 'Follow my position',
                    iconSize: 24,
                    padding: const EdgeInsets.all(12),
                    onPressed: () => setState(() => _follow = true),
                    icon: Icon(_follow ? Icons.my_location : Icons.location_searching, color: Palette.green),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // A Scaffold slot (not a Stack child), so snackbars float above the controls.
      bottomNavigationBar: ListenableBuilder(listenable: capture, builder: (context, _) => _controls(context)),
    );
  }

  Widget _controls(BuildContext context) {
    final walkMode = capture.mode == CaptureMode.walk;
    final ready = capture.locationProblem == null;
    final (title, hint) = walkMode
        ? (
            capture.walking ? 'Pause walking' : 'Start walking the boundary',
            'Drops a corner every ${capture.walkSpacingM.round()} m',
          )
        : (
            capture.averaging ? 'Hold still — averaging…' : 'Record corner ${capture.nodes.length + 1}',
            'Hold the pole still · averages 3 s',
          );
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [BoxShadow(color: Color(0x240F1B17), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Palette.lineStrong, borderRadius: BorderRadius.circular(99)),
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<CaptureMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: CaptureMode.corner, icon: Icon(Icons.place_outlined), label: Text('Corners')),
                  ButtonSegment(value: CaptureMode.walk, icon: Icon(Icons.directions_walk), label: Text('Walk')),
                ],
                selected: {capture.mode},
                onSelectionChanged: (s) => capture.setMode(s.single),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: FilledButton(
                  key: Key(walkMode ? 'walk' : 'corner'),
                  onPressed: !ready
                      ? null
                      : walkMode
                      ? capture.toggleWalking
                      : capture.averaging
                      ? null
                      : _recordCorner,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        hint,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFCFE8DD)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: capture.nodes.isEmpty ? null : capture.undo,
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('finish'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        backgroundColor: Palette.greenTint,
                        foregroundColor: Palette.greenInk,
                      ),
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

class _TopBar extends StatelessWidget {
  final Survey? survey;
  final VoidCallback onSettings;

  const _TopBar({required this.survey, required this.onSettings});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    shadowColor: Colors.black26,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back to surveys',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(survey?.titleDeedNo ?? 'Survey', style: mono.copyWith(fontSize: 15)),
                if (survey != null) Text(survey!.ownerName, style: const TextStyle(fontSize: 12, color: Palette.muted)),
              ],
            ),
          ),
          IconButton(tooltip: 'Capture settings', icon: const Icon(Icons.tune), onPressed: onSettings),
        ],
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
    final (gpsText, tone) = switch (fix) {
      _ when capture.locationProblem != null => (capture.locationProblem!, Tone.red),
      null => ('Waiting for GPS…', Tone.neutral),
      _ when !capture.isUsable(fix) => (
        'GPS ±${fix.accuracyM.toStringAsFixed(1)} m — too poor, not recording',
        Tone.red,
      ),
      _ when fix.accuracyM <= 1 => ('GPS ±${fix.accuracyM.toStringAsFixed(2)} m', Tone.green),
      _ => ('GPS ±${fix.accuracyM.toStringAsFixed(1)} m', Tone.amber),
    };
    final gpsRow = Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: tone.tint, borderRadius: BorderRadius.circular(99)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.satellite_alt, size: 14, color: tone.text),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      gpsText,
                      key: const Key('gps'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: tone.text, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (capture.walking) const StatusPill('Recording', Tone.blue),
        const SizedBox(width: 4),
        Icon(collapsed ? Icons.expand_more : Icons.expand_less, color: Palette.muted),
      ],
    );
    return Material(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('status-panel'),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: collapsed ? _summary(gpsRow) : _details(gpsRow),
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
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '${capture.nodes.length} corners · ${capture.areaSqm.toStringAsFixed(1)} m²'),
              if (encroachments.isNotEmpty)
                TextSpan(
                  text: ' · ${encroachments.length} overlap${encroachments.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: blocking > 0 ? Palette.redText : Palette.amberInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              if (capture.loopClosed)
                const TextSpan(
                  text: ' · closed',
                  style: TextStyle(color: Palette.greenInk, fontWeight: FontWeight.w700),
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

  Widget _details(Widget gpsRow) {
    Widget note(String text, Tone t, IconData icon, {Key? key}) => Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: t.tint, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, size: 16, color: t.text),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                key: key,
                style: TextStyle(color: t.text, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        gpsRow,
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: Fact('Corners', '${capture.nodes.length}', valueKey: const Key('corners'))),
            Expanded(child: Fact('Area', formatSqm(capture.areaSqm), valueKey: const Key('area'))),
            Expanded(child: Fact('Perimeter', formatLength(capture.perimeterM), valueKey: const Key('perimeter'))),
          ],
        ),
        if (capture.loopClosed)
          note(
            'Back at the first corner — boundary closed. Review and tap Finish.',
            Tone.green,
            Icons.check_circle_outline,
            key: const Key('loop-closed'),
          ),
        if (capture.selfIntersects)
          note('Boundary lines cross — undo the last corners.', Tone.red, Icons.error_outline),
        // Kept short: the panel sits over the map the surveyor is following.
        for (final (i, e) in encroachments.take(2).indexed)
          note(
            _describe(e),
            e.blocking ? Tone.red : Tone.amber,
            Icons.warning_amber_rounded,
            key: i == 0 ? const Key('encroachment') : null,
          ),
        if (encroachments.length > 2)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'and ${encroachments.length - 2} more overlap${encroachments.length == 3 ? '' : 's'}',
              style: const TextStyle(color: Palette.redText, fontWeight: FontWeight.w600),
            ),
          ),
        if (capture.storageError != null) note(capture.storageError!, Tone.red, Icons.sd_card_alert_outlined),
        if (neighbourNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              neighbourNote!,
              key: const Key('neighbours'),
              style: const TextStyle(fontSize: 12, color: Palette.muted),
            ),
          ),
      ],
    );
  }
}
