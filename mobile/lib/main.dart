import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'auth/session.dart';
import 'config.dart';
import 'data/db.dart';
import 'location/position_source.dart';
import 'map/tile_store.dart';
import 'services/api_client.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = AppDatabase();
  final session = AuthSession(apiBaseUrl, SecureTokenStore());
  await session.load();
  final sync = SyncService(db, ApiClient(apiBaseUrl, session));

  // Upload whenever connectivity returns, and poll review status while the app is open.
  Connectivity().onConnectivityChanged.listen((results) {
    if (!results.contains(ConnectivityResult.none)) sync.sync();
  });
  Timer.periodic(const Duration(minutes: 2), (_) => sync.sync());
  sync.sync();

  final support = await getApplicationSupportDirectory();
  final tileStore = basemapAllowsOfflineDownload ? TileStore(Directory('${support.path}/basemap'), basemapUrl) : null;

  runApp(CadastraApp(
    services: AppServices(
      db: db,
      session: session,
      sync: sync,
      positionSource: DevicePositionSource.new,
      tileStore: tileStore,
    ),
  ));
}
