// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// ignore_for_file: type=lint
class $SurveysTable extends Surveys with TableInfo<$SurveysTable, Survey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerUserIdMeta = const VerificationMeta(
    'ownerUserId',
  );
  @override
  late final GeneratedColumn<String> ownerUserId = GeneratedColumn<String>(
    'owner_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleDeedNoMeta = const VerificationMeta(
    'titleDeedNo',
  );
  @override
  late final GeneratedColumn<String> titleDeedNo = GeneratedColumn<String>(
    'title_deed_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SyncState>($SurveysTable.$convertersyncState);
  static const VerificationMeta _serverParcelIdMeta = const VerificationMeta(
    'serverParcelId',
  );
  @override
  late final GeneratedColumn<String> serverParcelId = GeneratedColumn<String>(
    'server_parcel_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverStatusMeta = const VerificationMeta(
    'serverStatus',
  );
  @override
  late final GeneratedColumn<String> serverStatus = GeneratedColumn<String>(
    'server_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewNoteMeta = const VerificationMeta(
    'reviewNote',
  );
  @override
  late final GeneratedColumn<String> reviewNote = GeneratedColumn<String>(
    'review_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _conflictsJsonMeta = const VerificationMeta(
    'conflictsJson',
  );
  @override
  late final GeneratedColumn<String> conflictsJson = GeneratedColumn<String>(
    'conflicts_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaSqmMeta = const VerificationMeta(
    'areaSqm',
  );
  @override
  late final GeneratedColumn<double> areaSqm = GeneratedColumn<double>(
    'area_sqm',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _perimeterMMeta = const VerificationMeta(
    'perimeterM',
  );
  @override
  late final GeneratedColumn<double> perimeterM = GeneratedColumn<double>(
    'perimeter_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ownerUserId,
    titleDeedNo,
    ownerName,
    syncState,
    serverParcelId,
    serverStatus,
    reviewNote,
    conflictsJson,
    lastError,
    areaSqm,
    perimeterM,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surveys';
  @override
  VerificationContext validateIntegrity(
    Insertable<Survey> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('owner_user_id')) {
      context.handle(
        _ownerUserIdMeta,
        ownerUserId.isAcceptableOrUnknown(
          data['owner_user_id']!,
          _ownerUserIdMeta,
        ),
      );
    }
    if (data.containsKey('title_deed_no')) {
      context.handle(
        _titleDeedNoMeta,
        titleDeedNo.isAcceptableOrUnknown(
          data['title_deed_no']!,
          _titleDeedNoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_titleDeedNoMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerNameMeta);
    }
    if (data.containsKey('server_parcel_id')) {
      context.handle(
        _serverParcelIdMeta,
        serverParcelId.isAcceptableOrUnknown(
          data['server_parcel_id']!,
          _serverParcelIdMeta,
        ),
      );
    }
    if (data.containsKey('server_status')) {
      context.handle(
        _serverStatusMeta,
        serverStatus.isAcceptableOrUnknown(
          data['server_status']!,
          _serverStatusMeta,
        ),
      );
    }
    if (data.containsKey('review_note')) {
      context.handle(
        _reviewNoteMeta,
        reviewNote.isAcceptableOrUnknown(data['review_note']!, _reviewNoteMeta),
      );
    }
    if (data.containsKey('conflicts_json')) {
      context.handle(
        _conflictsJsonMeta,
        conflictsJson.isAcceptableOrUnknown(
          data['conflicts_json']!,
          _conflictsJsonMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('area_sqm')) {
      context.handle(
        _areaSqmMeta,
        areaSqm.isAcceptableOrUnknown(data['area_sqm']!, _areaSqmMeta),
      );
    }
    if (data.containsKey('perimeter_m')) {
      context.handle(
        _perimeterMMeta,
        perimeterM.isAcceptableOrUnknown(data['perimeter_m']!, _perimeterMMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Survey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Survey(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ownerUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_user_id'],
      ),
      titleDeedNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_deed_no'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      )!,
      syncState: $SurveysTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      serverParcelId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_parcel_id'],
      ),
      serverStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_status'],
      ),
      reviewNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_note'],
      ),
      conflictsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflicts_json'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      areaSqm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}area_sqm'],
      )!,
      perimeterM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}perimeter_m'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SurveysTable createAlias(String alias) {
    return $SurveysTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SyncState, String, String> $convertersyncState =
      const EnumNameConverter<SyncState>(SyncState.values);
}

class Survey extends DataClass implements Insertable<Survey> {
  /// Generated on the device; doubles as the upload's idempotency key (client_ref).
  final String id;

  /// Account that captured the survey. Devices can be shared, so each surveyor sees
  /// and uploads only their own work.
  final String? ownerUserId;
  final String titleDeedNo;
  final String ownerName;
  final SyncState syncState;
  final String? serverParcelId;

  /// PENDING / APPROVED / REJECTED once synced.
  final String? serverStatus;
  final String? reviewNote;

  /// Raw JSON array of conflicts from the Core Engine.
  final String? conflictsJson;
  final String? lastError;
  final double areaSqm;
  final double perimeterM;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Survey({
    required this.id,
    this.ownerUserId,
    required this.titleDeedNo,
    required this.ownerName,
    required this.syncState,
    this.serverParcelId,
    this.serverStatus,
    this.reviewNote,
    this.conflictsJson,
    this.lastError,
    required this.areaSqm,
    required this.perimeterM,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || ownerUserId != null) {
      map['owner_user_id'] = Variable<String>(ownerUserId);
    }
    map['title_deed_no'] = Variable<String>(titleDeedNo);
    map['owner_name'] = Variable<String>(ownerName);
    {
      map['sync_state'] = Variable<String>(
        $SurveysTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || serverParcelId != null) {
      map['server_parcel_id'] = Variable<String>(serverParcelId);
    }
    if (!nullToAbsent || serverStatus != null) {
      map['server_status'] = Variable<String>(serverStatus);
    }
    if (!nullToAbsent || reviewNote != null) {
      map['review_note'] = Variable<String>(reviewNote);
    }
    if (!nullToAbsent || conflictsJson != null) {
      map['conflicts_json'] = Variable<String>(conflictsJson);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['area_sqm'] = Variable<double>(areaSqm);
    map['perimeter_m'] = Variable<double>(perimeterM);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SurveysCompanion toCompanion(bool nullToAbsent) {
    return SurveysCompanion(
      id: Value(id),
      ownerUserId: ownerUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerUserId),
      titleDeedNo: Value(titleDeedNo),
      ownerName: Value(ownerName),
      syncState: Value(syncState),
      serverParcelId: serverParcelId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverParcelId),
      serverStatus: serverStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(serverStatus),
      reviewNote: reviewNote == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewNote),
      conflictsJson: conflictsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(conflictsJson),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      areaSqm: Value(areaSqm),
      perimeterM: Value(perimeterM),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Survey.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Survey(
      id: serializer.fromJson<String>(json['id']),
      ownerUserId: serializer.fromJson<String?>(json['ownerUserId']),
      titleDeedNo: serializer.fromJson<String>(json['titleDeedNo']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
      syncState: $SurveysTable.$convertersyncState.fromJson(
        serializer.fromJson<String>(json['syncState']),
      ),
      serverParcelId: serializer.fromJson<String?>(json['serverParcelId']),
      serverStatus: serializer.fromJson<String?>(json['serverStatus']),
      reviewNote: serializer.fromJson<String?>(json['reviewNote']),
      conflictsJson: serializer.fromJson<String?>(json['conflictsJson']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      areaSqm: serializer.fromJson<double>(json['areaSqm']),
      perimeterM: serializer.fromJson<double>(json['perimeterM']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ownerUserId': serializer.toJson<String?>(ownerUserId),
      'titleDeedNo': serializer.toJson<String>(titleDeedNo),
      'ownerName': serializer.toJson<String>(ownerName),
      'syncState': serializer.toJson<String>(
        $SurveysTable.$convertersyncState.toJson(syncState),
      ),
      'serverParcelId': serializer.toJson<String?>(serverParcelId),
      'serverStatus': serializer.toJson<String?>(serverStatus),
      'reviewNote': serializer.toJson<String?>(reviewNote),
      'conflictsJson': serializer.toJson<String?>(conflictsJson),
      'lastError': serializer.toJson<String?>(lastError),
      'areaSqm': serializer.toJson<double>(areaSqm),
      'perimeterM': serializer.toJson<double>(perimeterM),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Survey copyWith({
    String? id,
    Value<String?> ownerUserId = const Value.absent(),
    String? titleDeedNo,
    String? ownerName,
    SyncState? syncState,
    Value<String?> serverParcelId = const Value.absent(),
    Value<String?> serverStatus = const Value.absent(),
    Value<String?> reviewNote = const Value.absent(),
    Value<String?> conflictsJson = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    double? areaSqm,
    double? perimeterM,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Survey(
    id: id ?? this.id,
    ownerUserId: ownerUserId.present ? ownerUserId.value : this.ownerUserId,
    titleDeedNo: titleDeedNo ?? this.titleDeedNo,
    ownerName: ownerName ?? this.ownerName,
    syncState: syncState ?? this.syncState,
    serverParcelId: serverParcelId.present
        ? serverParcelId.value
        : this.serverParcelId,
    serverStatus: serverStatus.present ? serverStatus.value : this.serverStatus,
    reviewNote: reviewNote.present ? reviewNote.value : this.reviewNote,
    conflictsJson: conflictsJson.present
        ? conflictsJson.value
        : this.conflictsJson,
    lastError: lastError.present ? lastError.value : this.lastError,
    areaSqm: areaSqm ?? this.areaSqm,
    perimeterM: perimeterM ?? this.perimeterM,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Survey copyWithCompanion(SurveysCompanion data) {
    return Survey(
      id: data.id.present ? data.id.value : this.id,
      ownerUserId: data.ownerUserId.present
          ? data.ownerUserId.value
          : this.ownerUserId,
      titleDeedNo: data.titleDeedNo.present
          ? data.titleDeedNo.value
          : this.titleDeedNo,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      serverParcelId: data.serverParcelId.present
          ? data.serverParcelId.value
          : this.serverParcelId,
      serverStatus: data.serverStatus.present
          ? data.serverStatus.value
          : this.serverStatus,
      reviewNote: data.reviewNote.present
          ? data.reviewNote.value
          : this.reviewNote,
      conflictsJson: data.conflictsJson.present
          ? data.conflictsJson.value
          : this.conflictsJson,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      areaSqm: data.areaSqm.present ? data.areaSqm.value : this.areaSqm,
      perimeterM: data.perimeterM.present
          ? data.perimeterM.value
          : this.perimeterM,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Survey(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('titleDeedNo: $titleDeedNo, ')
          ..write('ownerName: $ownerName, ')
          ..write('syncState: $syncState, ')
          ..write('serverParcelId: $serverParcelId, ')
          ..write('serverStatus: $serverStatus, ')
          ..write('reviewNote: $reviewNote, ')
          ..write('conflictsJson: $conflictsJson, ')
          ..write('lastError: $lastError, ')
          ..write('areaSqm: $areaSqm, ')
          ..write('perimeterM: $perimeterM, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ownerUserId,
    titleDeedNo,
    ownerName,
    syncState,
    serverParcelId,
    serverStatus,
    reviewNote,
    conflictsJson,
    lastError,
    areaSqm,
    perimeterM,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Survey &&
          other.id == this.id &&
          other.ownerUserId == this.ownerUserId &&
          other.titleDeedNo == this.titleDeedNo &&
          other.ownerName == this.ownerName &&
          other.syncState == this.syncState &&
          other.serverParcelId == this.serverParcelId &&
          other.serverStatus == this.serverStatus &&
          other.reviewNote == this.reviewNote &&
          other.conflictsJson == this.conflictsJson &&
          other.lastError == this.lastError &&
          other.areaSqm == this.areaSqm &&
          other.perimeterM == this.perimeterM &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SurveysCompanion extends UpdateCompanion<Survey> {
  final Value<String> id;
  final Value<String?> ownerUserId;
  final Value<String> titleDeedNo;
  final Value<String> ownerName;
  final Value<SyncState> syncState;
  final Value<String?> serverParcelId;
  final Value<String?> serverStatus;
  final Value<String?> reviewNote;
  final Value<String?> conflictsJson;
  final Value<String?> lastError;
  final Value<double> areaSqm;
  final Value<double> perimeterM;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SurveysCompanion({
    this.id = const Value.absent(),
    this.ownerUserId = const Value.absent(),
    this.titleDeedNo = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.syncState = const Value.absent(),
    this.serverParcelId = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.reviewNote = const Value.absent(),
    this.conflictsJson = const Value.absent(),
    this.lastError = const Value.absent(),
    this.areaSqm = const Value.absent(),
    this.perimeterM = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveysCompanion.insert({
    required String id,
    this.ownerUserId = const Value.absent(),
    required String titleDeedNo,
    required String ownerName,
    required SyncState syncState,
    this.serverParcelId = const Value.absent(),
    this.serverStatus = const Value.absent(),
    this.reviewNote = const Value.absent(),
    this.conflictsJson = const Value.absent(),
    this.lastError = const Value.absent(),
    this.areaSqm = const Value.absent(),
    this.perimeterM = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       titleDeedNo = Value(titleDeedNo),
       ownerName = Value(ownerName),
       syncState = Value(syncState),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Survey> custom({
    Expression<String>? id,
    Expression<String>? ownerUserId,
    Expression<String>? titleDeedNo,
    Expression<String>? ownerName,
    Expression<String>? syncState,
    Expression<String>? serverParcelId,
    Expression<String>? serverStatus,
    Expression<String>? reviewNote,
    Expression<String>? conflictsJson,
    Expression<String>? lastError,
    Expression<double>? areaSqm,
    Expression<double>? perimeterM,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ownerUserId != null) 'owner_user_id': ownerUserId,
      if (titleDeedNo != null) 'title_deed_no': titleDeedNo,
      if (ownerName != null) 'owner_name': ownerName,
      if (syncState != null) 'sync_state': syncState,
      if (serverParcelId != null) 'server_parcel_id': serverParcelId,
      if (serverStatus != null) 'server_status': serverStatus,
      if (reviewNote != null) 'review_note': reviewNote,
      if (conflictsJson != null) 'conflicts_json': conflictsJson,
      if (lastError != null) 'last_error': lastError,
      if (areaSqm != null) 'area_sqm': areaSqm,
      if (perimeterM != null) 'perimeter_m': perimeterM,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveysCompanion copyWith({
    Value<String>? id,
    Value<String?>? ownerUserId,
    Value<String>? titleDeedNo,
    Value<String>? ownerName,
    Value<SyncState>? syncState,
    Value<String?>? serverParcelId,
    Value<String?>? serverStatus,
    Value<String?>? reviewNote,
    Value<String?>? conflictsJson,
    Value<String?>? lastError,
    Value<double>? areaSqm,
    Value<double>? perimeterM,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SurveysCompanion(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      titleDeedNo: titleDeedNo ?? this.titleDeedNo,
      ownerName: ownerName ?? this.ownerName,
      syncState: syncState ?? this.syncState,
      serverParcelId: serverParcelId ?? this.serverParcelId,
      serverStatus: serverStatus ?? this.serverStatus,
      reviewNote: reviewNote ?? this.reviewNote,
      conflictsJson: conflictsJson ?? this.conflictsJson,
      lastError: lastError ?? this.lastError,
      areaSqm: areaSqm ?? this.areaSqm,
      perimeterM: perimeterM ?? this.perimeterM,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ownerUserId.present) {
      map['owner_user_id'] = Variable<String>(ownerUserId.value);
    }
    if (titleDeedNo.present) {
      map['title_deed_no'] = Variable<String>(titleDeedNo.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $SurveysTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (serverParcelId.present) {
      map['server_parcel_id'] = Variable<String>(serverParcelId.value);
    }
    if (serverStatus.present) {
      map['server_status'] = Variable<String>(serverStatus.value);
    }
    if (reviewNote.present) {
      map['review_note'] = Variable<String>(reviewNote.value);
    }
    if (conflictsJson.present) {
      map['conflicts_json'] = Variable<String>(conflictsJson.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (areaSqm.present) {
      map['area_sqm'] = Variable<double>(areaSqm.value);
    }
    if (perimeterM.present) {
      map['perimeter_m'] = Variable<double>(perimeterM.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveysCompanion(')
          ..write('id: $id, ')
          ..write('ownerUserId: $ownerUserId, ')
          ..write('titleDeedNo: $titleDeedNo, ')
          ..write('ownerName: $ownerName, ')
          ..write('syncState: $syncState, ')
          ..write('serverParcelId: $serverParcelId, ')
          ..write('serverStatus: $serverStatus, ')
          ..write('reviewNote: $reviewNote, ')
          ..write('conflictsJson: $conflictsJson, ')
          ..write('lastError: $lastError, ')
          ..write('areaSqm: $areaSqm, ')
          ..write('perimeterM: $perimeterM, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodesTable extends Nodes with TableInfo<$NodesTable, Node> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _surveyIdMeta = const VerificationMeta(
    'surveyId',
  );
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
    'survey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES surveys (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
    'lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMMeta = const VerificationMeta(
    'accuracyM',
  );
  @override
  late final GeneratedColumn<double> accuracyM = GeneratedColumn<double>(
    'accuracy_m',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    surveyId,
    seq,
    lat,
    lon,
    accuracyM,
    capturedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Node> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('survey_id')) {
      context.handle(
        _surveyIdMeta,
        surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
        _lonMeta,
        lon.isAcceptableOrUnknown(data['lon']!, _lonMeta),
      );
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('accuracy_m')) {
      context.handle(
        _accuracyMMeta,
        accuracyM.isAcceptableOrUnknown(data['accuracy_m']!, _accuracyMMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {surveyId, seq},
  ];
  @override
  Node map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Node(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      surveyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}survey_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lon'],
      )!,
      accuracyM: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy_m'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class Node extends DataClass implements Insertable<Node> {
  final int id;
  final String surveyId;
  final int seq;
  final double lat;
  final double lon;
  final double accuracyM;
  final DateTime capturedAt;
  const Node({
    required this.id,
    required this.surveyId,
    required this.seq,
    required this.lat,
    required this.lon,
    required this.accuracyM,
    required this.capturedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['seq'] = Variable<int>(seq);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['accuracy_m'] = Variable<double>(accuracyM);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      seq: Value(seq),
      lat: Value(lat),
      lon: Value(lon),
      accuracyM: Value(accuracyM),
      capturedAt: Value(capturedAt),
    );
  }

  factory Node.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Node(
      id: serializer.fromJson<int>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      seq: serializer.fromJson<int>(json['seq']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      accuracyM: serializer.fromJson<double>(json['accuracyM']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'seq': serializer.toJson<int>(seq),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'accuracyM': serializer.toJson<double>(accuracyM),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
    };
  }

  Node copyWith({
    int? id,
    String? surveyId,
    int? seq,
    double? lat,
    double? lon,
    double? accuracyM,
    DateTime? capturedAt,
  }) => Node(
    id: id ?? this.id,
    surveyId: surveyId ?? this.surveyId,
    seq: seq ?? this.seq,
    lat: lat ?? this.lat,
    lon: lon ?? this.lon,
    accuracyM: accuracyM ?? this.accuracyM,
    capturedAt: capturedAt ?? this.capturedAt,
  );
  Node copyWithCompanion(NodesCompanion data) {
    return Node(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      seq: data.seq.present ? data.seq.value : this.seq,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      accuracyM: data.accuracyM.present ? data.accuracyM.value : this.accuracyM,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('seq: $seq, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, surveyId, seq, lat, lon, accuracyM, capturedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.seq == this.seq &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.accuracyM == this.accuracyM &&
          other.capturedAt == this.capturedAt);
}

class NodesCompanion extends UpdateCompanion<Node> {
  final Value<int> id;
  final Value<String> surveyId;
  final Value<int> seq;
  final Value<double> lat;
  final Value<double> lon;
  final Value<double> accuracyM;
  final Value<DateTime> capturedAt;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.seq = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.accuracyM = const Value.absent(),
    this.capturedAt = const Value.absent(),
  });
  NodesCompanion.insert({
    this.id = const Value.absent(),
    required String surveyId,
    required int seq,
    required double lat,
    required double lon,
    required double accuracyM,
    required DateTime capturedAt,
  }) : surveyId = Value(surveyId),
       seq = Value(seq),
       lat = Value(lat),
       lon = Value(lon),
       accuracyM = Value(accuracyM),
       capturedAt = Value(capturedAt);
  static Insertable<Node> custom({
    Expression<int>? id,
    Expression<String>? surveyId,
    Expression<int>? seq,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<double>? accuracyM,
    Expression<DateTime>? capturedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (seq != null) 'seq': seq,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (accuracyM != null) 'accuracy_m': accuracyM,
      if (capturedAt != null) 'captured_at': capturedAt,
    });
  }

  NodesCompanion copyWith({
    Value<int>? id,
    Value<String>? surveyId,
    Value<int>? seq,
    Value<double>? lat,
    Value<double>? lon,
    Value<double>? accuracyM,
    Value<DateTime>? capturedAt,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      seq: seq ?? this.seq,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      accuracyM: accuracyM ?? this.accuracyM,
      capturedAt: capturedAt ?? this.capturedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (accuracyM.present) {
      map['accuracy_m'] = Variable<double>(accuracyM.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('seq: $seq, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('accuracyM: $accuracyM, ')
          ..write('capturedAt: $capturedAt')
          ..write(')'))
        .toString();
  }
}

class $RegisteredParcelsTable extends RegisteredParcels
    with TableInfo<$RegisteredParcelsTable, RegisteredParcel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegisteredParcelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleDeedNoMeta = const VerificationMeta(
    'titleDeedNo',
  );
  @override
  late final GeneratedColumn<String> titleDeedNo = GeneratedColumn<String>(
    'title_deed_no',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerNameMeta = const VerificationMeta(
    'ownerName',
  );
  @override
  late final GeneratedColumn<String> ownerName = GeneratedColumn<String>(
    'owner_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ringJsonMeta = const VerificationMeta(
    'ringJson',
  );
  @override
  late final GeneratedColumn<String> ringJson = GeneratedColumn<String>(
    'ring_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _southMeta = const VerificationMeta('south');
  @override
  late final GeneratedColumn<double> south = GeneratedColumn<double>(
    'south',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _westMeta = const VerificationMeta('west');
  @override
  late final GeneratedColumn<double> west = GeneratedColumn<double>(
    'west',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _northMeta = const VerificationMeta('north');
  @override
  late final GeneratedColumn<double> north = GeneratedColumn<double>(
    'north',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eastMeta = const VerificationMeta('east');
  @override
  late final GeneratedColumn<double> east = GeneratedColumn<double>(
    'east',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    titleDeedNo,
    ownerName,
    status,
    ringJson,
    south,
    west,
    north,
    east,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'registered_parcels';
  @override
  VerificationContext validateIntegrity(
    Insertable<RegisteredParcel> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title_deed_no')) {
      context.handle(
        _titleDeedNoMeta,
        titleDeedNo.isAcceptableOrUnknown(
          data['title_deed_no']!,
          _titleDeedNoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_titleDeedNoMeta);
    }
    if (data.containsKey('owner_name')) {
      context.handle(
        _ownerNameMeta,
        ownerName.isAcceptableOrUnknown(data['owner_name']!, _ownerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerNameMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('ring_json')) {
      context.handle(
        _ringJsonMeta,
        ringJson.isAcceptableOrUnknown(data['ring_json']!, _ringJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_ringJsonMeta);
    }
    if (data.containsKey('south')) {
      context.handle(
        _southMeta,
        south.isAcceptableOrUnknown(data['south']!, _southMeta),
      );
    } else if (isInserting) {
      context.missing(_southMeta);
    }
    if (data.containsKey('west')) {
      context.handle(
        _westMeta,
        west.isAcceptableOrUnknown(data['west']!, _westMeta),
      );
    } else if (isInserting) {
      context.missing(_westMeta);
    }
    if (data.containsKey('north')) {
      context.handle(
        _northMeta,
        north.isAcceptableOrUnknown(data['north']!, _northMeta),
      );
    } else if (isInserting) {
      context.missing(_northMeta);
    }
    if (data.containsKey('east')) {
      context.handle(
        _eastMeta,
        east.isAcceptableOrUnknown(data['east']!, _eastMeta),
      );
    } else if (isInserting) {
      context.missing(_eastMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RegisteredParcel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RegisteredParcel(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      titleDeedNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title_deed_no'],
      )!,
      ownerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_name'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      ringJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ring_json'],
      )!,
      south: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}south'],
      )!,
      west: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}west'],
      )!,
      north: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}north'],
      )!,
      east: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}east'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $RegisteredParcelsTable createAlias(String alias) {
    return $RegisteredParcelsTable(attachedDatabase, alias);
  }
}

class RegisteredParcel extends DataClass
    implements Insertable<RegisteredParcel> {
  final String id;
  final String titleDeedNo;
  final String ownerName;

  /// APPROVED or PENDING.
  final String status;

  /// Outer ring as a JSON array of [lon, lat] pairs.
  final String ringJson;
  final double south;
  final double west;
  final double north;
  final double east;
  final DateTime fetchedAt;
  const RegisteredParcel({
    required this.id,
    required this.titleDeedNo,
    required this.ownerName,
    required this.status,
    required this.ringJson,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title_deed_no'] = Variable<String>(titleDeedNo);
    map['owner_name'] = Variable<String>(ownerName);
    map['status'] = Variable<String>(status);
    map['ring_json'] = Variable<String>(ringJson);
    map['south'] = Variable<double>(south);
    map['west'] = Variable<double>(west);
    map['north'] = Variable<double>(north);
    map['east'] = Variable<double>(east);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  RegisteredParcelsCompanion toCompanion(bool nullToAbsent) {
    return RegisteredParcelsCompanion(
      id: Value(id),
      titleDeedNo: Value(titleDeedNo),
      ownerName: Value(ownerName),
      status: Value(status),
      ringJson: Value(ringJson),
      south: Value(south),
      west: Value(west),
      north: Value(north),
      east: Value(east),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory RegisteredParcel.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RegisteredParcel(
      id: serializer.fromJson<String>(json['id']),
      titleDeedNo: serializer.fromJson<String>(json['titleDeedNo']),
      ownerName: serializer.fromJson<String>(json['ownerName']),
      status: serializer.fromJson<String>(json['status']),
      ringJson: serializer.fromJson<String>(json['ringJson']),
      south: serializer.fromJson<double>(json['south']),
      west: serializer.fromJson<double>(json['west']),
      north: serializer.fromJson<double>(json['north']),
      east: serializer.fromJson<double>(json['east']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'titleDeedNo': serializer.toJson<String>(titleDeedNo),
      'ownerName': serializer.toJson<String>(ownerName),
      'status': serializer.toJson<String>(status),
      'ringJson': serializer.toJson<String>(ringJson),
      'south': serializer.toJson<double>(south),
      'west': serializer.toJson<double>(west),
      'north': serializer.toJson<double>(north),
      'east': serializer.toJson<double>(east),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  RegisteredParcel copyWith({
    String? id,
    String? titleDeedNo,
    String? ownerName,
    String? status,
    String? ringJson,
    double? south,
    double? west,
    double? north,
    double? east,
    DateTime? fetchedAt,
  }) => RegisteredParcel(
    id: id ?? this.id,
    titleDeedNo: titleDeedNo ?? this.titleDeedNo,
    ownerName: ownerName ?? this.ownerName,
    status: status ?? this.status,
    ringJson: ringJson ?? this.ringJson,
    south: south ?? this.south,
    west: west ?? this.west,
    north: north ?? this.north,
    east: east ?? this.east,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  RegisteredParcel copyWithCompanion(RegisteredParcelsCompanion data) {
    return RegisteredParcel(
      id: data.id.present ? data.id.value : this.id,
      titleDeedNo: data.titleDeedNo.present
          ? data.titleDeedNo.value
          : this.titleDeedNo,
      ownerName: data.ownerName.present ? data.ownerName.value : this.ownerName,
      status: data.status.present ? data.status.value : this.status,
      ringJson: data.ringJson.present ? data.ringJson.value : this.ringJson,
      south: data.south.present ? data.south.value : this.south,
      west: data.west.present ? data.west.value : this.west,
      north: data.north.present ? data.north.value : this.north,
      east: data.east.present ? data.east.value : this.east,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RegisteredParcel(')
          ..write('id: $id, ')
          ..write('titleDeedNo: $titleDeedNo, ')
          ..write('ownerName: $ownerName, ')
          ..write('status: $status, ')
          ..write('ringJson: $ringJson, ')
          ..write('south: $south, ')
          ..write('west: $west, ')
          ..write('north: $north, ')
          ..write('east: $east, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    titleDeedNo,
    ownerName,
    status,
    ringJson,
    south,
    west,
    north,
    east,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RegisteredParcel &&
          other.id == this.id &&
          other.titleDeedNo == this.titleDeedNo &&
          other.ownerName == this.ownerName &&
          other.status == this.status &&
          other.ringJson == this.ringJson &&
          other.south == this.south &&
          other.west == this.west &&
          other.north == this.north &&
          other.east == this.east &&
          other.fetchedAt == this.fetchedAt);
}

class RegisteredParcelsCompanion extends UpdateCompanion<RegisteredParcel> {
  final Value<String> id;
  final Value<String> titleDeedNo;
  final Value<String> ownerName;
  final Value<String> status;
  final Value<String> ringJson;
  final Value<double> south;
  final Value<double> west;
  final Value<double> north;
  final Value<double> east;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const RegisteredParcelsCompanion({
    this.id = const Value.absent(),
    this.titleDeedNo = const Value.absent(),
    this.ownerName = const Value.absent(),
    this.status = const Value.absent(),
    this.ringJson = const Value.absent(),
    this.south = const Value.absent(),
    this.west = const Value.absent(),
    this.north = const Value.absent(),
    this.east = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegisteredParcelsCompanion.insert({
    required String id,
    required String titleDeedNo,
    required String ownerName,
    required String status,
    required String ringJson,
    required double south,
    required double west,
    required double north,
    required double east,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       titleDeedNo = Value(titleDeedNo),
       ownerName = Value(ownerName),
       status = Value(status),
       ringJson = Value(ringJson),
       south = Value(south),
       west = Value(west),
       north = Value(north),
       east = Value(east),
       fetchedAt = Value(fetchedAt);
  static Insertable<RegisteredParcel> custom({
    Expression<String>? id,
    Expression<String>? titleDeedNo,
    Expression<String>? ownerName,
    Expression<String>? status,
    Expression<String>? ringJson,
    Expression<double>? south,
    Expression<double>? west,
    Expression<double>? north,
    Expression<double>? east,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (titleDeedNo != null) 'title_deed_no': titleDeedNo,
      if (ownerName != null) 'owner_name': ownerName,
      if (status != null) 'status': status,
      if (ringJson != null) 'ring_json': ringJson,
      if (south != null) 'south': south,
      if (west != null) 'west': west,
      if (north != null) 'north': north,
      if (east != null) 'east': east,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegisteredParcelsCompanion copyWith({
    Value<String>? id,
    Value<String>? titleDeedNo,
    Value<String>? ownerName,
    Value<String>? status,
    Value<String>? ringJson,
    Value<double>? south,
    Value<double>? west,
    Value<double>? north,
    Value<double>? east,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return RegisteredParcelsCompanion(
      id: id ?? this.id,
      titleDeedNo: titleDeedNo ?? this.titleDeedNo,
      ownerName: ownerName ?? this.ownerName,
      status: status ?? this.status,
      ringJson: ringJson ?? this.ringJson,
      south: south ?? this.south,
      west: west ?? this.west,
      north: north ?? this.north,
      east: east ?? this.east,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (titleDeedNo.present) {
      map['title_deed_no'] = Variable<String>(titleDeedNo.value);
    }
    if (ownerName.present) {
      map['owner_name'] = Variable<String>(ownerName.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (ringJson.present) {
      map['ring_json'] = Variable<String>(ringJson.value);
    }
    if (south.present) {
      map['south'] = Variable<double>(south.value);
    }
    if (west.present) {
      map['west'] = Variable<double>(west.value);
    }
    if (north.present) {
      map['north'] = Variable<double>(north.value);
    }
    if (east.present) {
      map['east'] = Variable<double>(east.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegisteredParcelsCompanion(')
          ..write('id: $id, ')
          ..write('titleDeedNo: $titleDeedNo, ')
          ..write('ownerName: $ownerName, ')
          ..write('status: $status, ')
          ..write('ringJson: $ringJson, ')
          ..write('south: $south, ')
          ..write('west: $west, ')
          ..write('north: $north, ')
          ..write('east: $east, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OfflineAreasTable extends OfflineAreas
    with TableInfo<$OfflineAreasTable, OfflineArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OfflineAreasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _southMeta = const VerificationMeta('south');
  @override
  late final GeneratedColumn<double> south = GeneratedColumn<double>(
    'south',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _westMeta = const VerificationMeta('west');
  @override
  late final GeneratedColumn<double> west = GeneratedColumn<double>(
    'west',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _northMeta = const VerificationMeta('north');
  @override
  late final GeneratedColumn<double> north = GeneratedColumn<double>(
    'north',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eastMeta = const VerificationMeta('east');
  @override
  late final GeneratedColumn<double> east = GeneratedColumn<double>(
    'east',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minZoomMeta = const VerificationMeta(
    'minZoom',
  );
  @override
  late final GeneratedColumn<int> minZoom = GeneratedColumn<int>(
    'min_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxZoomMeta = const VerificationMeta(
    'maxZoom',
  );
  @override
  late final GeneratedColumn<int> maxZoom = GeneratedColumn<int>(
    'max_zoom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tileSourceMeta = const VerificationMeta(
    'tileSource',
  );
  @override
  late final GeneratedColumn<String> tileSource = GeneratedColumn<String>(
    'tile_source',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tileCountMeta = const VerificationMeta(
    'tileCount',
  );
  @override
  late final GeneratedColumn<int> tileCount = GeneratedColumn<int>(
    'tile_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bytesMeta = const VerificationMeta('bytes');
  @override
  late final GeneratedColumn<int> bytes = GeneratedColumn<int>(
    'bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _parcelCountMeta = const VerificationMeta(
    'parcelCount',
  );
  @override
  late final GeneratedColumn<int> parcelCount = GeneratedColumn<int>(
    'parcel_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    south,
    west,
    north,
    east,
    minZoom,
    maxZoom,
    tileSource,
    tileCount,
    bytes,
    parcelCount,
    complete,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'offline_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<OfflineArea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('south')) {
      context.handle(
        _southMeta,
        south.isAcceptableOrUnknown(data['south']!, _southMeta),
      );
    } else if (isInserting) {
      context.missing(_southMeta);
    }
    if (data.containsKey('west')) {
      context.handle(
        _westMeta,
        west.isAcceptableOrUnknown(data['west']!, _westMeta),
      );
    } else if (isInserting) {
      context.missing(_westMeta);
    }
    if (data.containsKey('north')) {
      context.handle(
        _northMeta,
        north.isAcceptableOrUnknown(data['north']!, _northMeta),
      );
    } else if (isInserting) {
      context.missing(_northMeta);
    }
    if (data.containsKey('east')) {
      context.handle(
        _eastMeta,
        east.isAcceptableOrUnknown(data['east']!, _eastMeta),
      );
    } else if (isInserting) {
      context.missing(_eastMeta);
    }
    if (data.containsKey('min_zoom')) {
      context.handle(
        _minZoomMeta,
        minZoom.isAcceptableOrUnknown(data['min_zoom']!, _minZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_minZoomMeta);
    }
    if (data.containsKey('max_zoom')) {
      context.handle(
        _maxZoomMeta,
        maxZoom.isAcceptableOrUnknown(data['max_zoom']!, _maxZoomMeta),
      );
    } else if (isInserting) {
      context.missing(_maxZoomMeta);
    }
    if (data.containsKey('tile_source')) {
      context.handle(
        _tileSourceMeta,
        tileSource.isAcceptableOrUnknown(data['tile_source']!, _tileSourceMeta),
      );
    }
    if (data.containsKey('tile_count')) {
      context.handle(
        _tileCountMeta,
        tileCount.isAcceptableOrUnknown(data['tile_count']!, _tileCountMeta),
      );
    }
    if (data.containsKey('bytes')) {
      context.handle(
        _bytesMeta,
        bytes.isAcceptableOrUnknown(data['bytes']!, _bytesMeta),
      );
    }
    if (data.containsKey('parcel_count')) {
      context.handle(
        _parcelCountMeta,
        parcelCount.isAcceptableOrUnknown(
          data['parcel_count']!,
          _parcelCountMeta,
        ),
      );
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OfflineArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OfflineArea(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      south: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}south'],
      )!,
      west: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}west'],
      )!,
      north: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}north'],
      )!,
      east: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}east'],
      )!,
      minZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_zoom'],
      )!,
      maxZoom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_zoom'],
      )!,
      tileSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tile_source'],
      ),
      tileCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tile_count'],
      )!,
      bytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes'],
      )!,
      parcelCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parcel_count'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $OfflineAreasTable createAlias(String alias) {
    return $OfflineAreasTable(attachedDatabase, alias);
  }
}

class OfflineArea extends DataClass implements Insertable<OfflineArea> {
  final int id;
  final String name;
  final double south;
  final double west;
  final double north;
  final double east;
  final int minZoom;
  final int maxZoom;

  /// Basemap URL template the tiles came from; null when only parcels were saved.
  final String? tileSource;
  final int tileCount;
  final int bytes;
  final int parcelCount;

  /// False while downloading, or if it was cancelled or partly failed.
  final bool complete;
  final DateTime updatedAt;
  const OfflineArea({
    required this.id,
    required this.name,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.minZoom,
    required this.maxZoom,
    this.tileSource,
    required this.tileCount,
    required this.bytes,
    required this.parcelCount,
    required this.complete,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['south'] = Variable<double>(south);
    map['west'] = Variable<double>(west);
    map['north'] = Variable<double>(north);
    map['east'] = Variable<double>(east);
    map['min_zoom'] = Variable<int>(minZoom);
    map['max_zoom'] = Variable<int>(maxZoom);
    if (!nullToAbsent || tileSource != null) {
      map['tile_source'] = Variable<String>(tileSource);
    }
    map['tile_count'] = Variable<int>(tileCount);
    map['bytes'] = Variable<int>(bytes);
    map['parcel_count'] = Variable<int>(parcelCount);
    map['complete'] = Variable<bool>(complete);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  OfflineAreasCompanion toCompanion(bool nullToAbsent) {
    return OfflineAreasCompanion(
      id: Value(id),
      name: Value(name),
      south: Value(south),
      west: Value(west),
      north: Value(north),
      east: Value(east),
      minZoom: Value(minZoom),
      maxZoom: Value(maxZoom),
      tileSource: tileSource == null && nullToAbsent
          ? const Value.absent()
          : Value(tileSource),
      tileCount: Value(tileCount),
      bytes: Value(bytes),
      parcelCount: Value(parcelCount),
      complete: Value(complete),
      updatedAt: Value(updatedAt),
    );
  }

  factory OfflineArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OfflineArea(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      south: serializer.fromJson<double>(json['south']),
      west: serializer.fromJson<double>(json['west']),
      north: serializer.fromJson<double>(json['north']),
      east: serializer.fromJson<double>(json['east']),
      minZoom: serializer.fromJson<int>(json['minZoom']),
      maxZoom: serializer.fromJson<int>(json['maxZoom']),
      tileSource: serializer.fromJson<String?>(json['tileSource']),
      tileCount: serializer.fromJson<int>(json['tileCount']),
      bytes: serializer.fromJson<int>(json['bytes']),
      parcelCount: serializer.fromJson<int>(json['parcelCount']),
      complete: serializer.fromJson<bool>(json['complete']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'south': serializer.toJson<double>(south),
      'west': serializer.toJson<double>(west),
      'north': serializer.toJson<double>(north),
      'east': serializer.toJson<double>(east),
      'minZoom': serializer.toJson<int>(minZoom),
      'maxZoom': serializer.toJson<int>(maxZoom),
      'tileSource': serializer.toJson<String?>(tileSource),
      'tileCount': serializer.toJson<int>(tileCount),
      'bytes': serializer.toJson<int>(bytes),
      'parcelCount': serializer.toJson<int>(parcelCount),
      'complete': serializer.toJson<bool>(complete),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  OfflineArea copyWith({
    int? id,
    String? name,
    double? south,
    double? west,
    double? north,
    double? east,
    int? minZoom,
    int? maxZoom,
    Value<String?> tileSource = const Value.absent(),
    int? tileCount,
    int? bytes,
    int? parcelCount,
    bool? complete,
    DateTime? updatedAt,
  }) => OfflineArea(
    id: id ?? this.id,
    name: name ?? this.name,
    south: south ?? this.south,
    west: west ?? this.west,
    north: north ?? this.north,
    east: east ?? this.east,
    minZoom: minZoom ?? this.minZoom,
    maxZoom: maxZoom ?? this.maxZoom,
    tileSource: tileSource.present ? tileSource.value : this.tileSource,
    tileCount: tileCount ?? this.tileCount,
    bytes: bytes ?? this.bytes,
    parcelCount: parcelCount ?? this.parcelCount,
    complete: complete ?? this.complete,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  OfflineArea copyWithCompanion(OfflineAreasCompanion data) {
    return OfflineArea(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      south: data.south.present ? data.south.value : this.south,
      west: data.west.present ? data.west.value : this.west,
      north: data.north.present ? data.north.value : this.north,
      east: data.east.present ? data.east.value : this.east,
      minZoom: data.minZoom.present ? data.minZoom.value : this.minZoom,
      maxZoom: data.maxZoom.present ? data.maxZoom.value : this.maxZoom,
      tileSource: data.tileSource.present
          ? data.tileSource.value
          : this.tileSource,
      tileCount: data.tileCount.present ? data.tileCount.value : this.tileCount,
      bytes: data.bytes.present ? data.bytes.value : this.bytes,
      parcelCount: data.parcelCount.present
          ? data.parcelCount.value
          : this.parcelCount,
      complete: data.complete.present ? data.complete.value : this.complete,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OfflineArea(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('south: $south, ')
          ..write('west: $west, ')
          ..write('north: $north, ')
          ..write('east: $east, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('tileSource: $tileSource, ')
          ..write('tileCount: $tileCount, ')
          ..write('bytes: $bytes, ')
          ..write('parcelCount: $parcelCount, ')
          ..write('complete: $complete, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    south,
    west,
    north,
    east,
    minZoom,
    maxZoom,
    tileSource,
    tileCount,
    bytes,
    parcelCount,
    complete,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OfflineArea &&
          other.id == this.id &&
          other.name == this.name &&
          other.south == this.south &&
          other.west == this.west &&
          other.north == this.north &&
          other.east == this.east &&
          other.minZoom == this.minZoom &&
          other.maxZoom == this.maxZoom &&
          other.tileSource == this.tileSource &&
          other.tileCount == this.tileCount &&
          other.bytes == this.bytes &&
          other.parcelCount == this.parcelCount &&
          other.complete == this.complete &&
          other.updatedAt == this.updatedAt);
}

class OfflineAreasCompanion extends UpdateCompanion<OfflineArea> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> south;
  final Value<double> west;
  final Value<double> north;
  final Value<double> east;
  final Value<int> minZoom;
  final Value<int> maxZoom;
  final Value<String?> tileSource;
  final Value<int> tileCount;
  final Value<int> bytes;
  final Value<int> parcelCount;
  final Value<bool> complete;
  final Value<DateTime> updatedAt;
  const OfflineAreasCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.south = const Value.absent(),
    this.west = const Value.absent(),
    this.north = const Value.absent(),
    this.east = const Value.absent(),
    this.minZoom = const Value.absent(),
    this.maxZoom = const Value.absent(),
    this.tileSource = const Value.absent(),
    this.tileCount = const Value.absent(),
    this.bytes = const Value.absent(),
    this.parcelCount = const Value.absent(),
    this.complete = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  OfflineAreasCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double south,
    required double west,
    required double north,
    required double east,
    required int minZoom,
    required int maxZoom,
    this.tileSource = const Value.absent(),
    this.tileCount = const Value.absent(),
    this.bytes = const Value.absent(),
    this.parcelCount = const Value.absent(),
    this.complete = const Value.absent(),
    required DateTime updatedAt,
  }) : name = Value(name),
       south = Value(south),
       west = Value(west),
       north = Value(north),
       east = Value(east),
       minZoom = Value(minZoom),
       maxZoom = Value(maxZoom),
       updatedAt = Value(updatedAt);
  static Insertable<OfflineArea> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? south,
    Expression<double>? west,
    Expression<double>? north,
    Expression<double>? east,
    Expression<int>? minZoom,
    Expression<int>? maxZoom,
    Expression<String>? tileSource,
    Expression<int>? tileCount,
    Expression<int>? bytes,
    Expression<int>? parcelCount,
    Expression<bool>? complete,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (south != null) 'south': south,
      if (west != null) 'west': west,
      if (north != null) 'north': north,
      if (east != null) 'east': east,
      if (minZoom != null) 'min_zoom': minZoom,
      if (maxZoom != null) 'max_zoom': maxZoom,
      if (tileSource != null) 'tile_source': tileSource,
      if (tileCount != null) 'tile_count': tileCount,
      if (bytes != null) 'bytes': bytes,
      if (parcelCount != null) 'parcel_count': parcelCount,
      if (complete != null) 'complete': complete,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  OfflineAreasCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? south,
    Value<double>? west,
    Value<double>? north,
    Value<double>? east,
    Value<int>? minZoom,
    Value<int>? maxZoom,
    Value<String?>? tileSource,
    Value<int>? tileCount,
    Value<int>? bytes,
    Value<int>? parcelCount,
    Value<bool>? complete,
    Value<DateTime>? updatedAt,
  }) {
    return OfflineAreasCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      south: south ?? this.south,
      west: west ?? this.west,
      north: north ?? this.north,
      east: east ?? this.east,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      tileSource: tileSource ?? this.tileSource,
      tileCount: tileCount ?? this.tileCount,
      bytes: bytes ?? this.bytes,
      parcelCount: parcelCount ?? this.parcelCount,
      complete: complete ?? this.complete,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (south.present) {
      map['south'] = Variable<double>(south.value);
    }
    if (west.present) {
      map['west'] = Variable<double>(west.value);
    }
    if (north.present) {
      map['north'] = Variable<double>(north.value);
    }
    if (east.present) {
      map['east'] = Variable<double>(east.value);
    }
    if (minZoom.present) {
      map['min_zoom'] = Variable<int>(minZoom.value);
    }
    if (maxZoom.present) {
      map['max_zoom'] = Variable<int>(maxZoom.value);
    }
    if (tileSource.present) {
      map['tile_source'] = Variable<String>(tileSource.value);
    }
    if (tileCount.present) {
      map['tile_count'] = Variable<int>(tileCount.value);
    }
    if (bytes.present) {
      map['bytes'] = Variable<int>(bytes.value);
    }
    if (parcelCount.present) {
      map['parcel_count'] = Variable<int>(parcelCount.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OfflineAreasCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('south: $south, ')
          ..write('west: $west, ')
          ..write('north: $north, ')
          ..write('east: $east, ')
          ..write('minZoom: $minZoom, ')
          ..write('maxZoom: $maxZoom, ')
          ..write('tileSource: $tileSource, ')
          ..write('tileCount: $tileCount, ')
          ..write('bytes: $bytes, ')
          ..write('parcelCount: $parcelCount, ')
          ..write('complete: $complete, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurveysTable surveys = $SurveysTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $RegisteredParcelsTable registeredParcels =
      $RegisteredParcelsTable(this);
  late final $OfflineAreasTable offlineAreas = $OfflineAreasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surveys,
    nodes,
    registeredParcels,
    offlineAreas,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'surveys',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nodes', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$SurveysTableCreateCompanionBuilder =
    SurveysCompanion Function({
      required String id,
      Value<String?> ownerUserId,
      required String titleDeedNo,
      required String ownerName,
      required SyncState syncState,
      Value<String?> serverParcelId,
      Value<String?> serverStatus,
      Value<String?> reviewNote,
      Value<String?> conflictsJson,
      Value<String?> lastError,
      Value<double> areaSqm,
      Value<double> perimeterM,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SurveysTableUpdateCompanionBuilder =
    SurveysCompanion Function({
      Value<String> id,
      Value<String?> ownerUserId,
      Value<String> titleDeedNo,
      Value<String> ownerName,
      Value<SyncState> syncState,
      Value<String?> serverParcelId,
      Value<String?> serverStatus,
      Value<String?> reviewNote,
      Value<String?> conflictsJson,
      Value<String?> lastError,
      Value<double> areaSqm,
      Value<double> perimeterM,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SurveysTableReferences
    extends BaseReferences<_$AppDatabase, $SurveysTable, Survey> {
  $$SurveysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NodesTable, List<Node>> _nodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.nodes,
    aliasName: 'surveys__id__nodes__survey_id',
  );

  $$NodesTableProcessedTableManager get nodesRefs {
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.surveyId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SurveysTableFilterComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleDeedNo => $composableBuilder(
    column: $table.titleDeedNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get serverParcelId => $composableBuilder(
    column: $table.serverParcelId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewNote => $composableBuilder(
    column: $table.reviewNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conflictsJson => $composableBuilder(
    column: $table.conflictsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get areaSqm => $composableBuilder(
    column: $table.areaSqm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get perimeterM => $composableBuilder(
    column: $table.perimeterM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> nodesRefs(
    Expression<bool> Function($$NodesTableFilterComposer f) f,
  ) {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.surveyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurveysTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleDeedNo => $composableBuilder(
    column: $table.titleDeedNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverParcelId => $composableBuilder(
    column: $table.serverParcelId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewNote => $composableBuilder(
    column: $table.reviewNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conflictsJson => $composableBuilder(
    column: $table.conflictsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get areaSqm => $composableBuilder(
    column: $table.areaSqm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get perimeterM => $composableBuilder(
    column: $table.perimeterM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurveysTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ownerUserId => $composableBuilder(
    column: $table.ownerUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get titleDeedNo => $composableBuilder(
    column: $table.titleDeedNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get serverParcelId => $composableBuilder(
    column: $table.serverParcelId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverStatus => $composableBuilder(
    column: $table.serverStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reviewNote => $composableBuilder(
    column: $table.reviewNote,
    builder: (column) => column,
  );

  GeneratedColumn<String> get conflictsJson => $composableBuilder(
    column: $table.conflictsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<double> get areaSqm =>
      $composableBuilder(column: $table.areaSqm, builder: (column) => column);

  GeneratedColumn<double> get perimeterM => $composableBuilder(
    column: $table.perimeterM,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> nodesRefs<T extends Object>(
    Expression<T> Function($$NodesTableAnnotationComposer a) f,
  ) {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.surveyId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SurveysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurveysTable,
          Survey,
          $$SurveysTableFilterComposer,
          $$SurveysTableOrderingComposer,
          $$SurveysTableAnnotationComposer,
          $$SurveysTableCreateCompanionBuilder,
          $$SurveysTableUpdateCompanionBuilder,
          (Survey, $$SurveysTableReferences),
          Survey,
          PrefetchHooks Function({bool nodesRefs})
        > {
  $$SurveysTableTableManager(_$AppDatabase db, $SurveysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> ownerUserId = const Value.absent(),
                Value<String> titleDeedNo = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<String?> serverParcelId = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<String?> reviewNote = const Value.absent(),
                Value<String?> conflictsJson = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<double> areaSqm = const Value.absent(),
                Value<double> perimeterM = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveysCompanion(
                id: id,
                ownerUserId: ownerUserId,
                titleDeedNo: titleDeedNo,
                ownerName: ownerName,
                syncState: syncState,
                serverParcelId: serverParcelId,
                serverStatus: serverStatus,
                reviewNote: reviewNote,
                conflictsJson: conflictsJson,
                lastError: lastError,
                areaSqm: areaSqm,
                perimeterM: perimeterM,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> ownerUserId = const Value.absent(),
                required String titleDeedNo,
                required String ownerName,
                required SyncState syncState,
                Value<String?> serverParcelId = const Value.absent(),
                Value<String?> serverStatus = const Value.absent(),
                Value<String?> reviewNote = const Value.absent(),
                Value<String?> conflictsJson = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<double> areaSqm = const Value.absent(),
                Value<double> perimeterM = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SurveysCompanion.insert(
                id: id,
                ownerUserId: ownerUserId,
                titleDeedNo: titleDeedNo,
                ownerName: ownerName,
                syncState: syncState,
                serverParcelId: serverParcelId,
                serverStatus: serverStatus,
                reviewNote: reviewNote,
                conflictsJson: conflictsJson,
                lastError: lastError,
                areaSqm: areaSqm,
                perimeterM: perimeterM,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SurveysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (nodesRefs) db.nodes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (nodesRefs)
                    await $_getPrefetchedData<Survey, $SurveysTable, Node>(
                      currentTable: table,
                      referencedTable: $$SurveysTableReferences._nodesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SurveysTableReferences(db, table, p0).nodesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.surveyId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SurveysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurveysTable,
      Survey,
      $$SurveysTableFilterComposer,
      $$SurveysTableOrderingComposer,
      $$SurveysTableAnnotationComposer,
      $$SurveysTableCreateCompanionBuilder,
      $$SurveysTableUpdateCompanionBuilder,
      (Survey, $$SurveysTableReferences),
      Survey,
      PrefetchHooks Function({bool nodesRefs})
    >;
typedef $$NodesTableCreateCompanionBuilder =
    NodesCompanion Function({
      Value<int> id,
      required String surveyId,
      required int seq,
      required double lat,
      required double lon,
      required double accuracyM,
      required DateTime capturedAt,
    });
typedef $$NodesTableUpdateCompanionBuilder =
    NodesCompanion Function({
      Value<int> id,
      Value<String> surveyId,
      Value<int> seq,
      Value<double> lat,
      Value<double> lon,
      Value<double> accuracyM,
      Value<DateTime> capturedAt,
    });

final class $$NodesTableReferences
    extends BaseReferences<_$AppDatabase, $NodesTable, Node> {
  $$NodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SurveysTable _surveyIdTable(_$AppDatabase db) =>
      db.surveys.createAlias('nodes__survey_id__surveys__id');

  $$SurveysTableProcessedTableManager get surveyId {
    final $_column = $_itemColumn<String>('survey_id')!;

    final manager = $$SurveysTableTableManager(
      $_db,
      $_db.surveys,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surveyIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodesTableFilterComposer extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SurveysTableFilterComposer get surveyId {
    final $$SurveysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surveyId,
      referencedTable: $db.surveys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurveysTableFilterComposer(
            $db: $db,
            $table: $db.surveys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lon => $composableBuilder(
    column: $table.lon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracyM => $composableBuilder(
    column: $table.accuracyM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SurveysTableOrderingComposer get surveyId {
    final $$SurveysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surveyId,
      referencedTable: $db.surveys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurveysTableOrderingComposer(
            $db: $db,
            $table: $db.surveys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumn<double> get accuracyM =>
      $composableBuilder(column: $table.accuracyM, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  $$SurveysTableAnnotationComposer get surveyId {
    final $$SurveysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surveyId,
      referencedTable: $db.surveys,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SurveysTableAnnotationComposer(
            $db: $db,
            $table: $db.surveys,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodesTable,
          Node,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (Node, $$NodesTableReferences),
          Node,
          PrefetchHooks Function({bool surveyId})
        > {
  $$NodesTableTableManager(_$AppDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> surveyId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lon = const Value.absent(),
                Value<double> accuracyM = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                surveyId: surveyId,
                seq: seq,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                capturedAt: capturedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String surveyId,
                required int seq,
                required double lat,
                required double lon,
                required double accuracyM,
                required DateTime capturedAt,
              }) => NodesCompanion.insert(
                id: id,
                surveyId: surveyId,
                seq: seq,
                lat: lat,
                lon: lon,
                accuracyM: accuracyM,
                capturedAt: capturedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$NodesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({surveyId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (surveyId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.surveyId,
                                referencedTable: $$NodesTableReferences
                                    ._surveyIdTable(db),
                                referencedColumn: $$NodesTableReferences
                                    ._surveyIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodesTable,
      Node,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (Node, $$NodesTableReferences),
      Node,
      PrefetchHooks Function({bool surveyId})
    >;
typedef $$RegisteredParcelsTableCreateCompanionBuilder =
    RegisteredParcelsCompanion Function({
      required String id,
      required String titleDeedNo,
      required String ownerName,
      required String status,
      required String ringJson,
      required double south,
      required double west,
      required double north,
      required double east,
      required DateTime fetchedAt,
      Value<int> rowid,
    });
typedef $$RegisteredParcelsTableUpdateCompanionBuilder =
    RegisteredParcelsCompanion Function({
      Value<String> id,
      Value<String> titleDeedNo,
      Value<String> ownerName,
      Value<String> status,
      Value<String> ringJson,
      Value<double> south,
      Value<double> west,
      Value<double> north,
      Value<double> east,
      Value<DateTime> fetchedAt,
      Value<int> rowid,
    });

class $$RegisteredParcelsTableFilterComposer
    extends Composer<_$AppDatabase, $RegisteredParcelsTable> {
  $$RegisteredParcelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get titleDeedNo => $composableBuilder(
    column: $table.titleDeedNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ringJson => $composableBuilder(
    column: $table.ringJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get south => $composableBuilder(
    column: $table.south,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get west => $composableBuilder(
    column: $table.west,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get north => $composableBuilder(
    column: $table.north,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get east => $composableBuilder(
    column: $table.east,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RegisteredParcelsTableOrderingComposer
    extends Composer<_$AppDatabase, $RegisteredParcelsTable> {
  $$RegisteredParcelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get titleDeedNo => $composableBuilder(
    column: $table.titleDeedNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerName => $composableBuilder(
    column: $table.ownerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ringJson => $composableBuilder(
    column: $table.ringJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get south => $composableBuilder(
    column: $table.south,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get west => $composableBuilder(
    column: $table.west,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get north => $composableBuilder(
    column: $table.north,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get east => $composableBuilder(
    column: $table.east,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RegisteredParcelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RegisteredParcelsTable> {
  $$RegisteredParcelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get titleDeedNo => $composableBuilder(
    column: $table.titleDeedNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ownerName =>
      $composableBuilder(column: $table.ownerName, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get ringJson =>
      $composableBuilder(column: $table.ringJson, builder: (column) => column);

  GeneratedColumn<double> get south =>
      $composableBuilder(column: $table.south, builder: (column) => column);

  GeneratedColumn<double> get west =>
      $composableBuilder(column: $table.west, builder: (column) => column);

  GeneratedColumn<double> get north =>
      $composableBuilder(column: $table.north, builder: (column) => column);

  GeneratedColumn<double> get east =>
      $composableBuilder(column: $table.east, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$RegisteredParcelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RegisteredParcelsTable,
          RegisteredParcel,
          $$RegisteredParcelsTableFilterComposer,
          $$RegisteredParcelsTableOrderingComposer,
          $$RegisteredParcelsTableAnnotationComposer,
          $$RegisteredParcelsTableCreateCompanionBuilder,
          $$RegisteredParcelsTableUpdateCompanionBuilder,
          (
            RegisteredParcel,
            BaseReferences<
              _$AppDatabase,
              $RegisteredParcelsTable,
              RegisteredParcel
            >,
          ),
          RegisteredParcel,
          PrefetchHooks Function()
        > {
  $$RegisteredParcelsTableTableManager(
    _$AppDatabase db,
    $RegisteredParcelsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegisteredParcelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegisteredParcelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegisteredParcelsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> titleDeedNo = const Value.absent(),
                Value<String> ownerName = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> ringJson = const Value.absent(),
                Value<double> south = const Value.absent(),
                Value<double> west = const Value.absent(),
                Value<double> north = const Value.absent(),
                Value<double> east = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegisteredParcelsCompanion(
                id: id,
                titleDeedNo: titleDeedNo,
                ownerName: ownerName,
                status: status,
                ringJson: ringJson,
                south: south,
                west: west,
                north: north,
                east: east,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String titleDeedNo,
                required String ownerName,
                required String status,
                required String ringJson,
                required double south,
                required double west,
                required double north,
                required double east,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => RegisteredParcelsCompanion.insert(
                id: id,
                titleDeedNo: titleDeedNo,
                ownerName: ownerName,
                status: status,
                ringJson: ringJson,
                south: south,
                west: west,
                north: north,
                east: east,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RegisteredParcelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RegisteredParcelsTable,
      RegisteredParcel,
      $$RegisteredParcelsTableFilterComposer,
      $$RegisteredParcelsTableOrderingComposer,
      $$RegisteredParcelsTableAnnotationComposer,
      $$RegisteredParcelsTableCreateCompanionBuilder,
      $$RegisteredParcelsTableUpdateCompanionBuilder,
      (
        RegisteredParcel,
        BaseReferences<
          _$AppDatabase,
          $RegisteredParcelsTable,
          RegisteredParcel
        >,
      ),
      RegisteredParcel,
      PrefetchHooks Function()
    >;
typedef $$OfflineAreasTableCreateCompanionBuilder =
    OfflineAreasCompanion Function({
      Value<int> id,
      required String name,
      required double south,
      required double west,
      required double north,
      required double east,
      required int minZoom,
      required int maxZoom,
      Value<String?> tileSource,
      Value<int> tileCount,
      Value<int> bytes,
      Value<int> parcelCount,
      Value<bool> complete,
      required DateTime updatedAt,
    });
typedef $$OfflineAreasTableUpdateCompanionBuilder =
    OfflineAreasCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> south,
      Value<double> west,
      Value<double> north,
      Value<double> east,
      Value<int> minZoom,
      Value<int> maxZoom,
      Value<String?> tileSource,
      Value<int> tileCount,
      Value<int> bytes,
      Value<int> parcelCount,
      Value<bool> complete,
      Value<DateTime> updatedAt,
    });

class $$OfflineAreasTableFilterComposer
    extends Composer<_$AppDatabase, $OfflineAreasTable> {
  $$OfflineAreasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get south => $composableBuilder(
    column: $table.south,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get west => $composableBuilder(
    column: $table.west,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get north => $composableBuilder(
    column: $table.north,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get east => $composableBuilder(
    column: $table.east,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tileSource => $composableBuilder(
    column: $table.tileSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tileCount => $composableBuilder(
    column: $table.tileCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parcelCount => $composableBuilder(
    column: $table.parcelCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OfflineAreasTableOrderingComposer
    extends Composer<_$AppDatabase, $OfflineAreasTable> {
  $$OfflineAreasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get south => $composableBuilder(
    column: $table.south,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get west => $composableBuilder(
    column: $table.west,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get north => $composableBuilder(
    column: $table.north,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get east => $composableBuilder(
    column: $table.east,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minZoom => $composableBuilder(
    column: $table.minZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxZoom => $composableBuilder(
    column: $table.maxZoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tileSource => $composableBuilder(
    column: $table.tileSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tileCount => $composableBuilder(
    column: $table.tileCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytes => $composableBuilder(
    column: $table.bytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parcelCount => $composableBuilder(
    column: $table.parcelCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OfflineAreasTableAnnotationComposer
    extends Composer<_$AppDatabase, $OfflineAreasTable> {
  $$OfflineAreasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get south =>
      $composableBuilder(column: $table.south, builder: (column) => column);

  GeneratedColumn<double> get west =>
      $composableBuilder(column: $table.west, builder: (column) => column);

  GeneratedColumn<double> get north =>
      $composableBuilder(column: $table.north, builder: (column) => column);

  GeneratedColumn<double> get east =>
      $composableBuilder(column: $table.east, builder: (column) => column);

  GeneratedColumn<int> get minZoom =>
      $composableBuilder(column: $table.minZoom, builder: (column) => column);

  GeneratedColumn<int> get maxZoom =>
      $composableBuilder(column: $table.maxZoom, builder: (column) => column);

  GeneratedColumn<String> get tileSource => $composableBuilder(
    column: $table.tileSource,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tileCount =>
      $composableBuilder(column: $table.tileCount, builder: (column) => column);

  GeneratedColumn<int> get bytes =>
      $composableBuilder(column: $table.bytes, builder: (column) => column);

  GeneratedColumn<int> get parcelCount => $composableBuilder(
    column: $table.parcelCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$OfflineAreasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OfflineAreasTable,
          OfflineArea,
          $$OfflineAreasTableFilterComposer,
          $$OfflineAreasTableOrderingComposer,
          $$OfflineAreasTableAnnotationComposer,
          $$OfflineAreasTableCreateCompanionBuilder,
          $$OfflineAreasTableUpdateCompanionBuilder,
          (
            OfflineArea,
            BaseReferences<_$AppDatabase, $OfflineAreasTable, OfflineArea>,
          ),
          OfflineArea,
          PrefetchHooks Function()
        > {
  $$OfflineAreasTableTableManager(_$AppDatabase db, $OfflineAreasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OfflineAreasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OfflineAreasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OfflineAreasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> south = const Value.absent(),
                Value<double> west = const Value.absent(),
                Value<double> north = const Value.absent(),
                Value<double> east = const Value.absent(),
                Value<int> minZoom = const Value.absent(),
                Value<int> maxZoom = const Value.absent(),
                Value<String?> tileSource = const Value.absent(),
                Value<int> tileCount = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<int> parcelCount = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => OfflineAreasCompanion(
                id: id,
                name: name,
                south: south,
                west: west,
                north: north,
                east: east,
                minZoom: minZoom,
                maxZoom: maxZoom,
                tileSource: tileSource,
                tileCount: tileCount,
                bytes: bytes,
                parcelCount: parcelCount,
                complete: complete,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double south,
                required double west,
                required double north,
                required double east,
                required int minZoom,
                required int maxZoom,
                Value<String?> tileSource = const Value.absent(),
                Value<int> tileCount = const Value.absent(),
                Value<int> bytes = const Value.absent(),
                Value<int> parcelCount = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                required DateTime updatedAt,
              }) => OfflineAreasCompanion.insert(
                id: id,
                name: name,
                south: south,
                west: west,
                north: north,
                east: east,
                minZoom: minZoom,
                maxZoom: maxZoom,
                tileSource: tileSource,
                tileCount: tileCount,
                bytes: bytes,
                parcelCount: parcelCount,
                complete: complete,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OfflineAreasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OfflineAreasTable,
      OfflineArea,
      $$OfflineAreasTableFilterComposer,
      $$OfflineAreasTableOrderingComposer,
      $$OfflineAreasTableAnnotationComposer,
      $$OfflineAreasTableCreateCompanionBuilder,
      $$OfflineAreasTableUpdateCompanionBuilder,
      (
        OfflineArea,
        BaseReferences<_$AppDatabase, $OfflineAreasTable, OfflineArea>,
      ),
      OfflineArea,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurveysTableTableManager get surveys =>
      $$SurveysTableTableManager(_db, _db.surveys);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$RegisteredParcelsTableTableManager get registeredParcels =>
      $$RegisteredParcelsTableTableManager(_db, _db.registeredParcels);
  $$OfflineAreasTableTableManager get offlineAreas =>
      $$OfflineAreasTableTableManager(_db, _db.offlineAreas);
}
