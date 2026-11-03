import 'package:flutter/material.dart';

import 'auth/session.dart';
import 'data/db.dart';
import 'location/position_source.dart';
import 'map/tile_store.dart';
import 'services/neighbour_service.dart';
import 'services/offline_maps.dart';
import 'services/sync_service.dart';
import 'ui/login_screen.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

class AppServices {
  final AppDatabase db;
  final AuthSession session;
  final SyncService sync;
  final PositionSource Function() positionSource;

  /// Off in widget tests, which have no network for map tiles.
  final bool showBasemap;

  /// Basemap tiles saved on the device; null where tiles may not be saved.
  final TileStore? tileStore;

  late final NeighbourService neighbours = NeighbourService(db, sync.api);
  late final OfflineMaps offlineMaps = OfflineMaps(db, neighbours, tileStore);

  AppServices({
    required this.db,
    required this.session,
    required this.sync,
    required this.positionSource,
    this.showBasemap = true,
    this.tileStore,
  });
}

class Services extends InheritedWidget {
  final AppServices services;

  const Services({super.key, required this.services, required super.child});

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Services>()!.services;

  /// Non-subscribing lookup, safe in initState and callbacks.
  static AppServices read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Services>()!.services;

  @override
  bool updateShouldNotify(Services oldWidget) => services != oldWidget.services;
}

class CadastraApp extends StatelessWidget {
  final AppServices services;

  const CadastraApp({super.key, required this.services});

  @override
  Widget build(BuildContext context) {
    return Services(
      services: services,
      child: MaterialApp(
        title: 'Cadastra Field',
        debugShowCheckedModeBanner: false,
        theme: cadastraTheme(),
        // Signing out swaps the whole navigator back to the sign-in screen.
        home: ListenableBuilder(
          listenable: services.session,
          builder: (context, _) => services.session.signedIn
              ? HomeShell(key: ValueKey(services.session.user!.id))
              : const LoginScreen(),
        ),
      ),
    );
  }
}
