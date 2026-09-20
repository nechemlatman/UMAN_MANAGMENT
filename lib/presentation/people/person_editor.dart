import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/people_controller.dart';
import '../../application/event_controller.dart';
import '../../domain/entities/person.dart';
import '../../domain/value_objects/uuid_v4.dart';
import '../design_system.dart';
import 'person_labels.dart';

class PersonEditor extends StatefulWidget {
  const PersonEditor({super.key, required this.controller, this.base});
  final PeopleController controller;
  final Person? base;
  @override
  State<PersonEditor> createState() => _PersonEditorState();
}

class _PersonEditorState extends State<PersonEditor> {
  late final fields = {
    for (final f in PersonField.values)
      f: TextEditingController(text: widget.base?.input[f] ?? ''),
  };
  late PersonStatus status = widget.base?.input.status ?? PersonStatus.active;
  late final custom = widget.base?.input.customFields ?? <String, Object?>{};
  final requestId = UuidV4.generate();
  final scroll = ScrollController();
  final customKey = TextEditingController(),
      customValue = TextEditingController();
  Map<PersonField, String> errors = {};
  String? error;
  bool busy = false, dirty = false, saved = false;
  @override
  void dispose() {
    for (final c in fields.values) {
      c.clear();
      c.dispose();
    }
    customKey.dispose();
    customValue.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final input = PersonInput(
      values: {
        for (final f in PersonField.values)
          f: fields[f]!.text.isEmpty ? null : fields[f]!.text,
      },
      status: status,
      customFields: custom,
    );
    setState(() {
      errors = input.validate();
      error = null;
    });
    if (errors.isNotEmpty || !input.customFieldsValid) {
      if (!input.customFieldsValid) {
        setState(() => error = 'Custom fields are too large.');
      }
      showFeedback();
      return;
    }
    setState(() => busy = true);
    try {
      final duplicates = await widget.controller.duplicates(
        input,
        excludeId: widget.base?.summary.id,
      );
      if (!mounted) return;
      if (duplicates.isNotEmpty) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Possible duplicate'),
            content: Text(
              'Similar names or matching phone numbers already exist:\n${duplicates.map((p) => BidiTextFormatter.isolate(p.displayName)).join('\n')}\nSave a separate record?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Review draft'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save anyway'),
              ),
            ],
          ),
        );
        if (proceed != true) return;
      }
      final ok = await widget.controller.save(
        input,
        requestId: requestId,
        base: widget.base,
      );
      if (!mounted) return;
      if (ok) {
        setState(() {
          saved = true;
          dirty = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() => error = peopleFailure(widget.controller.state.failure));
        showFeedback();
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Could not check or save this person. Check your connection and retry.',
        );
        showFeedback();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard draft?'),
        content: const Text('Unsaved changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => dirty = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  void showFeedback() {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && scroll.hasClients) {
        scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PeopleController, PeopleState>(
    bloc: widget.controller,
    builder: (context, state) => PopScope(
      canPop: !busy && (!dirty || saved || !state.accessible),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy) confirmLeave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.base == null ? 'Add person' : 'Edit person'),
        ),
        body: SafeArea(
          child: !state.accessible
              ? Center(child: Text(peopleFailure(state.failure)))
              : Align(
                  alignment: AlignmentDirectional.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSpace.formWidth,
                    ),
                    child: ListView(
                      controller: scroll,
                      padding: const EdgeInsets.all(AppSpace.l),
                      children: [
                        if (!state.canWrite && !busy)
                          const Text(
                            'Read-only until connection and event access are available.',
                          ),
                        if (widget.base != null &&
                            state.person != null &&
                            state.person!.summary.version !=
                                widget.base!.summary.version)
                          const Text(
                            'This person changed. Your draft is preserved; close and reopen to review current details.',
                          ),
                        if (error != null)
                          Semantics(liveRegion: true, child: Text(error!)),
                        const Text(
                          'First name is required. Other details can be completed later. Passport details are optional and are not stored on this device.',
                        ),
                        for (final f in PersonField.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpace.l),
                            child: TextField(
                              key: ValueKey(f),
                              controller: fields[f],
                              enabled: !busy,
                              autocorrect: false,
                              enableSuggestions: false,
                              textDirection:
                                  {
                                    PersonField.hebrewFirstName,
                                    PersonField.hebrewLastName,
                                  }.contains(f)
                                  ? TextDirection.rtl
                                  : null,
                              maxLines: f == PersonField.notes ? 4 : 1,
                              decoration: InputDecoration(
                                labelText: personLabel(f),
                                errorText: errors[f],
                              ),
                              onChanged: (_) => setState(() => dirty = true),
                            ),
                          ),
                        DropdownButtonFormField<PersonStatus>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: PersonStatus.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                ),
                              )
                              .toList(),
                          onChanged: busy
                              ? null
                              : (s) => setState(() {
                                  status = s!;
                                  dirty = true;
                                }),
                        ),
                        const SizedBox(height: AppSpace.l),
                        const Text('Custom fields'),
                        for (final entry in custom.entries.toList())
                          ListTile(
                            title: Text(BidiTextFormatter.isolate(entry.key)),
                            subtitle: Text(
                              BidiTextFormatter.isolate('${entry.value}'),
                            ),
                            trailing: IconButton(
                              tooltip: 'Remove custom field',
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: busy
                                  ? null
                                  : () => setState(() {
                                      custom.remove(entry.key);
                                      dirty = true;
                                    }),
                            ),
                          ),
                        TextField(
                          controller: customKey,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: 'Field name',
                          ),
                        ),
                        TextField(
                          controller: customValue,
                          enabled: !busy,
                          decoration: const InputDecoration(
                            labelText: 'Field value',
                          ),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                  final key = customKey.text.trim();
                                  if (key.isEmpty || custom.containsKey(key)) {
                                    error =
                                        'Choose a new, nonempty custom field name.';
                                    return;
                                  }
                                  custom[key] = customValue.text;
                                  customKey.clear();
                                  customValue.clear();
                                  dirty = true;
                                }),
                          child: const Text('Add custom field'),
                        ),
                        FilledButton(
                          onPressed:
                              busy ||
                                  !state.canWrite ||
                                  (state.save == SaveStatus.conflict &&
                                      error != null)
                              ? null
                              : save,
                          child: Text(busy ? 'Saving…' : 'Save person'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    ),
  );
}
