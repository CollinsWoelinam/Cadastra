import 'dart:async';
import 'dart:math' as math;

import 'package:cadastra_field/data/db.dart';
import 'package:cadastra_field/location/position_source.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:latlong2/latlong.dart';

const origin = LatLng(5.6240, -0.1700); // Accra

/// Offset [origin] by metres east/north.
LatLng offset(double east, double north) => LatLng(
      origin.latitude + north / 110574.0,
      origin.longitude + east / (111320.0 * math.cos(origin.latitude * math.pi / 180)),
    );

/// Fixes every [step] metres around a w × h rectangle, ending back at the start.
List<Fix> walkRectangle(double w, double h, {double step = 1, double accuracy = 3}) {
  final corners = [(0.0, 0.0), (w, 0.0), (w, h), (0.0, h), (0.0, 0.0)];
  final fixes = <Fix>[];
  for (var i = 0; i < corners.length - 1; i++) {
    final (x0, y0) = corners[i];
    final (x1, y1) = corners[i + 1];
    final len = math.sqrt(math.pow(x1 - x0, 2) + math.pow(y1 - y0, 2));
    for (var d = 0.0; d < len; d += step) {
      fixes.add(Fix(offset(x0 + (x1 - x0) * d / len, y0 + (y1 - y0) * d / len), accuracy, DateTime.now()));
    }
  }
  fixes.add(Fix(offset(0, 0), accuracy, DateTime.now()));
  return fixes;
}

class TestPositionSource implements PositionSource {
  final controller = StreamController<Fix>.broadcast(sync: true);
  String? problem;

  @override
  Future<String?> prepare() async => problem;

  @override
  Stream<Fix> get fixes => controller.stream;

  void emit(Fix fix) => controller.add(fix);
}

AppDatabase memoryDb() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

Future<Survey> createSurvey(AppDatabase db, {String id = 'a1b2c3d4-0000-4000-8000-000000000001', String deed = 'GA/T/1'}) async {
  final now = DateTime.now();
  await db.into(db.surveys).insert(SurveysCompanion.insert(
        id: id,
        titleDeedNo: deed,
        ownerName: 'Ama Mensah',
        syncState: SyncState.draft,
        createdAt: now,
        updatedAt: now,
      ));
  return db.survey(id);
}
