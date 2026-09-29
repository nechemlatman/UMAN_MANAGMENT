import 'package:flutter/material.dart';
import '../../domain/value_objects/civil_date.dart';
import '../design_system.dart';
import 'optional_civil_date.dart';

/// Fixed-offset wall time is explicit: device timezone/DST never reinterpret it.
DateTime timestampAtOffset(CivilDate date, TimeOfDay time, int offsetMinutes) =>
    DateTime.utc(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    ).subtract(Duration(minutes: offsetMinutes));

String friendlyTimestamp(BuildContext context, DateTime? value) {
  if (value == null) return friendlyCivilDate(context, null);
  final utc = value.toUtc();
  if (utc.year < 1 || utc.year > 9999) {
    return Localizations.localeOf(context).languageCode == 'he'
        ? 'מחוץ לטווח התאריכים'
        : 'Outside supported date range';
  }
  return '${friendlyCivilDate(context, CivilDate(utc.year, utc.month, utc.day))} '
      '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(utc))} UTC';
}

class OptionalTimestampField extends StatelessWidget {
  const OptionalTimestampField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          icon: const Icon(Icons.event),
          label: Text('$label: ${friendlyTimestamp(context, value)}'),
          onPressed: !enabled
              ? null
              : () async {
                  final result = await showDialog<DateTime>(
                    context: context,
                    builder: (_) =>
                        _TimestampDialog(label: label, value: value),
                  );
                  if (result != null && context.mounted) onChanged(result);
                },
        ),
      ),
      if (value != null)
        IconButton(
          tooltip:
              '${Localizations.localeOf(context).languageCode == 'he' ? 'ניקוי' : 'Clear'} $label',
          constraints: const BoxConstraints(
            minWidth: AppSpace.touch,
            minHeight: AppSpace.touch,
          ),
          onPressed: enabled ? () => onChanged(null) : null,
          icon: const Icon(Icons.clear),
        ),
    ],
  );
}

class _TimestampDialog extends StatefulWidget {
  const _TimestampDialog({required this.label, required this.value});
  final String label;
  final DateTime? value;
  @override
  State<_TimestampDialog> createState() => _TimestampDialogState();
}

class _TimestampDialogState extends State<_TimestampDialog> {
  CivilDate? date;
  TimeOfDay? time;
  int offset = 0;
  bool changed = false;
  @override
  void initState() {
    super.initState();
    final utc = widget.value?.toUtc();
    if (utc != null) {
      date = CivilDate(utc.year, utc.month, utc.day);
      time = TimeOfDay.fromDateTime(utc);
    }
  }

  @override
  Widget build(BuildContext context) {
    final he = Localizations.localeOf(context).languageCode == 'he';
    final candidate = !changed && widget.value != null
        ? widget.value!.toUtc()
        : date == null || time == null
        ? null
        : timestampAtOffset(date!, time!, offset);
    return AlertDialog(
      title: Text(widget.label),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              he
                  ? 'בחרו היסט UTC מפורש לשעה המקומית. בדקו את ההמרה לפני אישור; אין ניחוש אזור זמן או שעון קיץ.'
                  : 'Choose the explicit UTC offset for the local time. Check the conversion before confirming; timezone and daylight saving are not inferred.',
            ),
            DropdownButtonFormField<int>(
              initialValue: offset,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: he ? 'היסט השעה המקומית' : 'Local time offset',
              ),
              items: [
                for (int m = -720; m <= 840; m += 15)
                  DropdownMenuItem(
                    value: m,
                    child: Text(
                      'UTC${m < 0 ? '-' : '+'}${(m.abs() ~/ 60).toString().padLeft(2, '0')}:${(m.abs() % 60).toString().padLeft(2, '0')}',
                    ),
                  ),
              ],
              onChanged: (v) => setState(() {
                offset = v!;
                changed = true;
              }),
            ),
            OptionalCivilDateField(
              label: he ? 'תאריך מקומי' : 'Local date',
              value: date,
              onChanged: (v) => setState(() {
                date = v;
                changed = true;
              }),
            ),
            OutlinedButton(
              onPressed: () async {
                final result = await showTimePicker(
                  context: context,
                  initialTime: time ?? const TimeOfDay(hour: 12, minute: 0),
                );
                if (result != null && mounted) {
                  setState(() {
                    time = result;
                    changed = true;
                  });
                }
              },
              child: Text(
                '${he ? 'שעה מקומית' : 'Local time'}: ${time == null ? (he ? 'לא נבחר' : 'Not selected') : MaterialLocalizations.of(context).formatTimeOfDay(time!)}',
              ),
            ),
            Text(
              '${he ? 'יישמר' : 'Will save'}: ${friendlyTimestamp(context, candidate)}',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed:
              candidate == null || candidate.year < 1 || candidate.year > 9999
              ? null
              : () => Navigator.pop(context, candidate),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
