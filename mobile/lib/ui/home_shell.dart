import 'package:flutter/material.dart';

import 'account_screen.dart';
import 'offline_areas_screen.dart';
import 'surveys_screen.dart';

/// The signed-in app: surveys, offline maps and the account, behind a bottom bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  void _show(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        SurveysScreen(onOpenAccount: () => _show(2)),
        const OfflineAreasScreen(),
        const AccountScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _show,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.format_list_bulleted), label: 'Surveys'),
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Offline maps'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}
