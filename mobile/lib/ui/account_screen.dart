import 'package:flutter/material.dart';

import '../app.dart';
import '../config.dart';
import '../data/db.dart';
import 'theme.dart';
import 'widgets.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const _roles = {'SURVEYOR': 'Surveyor', 'REVIEWER': 'Reviewer', 'ADMIN': 'Administrator'};

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final user = services.session.user!;
    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
          const Text('Account', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Panel(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              InitialsAvatar(user.fullName, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  Text(user.email, style: const TextStyle(color: Palette.muted)),
                  const SizedBox(height: 4),
                  StatusPill(_roles[user.role] ?? user.role, Tone.green),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Registry', style: TextStyle(fontSize: 12, color: Palette.muted)),
              const SizedBox(height: 2),
              Text(apiBaseUrl, style: mono.copyWith(fontSize: 14)),
              const SizedBox(height: 10),
              const Text('To change your password, sign in to the registry portal and open My account.',
                  style: TextStyle(color: Palette.ink2, height: 1.4)),
            ]),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ]),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    final services = Services.read(context);
    final owner = services.session.user!.id;
    final unsent = [
      ...await services.db.surveysIn(SyncState.draft, owner),
      ...await services.db.surveysIn(SyncState.queued, owner),
      ...await services.db.surveysIn(SyncState.failed, owner),
    ].length;
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(unsent == 0
            ? 'All your surveys are uploaded.'
            : '$unsent of your surveys are not uploaded yet. They stay on this device and will upload '
                'when you sign in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok == true) await services.session.logout();
  }
}
