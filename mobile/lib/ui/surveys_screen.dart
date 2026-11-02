import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../data/db.dart';
import '../services/sync_service.dart';
import 'capture_screen.dart';
import 'format.dart';
import 'login_screen.dart';
import 'survey_detail_screen.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Filter { all, inProgress, submitted }

class SurveysScreen extends StatefulWidget {
  final VoidCallback? onOpenAccount;

  const SurveysScreen({super.key, this.onOpenAccount});

  @override
  State<SurveysScreen> createState() => _SurveysScreenState();
}

class _SurveysScreenState extends State<SurveysScreen> {
  _Filter _filter = _Filter.all;

  static String _greeting() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Good morning' : h < 17 ? 'Good afternoon' : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    final sync = services.sync;
    final user = services.session.user!;
    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Survey>>(
          stream: services.db.watchSurveys(user.id),
          builder: (context, snapshot) {
            final all = snapshot.data ?? [];
            final open = [for (final s in all) if (s.syncState != SyncState.synced) s];
            final shown = switch (_filter) {
              _Filter.all => all,
              _Filter.inProgress => open,
              _Filter.submitted => [for (final s in all) if (s.syncState == SyncState.synced) s],
            };
            final waiting = all.where((s) => s.syncState == SyncState.queued).length;
            return RefreshIndicator(
              onRefresh: sync.sync,
              child: CustomScrollView(slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${_greeting()}, ${user.fullName.split(' ').first}',
                              style: const TextStyle(fontSize: 13, color: Palette.muted)),
                          const Text('Surveys', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                        ]),
                      ),
                      ListenableBuilder(
                        listenable: sync,
                        builder: (context, _) => sync.isSyncing
                            ? const SizedBox(
                                width: 44, height: 44, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                            : IconButton.outlined(
                                tooltip: 'Sync now',
                                onPressed: sync.sync,
                                style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Palette.line)),
                                icon: const Icon(Icons.sync),
                              ),
                      ),
                      const SizedBox(width: 6),
                      Semantics(
                        button: true,
                        label: 'Account',
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: widget.onOpenAccount,
                          child: InitialsAvatar(user.fullName),
                        ),
                      ),
                    ]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: ListenableBuilder(
                    listenable: sync,
                    builder: (context, _) => _SyncBanner(sync: sync, waiting: waiting, email: user.email),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(children: [
                      for (final (f, label) in [
                        (_Filter.all, 'All · ${all.length}'),
                        (_Filter.inProgress, 'In progress · ${open.length}'),
                        (_Filter.submitted, 'Submitted · ${all.length - open.length}'),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: _filter == f,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filter = f),
                            selectedColor: Palette.ink,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: _filter == f ? Palette.ink : Palette.lineStrong),
                            labelStyle: TextStyle(
                              color: _filter == f ? Colors.white : Palette.ink2,
                              fontWeight: _filter == f ? FontWeight.w600 : FontWeight.w500,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        ),
                    ]),
                  ),
                ),
                if (snapshot.hasData && shown.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        all.isEmpty ? 'No surveys yet. Tap “New survey” to capture a boundary.' : 'Nothing here.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Palette.muted),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  sliver: SliverList.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _SurveyCard(shown[i]),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Tabs stay mounted together, so each tab's button needs its own hero tag.
        heroTag: 'new-survey',
        onPressed: () => _newSurvey(context),
        icon: const Icon(Icons.add),
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

/// Dark strip at the top when uploads are held up: no signal, or the session ended.
class _SyncBanner extends StatelessWidget {
  final SyncService sync;
  final int waiting;
  final String email;

  const _SyncBanner({required this.sync, required this.waiting, required this.email});

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail, action, onAction) = sync.needsSignIn
        ? (Icons.lock_clock, 'Session ended.', 'Surveys stay on this device until you sign in.', 'Sign in',
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen(email: email))))
        : sync.offlineReason != null
            ? (
                Icons.signal_wifi_off,
                'No signal.',
                waiting == 0 ? 'Will retry automatically.' : '$waiting survey${waiting == 1 ? '' : 's'} will upload when you are back online.',
                'Retry',
                sync.sync
              )
            : (null, null, null, null, null);
    if (icon == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(color: Palette.ink, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Icon(icon, color: Palette.gold, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: detail, style: const TextStyle(color: Color(0xFFC8D3CE))),
            ]),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        TextButton(onPressed: onAction, style: TextButton.styleFrom(foregroundColor: Colors.white), child: Text(action!)),
      ]),
    );
  }
}

class _SurveyCard extends StatelessWidget {
  final Survey survey;

  const _SurveyCard(this.survey);

  @override
  Widget build(BuildContext context) {
    final status = surveyStatus(survey, Conflict.listFrom(survey));
    final draft = survey.syncState == SyncState.draft;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: status.tone == Tone.red ? Palette.redLine : Palette.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => draft ? CaptureScreen(surveyId: survey.id) : SurveyDetailScreen(surveyId: survey.id),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: status.tone.tint, borderRadius: BorderRadius.circular(12)),
              child: Icon(status.icon, color: status.tone.text),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(survey.titleDeedNo, style: mono)),
                  Text(formatWhen(survey.updatedAt), style: const TextStyle(fontSize: 12, color: Palette.muted)),
                ]),
                const SizedBox(height: 2),
                Text(draft || survey.areaSqm == 0 ? survey.ownerName : '${survey.ownerName} · ${formatSqm(survey.areaSqm)}'),
                const SizedBox(height: 2),
                Text(status.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: status.tone.text)),
              ]),
            ),
          ]),
        ),
      ),
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
