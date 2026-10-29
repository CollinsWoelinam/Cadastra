import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/location/position_source.dart';
import 'package:cadastra_field/services/capture_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;
  late TestPositionSource gps;
  late CaptureController capture;

  setUp(() async {
    db = memoryDb();
    gps = TestPositionSource();
    final survey = await createSurvey(db);
    capture = CaptureController(db, gps, survey.id, averagingWindow: const Duration(milliseconds: 50));
    await capture.start();
  });

  tearDown(() async {
    await capture.flush();
    capture.dispose();
    await db.close();
  });

  test('walk mode drops nodes every N metres and closes the loop', () async {
    capture
      ..setMode(CaptureMode.walk)
      ..walkSpacingM = 5
      ..toggleWalking();
    walkRectangle(30, 36).forEach(gps.emit);

    expect(capture.loopClosed, isTrue);
    expect(capture.walking, isFalse);
    // 132 m perimeter / 5 m spacing ≈ 26 nodes, minus the closing stretch.
    expect(capture.nodes.length, inInclusiveRange(24, 27));
    expect(capture.areaSqm, closeTo(30 * 36, 30 * 36 * 0.01));
    await capture.flush();
    expect((await db.nodesOf(capture.surveyId)).length, capture.nodes.length);
    expect((await db.survey(capture.surveyId)).areaSqm, closeTo(capture.areaSqm, 1e-6));
  });

  test('walk mode ignores fixes worse than the accuracy limit', () {
    capture
      ..setMode(CaptureMode.walk)
      ..maxAccuracyM = 5
      ..toggleWalking();
    walkRectangle(30, 36, accuracy: 12).forEach(gps.emit);
    expect(capture.nodes, isEmpty);
    expect(capture.lastFix, isNotNull);
  });

  test('corner mode averages fixes weighted by accuracy', () async {
    final pending = capture.dropCorner();
    expect(capture.averaging, isTrue);
    gps.emit(Fix(offset(0, 0), 1, DateTime.now()));
    gps.emit(Fix(offset(3, 0), 3, DateTime.now())); // weight 1/9 vs 1
    gps.emit(Fix(offset(100, 0), 50, DateTime.now())); // beyond the limit: ignored
    expect(await pending, isNull);

    expect(capture.nodes, hasLength(1));
    final east = (capture.nodes.single.position.longitude - origin.longitude) *
        111320.0 * 0.99518; // cos(5.624°)
    expect(east, closeTo(3 * (1 / 9) / (1 + 1 / 9), 0.01)); // 0.3 m
  });

  test('corner mode reports when no usable fix arrives', () async {
    final pending = capture.dropCorner();
    gps.emit(Fix(offset(0, 0), 40, DateTime.now()));
    expect(await pending, contains('No fix better than'));
    expect(capture.nodes, isEmpty);
  });

  test('undo removes the last node from storage', () async {
    capture
      ..setMode(CaptureMode.walk)
      ..toggleWalking();
    walkRectangle(30, 36).take(40).forEach(gps.emit);
    final before = capture.nodes.length;
    capture.undo();
    await capture.flush();
    expect(capture.nodes.length, before - 1);
    final stored = await db.nodesOf(capture.surveyId);
    expect(stored.map((n) => n.seq), List.generate(before - 1, (i) => i + 1));
  });

  test('finish refuses too few corners and crossing boundaries, then queues', () async {
    expect(await capture.finish(), contains('at least 3'));

    for (final (x, y) in [(0.0, 0.0), (30.0, 36.0), (30.0, 0.0), (0.0, 36.0)]) {
      final pending = capture.dropCorner();
      gps.emit(Fix(offset(x, y), 2, DateTime.now()));
      await pending;
    }
    expect(await capture.finish(), contains('cross'));

    capture.undo();
    expect(await capture.finish(), isNull);
    expect(capture.storageError, isNull);
    expect((await db.survey(capture.surveyId)).syncState, SyncState.queued);
  });

  test('resuming a draft reloads its nodes', () async {
    capture
      ..setMode(CaptureMode.walk)
      ..toggleWalking();
    walkRectangle(30, 36).take(50).forEach(gps.emit);
    await capture.flush();

    final resumed = CaptureController(db, TestPositionSource(), capture.surveyId);
    await resumed.start();
    expect(resumed.nodes.length, capture.nodes.length);
    expect(resumed.areaSqm, closeTo(capture.areaSqm, 1e-6));
    resumed.dispose();
  });

  test('reports location problems instead of listening', () async {
    final blocked = TestPositionSource()..problem = 'Location permission was denied.';
    final c = CaptureController(db, blocked, capture.surveyId);
    await c.start();
    expect(c.locationProblem, contains('denied'));
    c.dispose();
  });
}
