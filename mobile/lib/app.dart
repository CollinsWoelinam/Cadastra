import 'package:flutter/material.dart';

import 'auth/session.dart';
import 'data/db.dart';
import 'location/position_source.dart';
import 'services/sync_service.dart';
import 'ui/login_screen.dart';
import 'ui/surveys_screen.dart';

class AppServices {
  final AppDatabase db;
  final AuthSession session;
  final SyncService sync;
  final PositionSource Function() positionSource;

  /// Off in widget tests, which have no network for map tiles.
  final bool showBasemap;

  AppServices({
    required this.db,
    required this.session,
    required this.sync,
    required this.positionSource,
    this.showBasemap = true,
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
        theme: ThemeData(colorSchemeSeed: const Color(0xFF1D4ED8), useMaterial3: true),
        // Signing out swaps the whole navigator back to the sign-in screen.
        home: ListenableBuilder(
          listenable: services.session,
          builder: (context, _) => services.session.signedIn
              ? SurveysScreen(key: ValueKey(services.session.user!.id))
              : const LoginScreen(),
        ),
      ),
    );
  }
}
