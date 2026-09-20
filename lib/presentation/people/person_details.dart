import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/people_controller.dart';
import '../../domain/entities/person.dart';
import '../design_system.dart';
import 'person_editor.dart';
import 'person_labels.dart';

class PersonDetails extends StatefulWidget {
  const PersonDetails({super.key, required this.controller, required this.id});
  final PeopleController controller;
  final String id;
  @override
  State<PersonDetails> createState() => _PersonDetailsState();
}

class _PersonDetailsState extends State<PersonDetails> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.controller.select(widget.id));
  }

  @override
  void dispose() {
    unawaited(widget.controller.select(null));
    super.dispose();
  }

  Future<void> deletion(Person person) async {
    final deleted = !person.summary.isDeleted;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deleted ? 'Delete person?' : 'Restore person?'),
        content: Text(
          deleted
              ? 'Hide this person from the ordinary list. All details and historical relationships are preserved and can be restored.'
              : 'Return this person to the ordinary list without changing their status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(deleted ? 'Delete' : 'Restore'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final saved = await widget.controller.setDeleted(person.summary, deleted);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? deleted
                    ? 'Person deleted. You can restore them.'
                    : 'Person restored.'
              : peopleFailure(widget.controller.state.failure),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PeopleController, PeopleState>(
    bloc: widget.controller,
    builder: (context, state) {
      final p = state.person;
      return Scaffold(
        appBar: AppBar(title: const Text('Person details')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.l),
            children: [
              if (!state.accessible || state.load == PeopleLoad.error) ...[
                Text(peopleFailure(state.failure)),
                TextButton(
                  onPressed: widget.controller.reconcile,
                  child: const Text('Retry'),
                ),
              ] else if (p == null)
                const Center(child: CircularProgressIndicator())
              else ...[
                Text(
                  BidiTextFormatter.isolate(p.summary.displayName),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (p.summary.isDeleted)
                  const Text('Deleted — details and relationships preserved.'),
                if (!state.writable) const Text('Event is read-only.'),
                for (final field in PersonField.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.s),
                    child: Text(
                      '${personLabel(field)}: ${BidiTextFormatter.isolate(p.input[field]?.isNotEmpty == true ? p.input[field]! : 'Not entered')}',
                    ),
                  ),
                Text('Status: ${p.input.status.name}'),
                for (final field in p.input.customFields.entries)
                  Text(
                    '${BidiTextFormatter.isolate(field.key)}: ${BidiTextFormatter.isolate('${field.value}')}',
                  ),
                Text('Last updated: ${p.summary.updatedAtUtc.toLocal()}'),
                FilledButton(
                  onPressed: state.canWrite && !p.summary.isDeleted
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => PersonEditor(
                              controller: widget.controller,
                              base: p,
                            ),
                          ),
                        )
                      : null,
                  child: const Text('Edit person'),
                ),
                TextButton(
                  onPressed: state.canWrite ? () => deletion(p) : null,
                  child: Text(
                    p.summary.isDeleted ? 'Restore person' : 'Delete person',
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
