import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/application/event_controller.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/presentation/events/event_editor.dart';
import 'cloud_controller_test.dart' show FakeRepository, MemoryCache, sample;

void main() {
  Future<void> scrollToSave(WidgetTester tester) => tester.scrollUntilVisible(
    find.text('Save'),
    300,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('event-editor-scroll')),
          matching: find.byType(Scrollable),
        )
        .first,
  );

  testWidgets('all optional text survives canonical changes and revocation', (
    tester,
  ) async {
    final repo = FakeRepository();
    final controller = EventController(repo, MemoryCache());
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(
        home: EventEditor(controller: controller, base: sample()),
      ),
    );
    final drafts = <TextEditingController>[];
    for (final label in [
      'Name',
      'Hebrew name',
      'Description',
      'Manager notes',
    ]) {
      final field = tester.widget<TextField>(find.byKey(ValueKey(label)));
      drafts.add(field.controller!..text = 'draft $label');
    }
    repo.rows = [];
    repo.notifications.add(RepositorySignal.changed);
    await tester.pumpAndSettle();
    expect(drafts.map((c) => c.text), [
      'draft Name',
      'draft Hebrew name',
      'draft Description',
      'draft Manager notes',
    ]);
    await scrollToSave(tester);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    await tester.runAsync(controller.close);
    await tester.pumpAndSettle();
    expect(find.text('Session ended'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('name-only draft never invents year dates or currency', (
    tester,
  ) async {
    final repo = FakeRepository();
    final controller = EventController(repo, MemoryCache());
    await controller.start();
    await tester.pumpWidget(
      MaterialApp(home: EventEditor(controller: controller)),
    );
    await tester.enterText(find.byKey(const ValueKey('Name')), 'Draft event');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('Year')))
          .controller!
          .text,
      isEmpty,
    );
    await scrollToSave(tester);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(repo.createdInput!.name, 'Draft event');
    expect(repo.createdInput!.year, isNull);
    expect(repo.createdInput!.startDate, isNull);
    expect(repo.createdInput!.endDate, isNull);
    expect(repo.createdInput!.baseCurrency, isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(controller.close);
  });
}
