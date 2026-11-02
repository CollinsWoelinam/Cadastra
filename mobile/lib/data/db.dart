import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../geo/tiles.dart';

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

/// Approved and pending parcels from the registry, kept on the device so the map
/// and overlap warnings work without signal. Refreshed whenever the device is online.
class RegisteredParcels extends Table {
  TextColumn get id => text()();
  TextColumn get titleDeedNo => text()();
  TextColumn get ownerName => text()();

  /// APPROVED or PENDING.
  TextColumn get status => text()();

  /// Outer ring as a JSON array of [lon, lat] pairs.
  TextColumn get ringJson => text()();
  RealColumn get south => real()();
  RealColumn get west => real()();
  RealColumn get north => real()();
  RealColumn get east => real()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// An area saved for offline fieldwork: registered parcels and, where the basemap
/// provider allows it, map tiles.
class OfflineAreas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get south => real()();
  RealColumn get west => real()();
  RealColumn get north => real()();
  RealColumn get east => real()();
  IntColumn get minZoom => integer()();
  IntColumn get maxZoom => integer()();

  /// Basemap URL template the tiles came from; null when only parcels were saved.
  TextColumn get tileSource => text().nullable()();
  IntColumn get tileCount => integer().withDefault(const Constant(0))();
  IntColumn get bytes => integer().withDefault(const Constant(0))();
  IntColumn get parcelCount => integer().withDefault(const Constant(0))();

  /// False while downloading, or if it was cancelled or partly failed.
  BoolColumn get complete => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();
}

final _rings = Expando<List<LatLng>>();

extension RegisteredParcelRing on RegisteredParcel {
  /// Outer ring without the repeated closing point.
  List<LatLng> get ring => _rings[this] ??= () {
        final pts = [
          for (final p in jsonDecode(ringJson) as List) LatLng((p[1] as num).toDouble(), (p[0] as num).toDouble())
        ];
        if (pts.length > 1 && pts.first == pts.last) pts.removeLast();
        return pts;
      }();

  GeoBounds get bounds => GeoBounds(south, west, north, east);
}

extension OfflineAreaBounds on OfflineArea {
  GeoBounds get bounds => GeoBounds(south, west, north, east);
}

@DriftDatabase(tables: [Surveys, Nodes, RegisteredParcels, OfflineAreas])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? driftDatabase(name: 'cadastra_field'));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(surveys, surveys.ownerUserId);
          if (from < 3) {
            await m.createTable(registeredParcels);
            await m.createTable(offlineAreas);
          }
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

  /// Replaces the cached parcels in [area] with a fresh download. The API returns every
  /// parcel whose bounding box meets [area], so cached ones it no longer returns were
  /// rejected or removed. When the download was truncated ([complete] false), nothing
  /// is removed.
  Future<void> replaceRegisteredParcels(GeoBounds area, List<RegisteredParcelsCompanion> parcels,
      {bool complete = true}) =>
      transaction(() async {
        if (complete) {
          await (delete(registeredParcels)
                ..where((p) =>
                    p.south.isSmallerOrEqualValue(area.north) &
                    p.north.isBiggerOrEqualValue(area.south) &
                    p.west.isSmallerOrEqualValue(area.east) &
                    p.east.isBiggerOrEqualValue(area.west)))
              .go();
        }
        await batch((b) => b.insertAllOnConflictUpdate(registeredParcels, parcels));
      });

  SimpleSelectStatement<$RegisteredParcelsTable, RegisteredParcel> _parcelsIn(GeoBounds area) =>
      select(registeredParcels)
        ..where((p) =>
            p.south.isSmallerOrEqualValue(area.north) &
            p.north.isBiggerOrEqualValue(area.south) &
            p.west.isSmallerOrEqualValue(area.east) &
            p.east.isBiggerOrEqualValue(area.west));

  Stream<List<RegisteredParcel>> watchRegisteredParcelsIn(GeoBounds area) => _parcelsIn(area).watch();

  Future<List<RegisteredParcel>> registeredParcelsIn(GeoBounds area) => _parcelsIn(area).get();

  Stream<List<OfflineArea>> watchOfflineAreas() =>
      (select(offlineAreas)..orderBy([(a) => OrderingTerm.desc(a.updatedAt)])).watch();
}
