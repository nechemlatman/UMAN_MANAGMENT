import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/value_objects/civil_date.dart';
import 'package:uman_event_manager/presentation/forms/optional_timestamp.dart';

void main() {
  test(
    'Explicit positive and negative offsets cross civil-day boundaries deterministically',
    () {
      expect(
        timestampAtOffset(
          CivilDate(2026, 9, 1),
          const TimeOfDay(hour: 1, minute: 15),
          180,
        ),
        DateTime.utc(2026, 8, 31, 22, 15),
      );
      expect(
        timestampAtOffset(
          CivilDate(2026, 9, 1),
          const TimeOfDay(hour: 23, minute: 30),
          -330,
        ),
        DateTime.utc(2026, 9, 2, 5),
      );
    },
  );
  for (final language in ['en', 'he']) {
    testWidgets('Timestamp cancel clear and unchanged precision ($language)', (
      tester,
    ) async {
      final original = DateTime.utc(2026, 9, 21, 10, 30, 42, 123);
      DateTime? value = original;
      int calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(language),
          supportedLocales: const [Locale('en'), Locale('he')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => OptionalTimestampField(
                label: 'Schedule',
                value: value,
                onChanged: (v) => setState(() {
                  value = v;
                  calls++;
                }),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(AlertDialog));
      expect(
        Directionality.of(context),
        language == 'he' ? TextDirection.rtl : TextDirection.ltr,
      );
      final loc = MaterialLocalizations.of(context);
      await tester.tap(find.text(loc.cancelButtonLabel));
      await tester.pumpAndSettle();
      expect(value, original);
      expect(calls, 0);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(loc.okButtonLabel));
      await tester.pumpAndSettle();
      expect(value, original);
      expect(calls, 1);
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(value, isNull);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text(loc.cancelButtonLabel));
      await tester.pumpAndSettle();
      expect(value, isNull);
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Explicit offset preview and confirmation persist UTC without device-zone conversion',
    (tester) async {
      DateTime? value = DateTime.utc(2026, 9, 21, 10, 30);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => OptionalTimestampField(
                label: 'Schedule',
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('UTC+03:00'),
        120,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('UTC+03:00').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('Will save:'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(value, DateTime.utc(2026, 9, 21, 7, 30));
    },
  );
}
