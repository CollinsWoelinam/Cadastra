import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../data/db.dart';
import 'capture_screen.dart';
import 'format.dart';
import 'login_screen.dart';
import 'survey_detail_screen.dart';

class SurveysScreen extends StatelessWidget {
  const SurveysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final sync = services.sync;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastra Field'),
        actions: [
          ListenableBuilder(
            listenable: sync,
            builder: (context, _) => sync.isSyncing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(tooltip: 'Sync now', icon: const Icon(Icons.sync), onPressed: sync.sync),
          ),
          const _AccountMenu(),
        ],
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: sync,
            builder: (context, _) => sync.needsSignIn
                ? MaterialBanner(
                    content: const Text('Your session has ended. Surveys stay on this device until you sign in.'),
                    leading: const Icon(Icons.lock_clock),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => LoginScreen(email: services.session.user?.email),
                        )),
                        child: const Text('Sign in'),
                      ),
                    ],
                  )
                : sync.offlineReason == null
                ? const SizedBox.shrink()
                : MaterialBanner(
                    content: Text(sync.offlineReason!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    leading: const Icon(Icons.cloud_off),
                    actions: [TextButton(onPressed: sync.sync, child: const Text('Retry'))],
                  ),
          ),
          Expanded(
            child: StreamBuilder<List<Survey>>(
              stream: services.db.watchSurveys(services.session.user!.id),
              builder: (context, snapshot) {
                final surveys = snapshot.data ?? [];
                return RefreshIndicator(
                  onRefresh: sync.sync,
                  child: surveys.isEmpty
                      ? ListView(children: const [
                          Padding(
                            padding: EdgeInsets.all(32),
                            child: Text('No surveys yet. Tap “New survey” to capture a boundary.',
                                textAlign: TextAlign.center),
                          ),
                        ])
                      : ListView.separated(
                          itemCount: surveys.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, i) => _SurveyTile(surveys[i]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newSurvey(context),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('New survey'),
      ),
    );
  }

  Future<void> _newSurvey(BuildContext context) async {
    final details = await showDialog<(String, String)>(context: context, builder: (_) => const SurveyDetailsDialog());
    if (details == null || !context.mounted) return;
    final services = Services.read(context);
    final db = services.db;
    final id = const Uuid().v4();
    final now = DateTime.now();
    await db.into(db.surveys).insert(SurveysCompanion.insert(
          id: id,
          ownerUserId: Value(services.session.user!.id),
          titleDeedNo: details.$1,
          ownerName: details.$2,
          syncState: SyncState.draft,
          createdAt: now,
          updatedAt: now,
        ));
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CaptureScreen(surveyId: id)));
    }
  }
}

class _SurveyTile extends StatelessWidget {
  final Survey survey;

  const _SurveyTile(this.survey);

  @override
  Widget build(BuildContext context) {
    final (label, color) = surveyStatus(survey, Conflict.listFrom(survey));
    return ListTile(
      title: Text(survey.titleDeedNo, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${survey.ownerName} · ${formatArea(survey.areaSqm)}'),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => survey.syncState == SyncState.draft
            ? CaptureScreen(surveyId: survey.id)
            : SurveyDetailScreen(surveyId: survey.id),
      )),
    );
  }
}

/// Collects title deed number and owner; returns them as a record.
class SurveyDetailsDialog extends StatefulWidget {
  final String? titleDeedNo;
  final String? ownerName;
  final String title;

  const SurveyDetailsDialog({super.key, this.titleDeedNo, this.ownerName, this.title = 'New survey'});

  @override
  State<SurveyDetailsDialog> createState() => _SurveyDetailsDialogState();
}

class _SurveyDetailsDialogState extends State<SurveyDetailsDialog> {
  final _form = GlobalKey<FormState>();
  late final _deed = TextEditingController(text: widget.titleDeedNo);
  late final _owner = TextEditingController(text: widget.ownerName);

  @override
  void dispose() {
    _deed.dispose();
    _owner.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _form,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            key: const Key('deed'),
            controller: _deed,
            decoration: const InputDecoration(labelText: 'Title deed no.'),
            textCapitalization: TextCapitalization.characters,
            maxLength: 50,
            validator: _required,
          ),
          TextFormField(
            key: const Key('owner'),
            controller: _owner,
            decoration: const InputDecoration(labelText: 'Owner name'),
            textCapitalization: TextCapitalization.words,
            maxLength: 100,
            validator: _required,
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_form.currentState!.validate()) {
              Navigator.pop(context, (_deed.text.trim(), _owner.text.trim()));
            }
          },
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final user = services.session.user!;
    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: const Icon(Icons.account_circle),
      onSelected: (_) => _signOut(context),
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text('${user.fullName}\n${user.email}')),
        const PopupMenuItem(value: 'logout', child: Text('Sign out')),
      ],
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
