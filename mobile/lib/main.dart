import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'config.dart';
import 'data/db.dart';
import 'location/position_source.dart';
import 'services/api_client.dart';
import 'services/sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final sync = SyncService(db, ApiClient(apiBaseUrl));

  // Upload whenever connectivity returns, and poll review status while the app is open.
  Connectivity().onConnectivityChanged.listen((results) {
    if (!results.contains(ConnectivityResult.none)) sync.sync();
  });
  Timer.periodic(const Duration(minutes: 2), (_) => sync.sync());
  sync.sync();

  runApp(CadastraApp(
    services: AppServices(db: db, sync: sync, positionSource: DevicePositionSource.new),
  ));
}
