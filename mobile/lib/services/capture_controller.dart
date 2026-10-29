import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/db.dart';
import '../geo/polygon_math.dart';
import '../location/position_source.dart';

enum CaptureMode {
  /// Surveyor stands on each corner and taps; fixes are averaged over a short window.
  corner,

  /// A node is dropped automatically every [CaptureController.walkSpacingM] metres.
  walk,
}

class CapturedNode {
  final LatLng position;
  final double accuracyM;
  final DateTime capturedAt;

  const CapturedNode(this.position, this.accuracyM, this.capturedAt);
}

/// Drives boundary capture for one survey. Nodes are persisted as they are taken,
/// so a crash or dead battery mid-survey loses nothing.
class CaptureController extends ChangeNotifier {
  final AppDatabase db;
  final PositionSource source;
  final String surveyId;
  final Duration averagingWindow;

  CaptureMode mode = CaptureMode.corner;
  double walkSpacingM = 5;

  /// Fixes worse than this are ignored for node capture.
  double maxAccuracyM = 10;

  final List<CapturedNode> nodes = [];
  Fix? lastFix;
  bool walking = false;
  bool averaging = false;

  /// Why positions are unavailable (permissions, services off), if they are.
  String? locationProblem;

  /// Set when walk mode stops itself on returning to the first node.
  bool loopClosed = false;

  /// Set if a node could not be written to local storage.
  String? storageError;

  StreamSubscription<Fix>? _sub;
  final List<Fix> _window = [];
  Future<void> _writes = Future.value();

  CaptureController(this.db, this.source, this.surveyId,
      {this.averagingWindow = const Duration(seconds: 3)});

  Future<void> start() async {
    final stored = await db.nodesOf(surveyId);
    nodes.addAll(stored.map((n) => CapturedNode(LatLng(n.lat, n.lon), n.accuracyM, n.capturedAt)));
    locationProblem = await source.prepare();
    if (locationProblem == null) _sub = source.fixes.listen(_onFix);
    notifyListeners();
  }

  List<LatLng> get ring => [for (final n in nodes) n.position];
  double get areaSqm => PolygonMath.area(ring);
  double get perimeterM => PolygonMath.perimeter(ring);
  bool get selfIntersects => PolygonMath.selfIntersects(ring);
  bool isUsable(Fix fix) => fix.accuracyM <= maxAccuracyM;

  void _onFix(Fix fix) {
    lastFix = fix;
    if (isUsable(fix)) {
      if (averaging) _window.add(fix);
      if (mode == CaptureMode.walk && walking) _walkStep(fix);
    }
    notifyListeners();
  }

  void _walkStep(Fix fix) {
    if (nodes.isEmpty) return _add(CapturedNode(fix.position, fix.accuracyM, fix.time));
    final fromLast = PolygonMath.distance(nodes.last.position, fix.position);
    if (fromLast < walkSpacingM) return;
    final backAtStart = nodes.length >= 3 &&
        PolygonMath.distance(nodes.first.position, fix.position) < walkSpacingM;
    if (backAtStart) {
      walking = false;
      loopClosed = true;
      return;
    }
    _add(CapturedNode(fix.position, fix.accuracyM, fix.time));
  }

  void setMode(CaptureMode m) {
    mode = m;
    walking = false;
    notifyListeners();
  }

  void setMaxAccuracy(double metres) {
    maxAccuracyM = metres;
    notifyListeners();
  }

  void setWalkSpacing(double metres) {
    walkSpacingM = metres;
    notifyListeners();
  }

  void toggleWalking() {
    walking = !walking;
    loopClosed = false;
    if (walking && lastFix != null && isUsable(lastFix!)) _walkStep(lastFix!);
    notifyListeners();
  }

  /// Averages usable fixes over [averagingWindow] into one corner node.
  /// Returns an error message if no usable fix arrived.
  Future<String?> dropCorner() async {
    if (averaging) return null;
    _window.clear();
    averaging = true;
    notifyListeners();
    await Future<void>.delayed(averagingWindow);
    averaging = false;
    if (_window.isEmpty) {
      notifyListeners();
      return 'No fix better than ±${maxAccuracyM.toStringAsFixed(0)} m — wait for a better signal.';
    }
    // Inverse-variance weighted mean. Reported accuracy is the weighted mean of the
    // inputs, not reduced by √n: GNSS errors are correlated over a few seconds.
    var wSum = 0.0, lat = 0.0, lon = 0.0, acc = 0.0;
    for (final f in _window) {
      final w = 1 / (f.accuracyM * f.accuracyM + 1e-6);
      wSum += w;
      lat += w * f.position.latitude;
      lon += w * f.position.longitude;
      acc += w * f.accuracyM;
    }
    _add(CapturedNode(LatLng(lat / wSum, lon / wSum), acc / wSum, _window.last.time));
    return null;
  }

  void _add(CapturedNode node) {
    nodes.add(node);
    final seq = nodes.length;
    final area = areaSqm, perimeter = perimeterM;
    _enqueue(() async {
      await db.into(db.nodes).insert(NodesCompanion.insert(
            surveyId: surveyId,
            seq: seq,
            lat: node.position.latitude,
            lon: node.position.longitude,
            accuracyM: node.accuracyM,
            capturedAt: node.capturedAt,
          ));
      await _saveMeasures(area, perimeter);
    });
    notifyListeners();
  }

  void undo() {
    if (nodes.isEmpty) return;
    final seq = nodes.length;
    nodes.removeLast();
    final area = areaSqm, perimeter = perimeterM;
    _enqueue(() async {
      await (db.delete(db.nodes)..where((n) => n.surveyId.equals(surveyId) & n.seq.equals(seq))).go();
      await _saveMeasures(area, perimeter);
    });
    notifyListeners();
  }

  /// Validates the boundary and queues the survey for upload.
  Future<String?> finish() async {
    if (nodes.length < 3) return 'A boundary needs at least 3 corners.';
    if (selfIntersects) return 'Boundary lines cross each other. Undo the last corners and re-walk.';
    walking = false;
    await _writes;
    await db.updateSurvey(surveyId, const SurveysCompanion(syncState: Value(SyncState.queued)));
    return null;
  }

  /// Serialises storage writes; a failed write is reported without blocking later ones.
  void _enqueue(Future<void> Function() write) {
    _writes = _writes.then((_) => write()).catchError((Object e) {
      storageError = 'Could not save to device storage: $e';
      notifyListeners();
    });
  }

  Future<void> _saveMeasures(double area, double perimeter) =>
      db.updateSurvey(surveyId, SurveysCompanion(areaSqm: Value(area), perimeterM: Value(perimeter)));

  /// Waits for pending node writes; mainly for tests.
  Future<void> flush() => _writes;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
