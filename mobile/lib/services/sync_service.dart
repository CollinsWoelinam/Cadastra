import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../auth/session.dart';
import '../data/db.dart';
import 'api_client.dart';

/// Uploads finished surveys and refreshes the review status of synced ones.
class SyncService extends ChangeNotifier {
  final AppDatabase db;
  final ApiClient api;
  Future<void>? _running;

  /// Last connectivity problem, cleared on the next successful contact.
  String? offlineReason;

  /// The session has ended; uploads wait until the surveyor signs in again.
  bool needsSignIn = false;

  SyncService(this.db, this.api);

  bool get isSyncing => _running != null;

  /// Runs one sync pass; concurrent callers share the pass already in flight.
  Future<void> sync() {
    final pass = _running ??= _syncOnce().whenComplete(() {
      _running = null;
      notifyListeners();
    });
    notifyListeners();
    return pass;
  }

  Future<void> _syncOnce() async {
    // Only the signed-in surveyor's own surveys are uploaded under their account.
    final owner = api.session.user?.id;
    if (owner == null) return;
    try {
      for (final survey in await db.surveysIn(SyncState.queued, owner)) {
        await _upload(survey);
      }
      for (final survey in await db.surveysIn(SyncState.synced, owner)) {
        if (survey.serverStatus == 'PENDING') await _refresh(survey);
      }
      offlineReason = null;
      needsSignIn = false;
    } on AuthRequiredException catch (e) {
      // Not a refusal: everything stays queued until the surveyor signs in.
      needsSignIn = true;
      offlineReason = e.toString();
    } on Exception catch (e) {
      // Network failure: everything stays queued for the next pass.
      offlineReason = 'Offline — will retry ($e)';
    }
  }

  Future<void> _upload(Survey survey) async {
    final nodes = await db.nodesOf(survey.id);
    try {
      final result = await api.submit(survey, nodes);
      await db.updateSurvey(survey.id, SurveysCompanion(
        syncState: const Value(SyncState.synced),
        serverParcelId: Value(result.parcelId),
        serverStatus: Value(result.status),
        conflictsJson: Value(jsonEncode(result.conflicts)),
        lastError: const Value(null),
      ));
    } on RejectedException catch (e) {
      await db.updateSurvey(survey.id, SurveysCompanion(
        syncState: const Value(SyncState.failed),
        lastError: Value(e.message),
      ));
    }
  }

  Future<void> _refresh(Survey survey) async {
    final id = survey.serverParcelId!;
    try {
      final parcel = await api.parcel(id);
      final conflicts = await api.conflicts(id);
      await db.updateSurvey(survey.id, SurveysCompanion(
        serverStatus: Value(parcel['status'] as String),
        reviewNote: Value(parcel['review_note'] as String?),
        conflictsJson: Value(jsonEncode(conflicts)),
        lastError: const Value(null),
      ));
    } on RejectedException catch (e) {
      await db.updateSurvey(survey.id, SurveysCompanion(lastError: Value(e.message)));
    }
  }

  /// Puts a failed survey back in the queue, optionally with corrected details.
  Future<void> retry(String surveyId, {String? titleDeedNo, String? ownerName}) async {
    await db.updateSurvey(surveyId, SurveysCompanion(
      syncState: const Value(SyncState.queued),
      lastError: const Value(null),
      titleDeedNo: titleDeedNo == null ? const Value.absent() : Value(titleDeedNo),
      ownerName: ownerName == null ? const Value.absent() : Value(ownerName),
    ));
    await sync();
  }
}
