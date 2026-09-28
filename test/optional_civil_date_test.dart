import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/value_objects/civil_date.dart';
import 'package:uman_event_manager/presentation/forms/optional_civil_date.dart';

void main() {
  for (final language in ['en', 'he']) {
    testWidgets(
      'Calendar selection, cancel and clear preserve null semantics ($language)',
      (tester) async {
        CivilDate? value = CivilDate(2026, 9, 20);
        var calls = 0;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en'), Locale('he')],
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => OptionalCivilDateField(
                  label: 'Date',
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
        expect(find.byType(DatePickerDialog), findsOneWidget);
        final dialogContext = tester.element(find.byType(DatePickerDialog));
        expect(
          Directionality.of(dialogContext),
          language == 'he' ? TextDirection.rtl : TextDirection.ltr,
        );
        final cancel = MaterialLocalizations.of(
          dialogContext,
        ).cancelButtonLabel;
        await tester.tap(find.text(cancel));
        await tester.pumpAndSettle();
        expect(value.toString(), '2026-09-20');
        expect(calls, 0);
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text('21'));
        await tester.pumpAndSettle();
        final ok = MaterialLocalizations.of(
          tester.element(find.byType(DatePickerDialog)),
        ).okButtonLabel;
        await tester.tap(find.text(ok));
        await tester.pumpAndSettle();
        expect(value.toString(), '2026-09-21');
        expect(calls, 1);
        await tester.tap(find.byIcon(Icons.clear));
        await tester.pumpAndSettle();
        expect(value, isNull);
        expect(calls, 2);
        await tester.tap(find.byType(OutlinedButton));
        await tester.pumpAndSettle();
        await tester.tap(find.text(cancel));
        await tester.pumpAndSettle();
        expect(value, isNull);
        expect(calls, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Range calendar confirms both endpoints; cancel and individual clear preserve partial data',
    (tester) async {
      CivilDate? start = CivilDate(2026, 9, 20), end = CivilDate(2026, 9, 23);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => OptionalCivilDateRangeField(
                start: start,
                end: end,
                onChanged: (a, b) => setState(() {
                  start = a;
                  end = b;
                }),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose stay range'));
      await tester.pumpAndSettle();
      expect(find.byType(DateRangePickerDialog), findsOneWidget);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(start.toString(), '2026-09-20');
      expect(end.toString(), '2026-09-23');
      await tester.tap(find.text('Choose stay range'));
      await tester.pumpAndSettle();
      final save = MaterialLocalizations.of(
        tester.element(find.byType(DateRangePickerDialog)),
      ).saveButtonLabel;
      await tester.tap(find.text(save));
      await tester.pumpAndSettle();
      expect(start.toString(), '2026-09-20');
      expect(end.toString(), '2026-09-23');
      await tester.tap(find.byTooltip('Clear Checkout date'));
      await tester.pumpAndSettle();
      expect(start.toString(), '2026-09-20');
      expect(end, isNull);
      await tester.tap(find.text('Choose stay range'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(end, isNull);
      await tester.tap(find.text('Clear dates'));
      await tester.pumpAndSettle();
      expect(start, isNull);
      expect(end, isNull);
    },
  );
}
