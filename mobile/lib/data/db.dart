import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'db.g.dart';

/// Local lifecycle of a survey on this device.
enum SyncState {
  /// Still being captured.
  draft,

  /// Finished and waiting for upload (or retrying after a network error).
  queued,

  /// Accepted by the Core Engine; [Surveys.serverStatus] tracks the review.
  synced,

  /// Refused by the Core Engine (e.g. duplicate title deed); needs the surveyor.
  failed,
}

class Surveys extends Table {
  /// Generated on the device; doubles as the upload's idempotency key (client_ref).
  TextColumn get id => text()();

  /// Account that captured the survey. Devices can be shared, so each surveyor sees
  /// and uploads only their own work.
  TextColumn get ownerUserId => text().nullable()();
  TextColumn get titleDeedNo => text()();
  TextColumn get ownerName => text()();
  TextColumn get syncState => textEnum<SyncState>()();
  TextColumn get serverParcelId => text().nullable()();

  /// PENDING / APPROVED / REJECTED once synced.
  TextColumn get serverStatus => text().nullable()();
  TextColumn get reviewNote => text().nullable()();

  /// Raw JSON array of conflicts from the Core Engine.
  TextColumn get conflictsJson => text().nullable()();
  TextColumn get lastError => text().nullable()();
  RealColumn get areaSqm => real().withDefault(const Constant(0))();
  RealColumn get perimeterM => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Nodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get surveyId => text().references(Surveys, #id, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get accuracyM => real()();
  DateTimeColumn get capturedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {surveyId, seq},
      ];
}

@DriftDatabase(tables: [Surveys, Nodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'cadastra_field'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(surveys, surveys.ownerUserId);
        },
        beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
      );

  Stream<List<Survey>> watchSurveys(String ownerUserId) => (select(surveys)
        ..where((s) => s.ownerUserId.equals(ownerUserId))
        ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
      .watch();

  /// Surveys captured before accounts existed belong to whoever signs in first.
  Future<void> claimUnownedSurveys(String ownerUserId) =>
      (update(surveys)..where((s) => s.ownerUserId.isNull())).write(SurveysCompanion(ownerUserId: Value(ownerUserId)));

  Stream<Survey> watchSurvey(String id) =>
      (select(surveys)..where((s) => s.id.equals(id))).watchSingle();

  Future<Survey> survey(String id) => (select(surveys)..where((s) => s.id.equals(id))).getSingle();

  Future<List<Survey>> surveysIn(SyncState state, String ownerUserId) => (select(surveys)
        ..where((s) => s.syncState.equalsValue(state) & s.ownerUserId.equals(ownerUserId)))
      .get();

  Future<List<Node>> nodesOf(String surveyId) => (select(nodes)
        ..where((n) => n.surveyId.equals(surveyId))
        ..orderBy([(n) => OrderingTerm.asc(n.seq)]))
      .get();

  Future<void> updateSurvey(String id, SurveysCompanion changes) =>
      (update(surveys)..where((s) => s.id.equals(id)))
          .write(changes.copyWith(updatedAt: Value(DateTime.now())));
}
