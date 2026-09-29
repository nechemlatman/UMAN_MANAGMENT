import 'civil_date.dart';
import 'currency_codes.dart';

abstract final class FormPolicy {
  static void event({
    required String name,
    int? year,
    String? start,
    String? end,
    String? currency,
    String? hebrewName,
    String? description,
    String? notes,
  }) {
    if (name.trim().isEmpty) {
      throw const FormatException('Enter an event name.');
    }
    text(name, 200, 'Name');
    text(hebrewName, 200, 'Hebrew name');
    text(description, 10000, 'Description');
    text(notes, 10000, 'Manager notes');
    if (year != null && (year < 1900 || year > 2200)) {
      throw const FormatException('Year must be between 1900 and 2200.');
    }
    if (currency != null && !eventCurrencyCodes.contains(currency)) {
      throw const FormatException(
        'Choose a recognized uppercase currency code.',
      );
    }
    try {
      final a = start == null ? null : CivilDate.parse(start),
          b = end == null ? null : CivilDate.parse(end);
      if (a != null && b != null && b.compareTo(a) < 0) {
        throw const FormatException('End date must not precede start date.');
      }
    } on ArgumentError {
      throw const FormatException('Choose a valid calendar date.');
    }
  }

  static void eventOperation({
    required int? year,
    required CivilDate? start,
    required CivilDate? end,
    required String? currency,
  }) {
    if (year == null || start == null || end == null || currency == null) {
      throw const FormatException(
        'Complete the event year, dates and currency before entering an operational stage.',
      );
    }
  }

  static void text(String? value, int max, String label) {
    if ((value?.length ?? 0) > max) {
      throw FormatException('$label must be at most $max characters.');
    }
  }

  static void schedule(
    DateTime? departure,
    DateTime? arrival, {
    DateTime? actualDeparture,
    DateTime? actualArrival,
  }) {
    for (final value in [departure, arrival, actualDeparture, actualArrival]) {
      if (value != null &&
          (!value.isUtc || value.year < 1 || value.year > 9999)) {
        throw const FormatException('Choose a valid UTC date and time.');
      }
    }
    if (departure != null && arrival != null && !arrival.isAfter(departure)) {
      throw const FormatException('Scheduled arrival must be after departure.');
    }
  }

  static void routeOperation(
    String? origin,
    String? destination,
    DateTime? departure,
    DateTime? arrival,
  ) {
    if ((origin?.trim().isEmpty ?? true) ||
        (destination?.trim().isEmpty ?? true) ||
        departure == null ||
        arrival == null) {
      throw const FormatException(
        'Complete the route and scheduled departure/arrival before choosing an operational status. Save the draft to finish later.',
      );
    }
  }
}
