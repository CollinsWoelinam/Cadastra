import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../app.dart';
import '../data/db.dart';
import 'capture_screen.dart';
import 'format.dart';
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
        ],
      ),
      body: Column(
        children: [
          ListenableBuilder(
            listenable: sync,
            builder: (context, _) => sync.offlineReason == null
                ? const SizedBox.shrink()
                : MaterialBanner(
                    content: Text(sync.offlineReason!, maxLines: 2, overflow: TextOverflow.ellipsis),
                    leading: const Icon(Icons.cloud_off),
                    actions: [TextButton(onPressed: sync.sync, child: const Text('Retry'))],
                  ),
          ),
          Expanded(
            child: StreamBuilder<List<Survey>>(
              stream: services.db.watchSurveys(),
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
    final db = Services.read(context).db;
    final id = const Uuid().v4();
    final now = DateTime.now();
    await db.into(db.surveys).insert(SurveysCompanion.insert(
          id: id,
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
