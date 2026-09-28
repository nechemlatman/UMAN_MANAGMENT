import 'package:flutter/material.dart';
import '../../domain/value_objects/civil_date.dart';
import '../design_system.dart';

DateTime _calendar(CivilDate date) => DateTime(date.year, date.month, date.day);
CivilDate _civil(DateTime date) => CivilDate(date.year, date.month, date.day);
String friendlyCivilDate(BuildContext context, CivilDate? date) => date == null
    ? (Localizations.localeOf(context).languageCode == 'he'
          ? 'לא נבחר'
          : 'Not selected')
    : MaterialLocalizations.of(context).formatMediumDate(_calendar(date));

/// Calendar focus may be today; only an explicit selection changes domain data.
class OptionalCivilDateField extends StatelessWidget {
  const OptionalCivilDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.allowClear = true,
  });
  final String label;
  final CivilDate? value;
  final ValueChanged<CivilDate?> onChanged;
  final bool enabled;
  final bool allowClear;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_month),
          label: Text('$label: ${friendlyCivilDate(context, value)}'),
          onPressed: !enabled
              ? null
              : () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate: value == null
                        ? DateTime.now()
                        : _calendar(value!),
                    firstDate: DateTime(1),
                    lastDate: DateTime(9999, 12, 31),
                  );
                  if (selected != null && context.mounted) {
                    onChanged(_civil(selected));
                  }
                },
        ),
      ),
      if (allowClear && value != null)
        IconButton(
          tooltip:
              '${Localizations.localeOf(context).languageCode == 'he' ? 'ניקוי' : 'Clear'} $label',
          onPressed: enabled ? () => onChanged(null) : null,
          icon: const Icon(Icons.clear),
          constraints: const BoxConstraints(
            minWidth: AppSpace.touch,
            minHeight: AppSpace.touch,
          ),
        ),
    ],
  );
}

/// Range selection writes both endpoints only after confirmation. Separate
/// endpoint calendars retain partial drafts and allow either endpoint to clear.
class OptionalCivilDateRangeField extends StatelessWidget {
  const OptionalCivilDateRangeField({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
    this.enabled = true,
    this.startLabel,
    this.endLabel,
    this.rangeLabel,
    this.helpText,
  });
  final CivilDate? start, end;
  final void Function(CivilDate?, CivilDate?) onChanged;
  final bool enabled;
  final String? startLabel, endLabel, rangeLabel, helpText;
  @override
  Widget build(BuildContext context) {
    final hebrew = Localizations.localeOf(context).languageCode == 'he';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.date_range),
          label: Text(
            rangeLabel ?? (hebrew ? 'בחירת תקופת שהייה' : 'Choose stay range'),
          ),
          onPressed: !enabled
              ? null
              : () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1),
                    lastDate: DateTime(9999, 12, 31),
                    initialDateRange:
                        start != null &&
                            end != null &&
                            start!.compareTo(end!) <= 0
                        ? DateTimeRange(
                            start: _calendar(start!),
                            end: _calendar(end!),
                          )
                        : null,
                    helpText:
                        helpText ??
                        (hebrew
                            ? 'כניסה עד יציאה (ללא ליל היציאה)'
                            : 'Check-in through checkout (checkout night excluded)'),
                  );
                  if (range != null && context.mounted) {
                    onChanged(_civil(range.start), _civil(range.end));
                  }
                },
        ),
        OptionalCivilDateField(
          label: startLabel ?? (hebrew ? 'כניסה' : 'Check-in date'),
          value: start,
          enabled: enabled,
          onChanged: (value) => onChanged(value, end),
        ),
        OptionalCivilDateField(
          label: endLabel ?? (hebrew ? 'יציאה' : 'Checkout date'),
          value: end,
          enabled: enabled,
          onChanged: (value) => onChanged(start, value),
        ),
        if (start != null || end != null)
          TextButton(
            onPressed: enabled ? () => onChanged(null, null) : null,
            child: Text(hebrew ? 'ניקוי תאריכים' : 'Clear dates'),
          ),
      ],
    );
  }
}
