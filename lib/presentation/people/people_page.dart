import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/people_controller.dart';
import '../../domain/entities/person.dart';
import '../design_system.dart';
import 'person_details.dart';
import 'person_editor.dart';
import 'person_labels.dart';

class PeoplePage extends StatelessWidget {
  const PeoplePage({super.key, required this.controller});
  final PeopleController controller;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PeopleController, PeopleState>(
    bloc: controller,
    builder: (context, state) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.l),
          child: Column(
            children: [
                    TextFormField(
                      initialValue: state.query,
                key: const ValueKey('people-search'),
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Search names, phones or notes',
                ),
                onChanged: controller.search,
              ),
              CheckboxListTile(
                title: const Text('Show deleted people'),
                value: state.deleted,
                onChanged: (v) => controller.search(state.query, deleted: v),
              ),
              if (!state.accessible)
                Text(peopleFailure(state.failure))
              else if (!state.online && state.synchronizedAt != null)
                Text(
                  'Offline — last synchronized ${state.synchronizedAt!.toLocal()}. Read-only.',
                )
              else if (!state.realtimeConnected && state.online)
                const Text(
                  'Live updates reconnecting. Checking for changes periodically.',
                ),
              if (state.online && !state.writable)
                const Text('Event is read-only.'),
              if (state.load == PeopleLoad.error)
                Text(peopleFailure(state.failure)),
              Wrap(
                spacing: AppSpace.s,
                children: [
                  FilledButton.icon(
                    onPressed: state.canWrite
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  PersonEditor(controller: controller),
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add person'),
                  ),
                  TextButton(
                    onPressed: controller.reconcile,
                    child: const Text('Refresh / Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (state.load == PeopleLoad.loading) const LinearProgressIndicator(),
        Expanded(
          child: state.load == PeopleLoad.empty
              ? Center(
                  child: Text(
                    state.query.isNotEmpty
                        ? 'No matching people.'
                        : state.deleted
                        ? 'No deleted people.'
                        : 'No people yet. Add the first person.',
                  ),
                )
              : ListView.builder(
                  itemCount: state.rows.length,
                  itemBuilder: (context, i) {
                    final p = state.rows[i];
                    return ListTile(
                      key: ValueKey(p.id),
                      title: Text(BidiTextFormatter.isolate(p.displayName)),
                      subtitle: Text(
                        '${BidiTextFormatter.isolate(p.phone.isEmpty ? 'Phone not entered' : p.phone)} · ${p.status == PersonStatus.active ? 'Active' : 'Inactive'}',
                      ),
                      onTap: state.online
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => PersonDetails(
                                  controller: controller,
                                  id: p.id,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
        ),
        Wrap(
          spacing: AppSpace.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              onPressed: state.page > 0
                  ? () => controller.page(state.page - 1)
                  : null,
              child: const Text('Previous'),
            ),
            Text('Page ${state.page + 1}'),
            TextButton(
              onPressed: state.hasNext
                  ? () => controller.page(state.page + 1)
                  : null,
              child: const Text('Next'),
            ),
          ],
        ),
      ],
    ),
  );
}
