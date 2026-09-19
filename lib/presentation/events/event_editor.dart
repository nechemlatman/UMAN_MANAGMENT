import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/value_objects/civil_date.dart';
import '../../domain/value_objects/currency_codes.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';

class EventEditor extends StatefulWidget {
  const EventEditor({super.key, required this.controller, this.base});
  final EventController controller;
  final Event? base;
  @override
  State<EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends State<EventEditor> {
  late final fields = <String, TextEditingController>{
    'Name': TextEditingController(text: widget.base?.name),
    'Hebrew name': TextEditingController(text: widget.base?.hebrewName),
    'Description': TextEditingController(text: widget.base?.description),
    'Manager notes': TextEditingController(text: widget.base?.managerNotes),
    'Year': TextEditingController(
      text: (widget.base?.year ?? DateTime.now().year).toString(),
    ),
    'Start date (YYYY-MM-DD)': TextEditingController(
      text: widget.base?.startDate.toString(),
    ),
    'End date (YYYY-MM-DD)': TextEditingController(
      text: widget.base?.endDate.toString(),
    ),
    'Base currency (ISO code)': TextEditingController(
      text: widget.base?.baseCurrency ?? 'USD',
    ),
  };
  final requestId = UuidV4.generate();
  bool saving = false, conflicted = false;
  String? message;
  String value(String key) => fields[key]!.text;
  String? optional(String key) => value(key).isEmpty ? null : value(key);

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> save() async {
    late CivilDate start, end;
    final year = int.tryParse(value('Year'));
    try {
      start = CivilDate.parse(value('Start date (YYYY-MM-DD)'));
      end = CivilDate.parse(value('End date (YYYY-MM-DD)'));
      if (end.compareTo(start) < 0 ||
          year == null ||
          year < 1900 ||
          year > 2200 ||
          value('Name').trim().isEmpty ||
          value('Name').trim().length > 200 ||
          value('Hebrew name').length > 200 ||
          value('Description').length > 10000 ||
          value('Manager notes').length > 10000 ||
          !eventCurrencyCodes.contains(value('Base currency (ISO code)'))) {
        throw const FormatException();
      }
    } catch (_) {
      setState(
        () => message =
            'Check the name, year (1900–2200), real ordered dates and recognized uppercase ISO currency code. Names allow 200 characters; notes and description allow 10,000.',
      );
      return;
    }
    setState(() {
      saving = true;
      message = null;
    });
    final ok = widget.base == null
        ? await widget.controller.create(
            NewEvent(
              requestId: requestId,
              name: value('Name'),
              year: year,
              startDate: start.toString(),
              endDate: end.toString(),
              baseCurrency: value('Base currency (ISO code)'),
            ),
          )
        : await widget.controller.editDetails(
            widget.base!,
            EventDetailsInput(
              name: value('Name'),
              hebrewName: optional('Hebrew name'),
              description: optional('Description'),
              managerNotes: optional('Manager notes'),
              year: year,
              startDate: start.toString(),
              endDate: end.toString(),
              baseCurrency: value('Base currency (ISO code)'),
            ),
          );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      saving = false;
      conflicted = widget.controller.state.saveStatus == SaveStatus.conflict;
      message = conflicted
          ? 'This record changed on another device. Your text is kept here. Copy it, close this form and reopen the latest record to apply it intentionally.'
          : switch (widget.controller.state.failure) {
              CloudFailureKind.invalid =>
                'The server rejected these values. Review the fields.',
              CloudFailureKind.unauthorized =>
                'Access is no longer available. Your draft remains here.',
              _ =>
                'Save not confirmed. Check connection and current data before retrying.',
            };
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EventController, EventState>(
    bloc: widget.controller,
    builder: (context, state) {
      if (!state.authenticated) {
        return Scaffold(
          appBar: AppBar(title: const Text('Session ended')),
          body: const SafeArea(
            child: Center(child: Text('Return to sign in.')),
          ),
        );
      }
      final allowed = widget.base == null
          ? state.capabilities().canCreate
          : state.capabilities(widget.base!.id).canEdit;
      return PopScope(
        canPop: !saving,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.base == null ? 'Create event' : 'Edit event'),
          ),
          body: SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSpace.formWidth),
                child: ListView(
                  key: const ValueKey('event-editor-scroll'),
                  padding: const EdgeInsets.all(AppSpace.xl),
                  children: [
                    if (widget.base == null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpace.l),
                        child: Text(
                          'Create the Event first, then add Hebrew name, description and manager notes in Edit. Additional managers require operator-granted access.',
                        ),
                      ),
                    for (final entry in fields.entries)
                      if (widget.base != null ||
                          ![
                            'Hebrew name',
                            'Description',
                            'Manager notes',
                          ].contains(entry.key))
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpace.l),
                          child: TextField(
                            key: ValueKey(entry.key),
                            controller: entry.value,
                            readOnly: saving,
                            textDirection: entry.key == 'Hebrew name'
                                ? TextDirection.rtl
                                : [
                                    'Year',
                                    'Start date (YYYY-MM-DD)',
                                    'End date (YYYY-MM-DD)',
                                    'Base currency (ISO code)',
                                  ].contains(entry.key)
                                ? TextDirection.ltr
                                : null,
                            maxLines:
                                [
                                  'Description',
                                  'Manager notes',
                                ].contains(entry.key)
                                ? 4
                                : 1,
                            decoration: InputDecoration(labelText: entry.key),
                          ),
                        ),
                    if (!allowed)
                      const Text(
                        'Read-only: offline, saving, archived or access unavailable. Your draft is retained.',
                      ),
                    if (message != null)
                      Semantics(
                        liveRegion: true,
                        child: SelectableText(message!),
                      ),
                    const SizedBox(height: AppSpace.l),
                    FilledButton(
                      onPressed: saving || conflicted || !allowed ? null : save,
                      child: Text(saving ? 'Saving…' : 'Save'),
                    ),
                    TextButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
