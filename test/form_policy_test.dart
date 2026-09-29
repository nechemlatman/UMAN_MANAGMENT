import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/flight.dart';
import 'package:uman_event_manager/domain/entities/trip.dart';
import 'package:uman_event_manager/domain/repositories/event_repository.dart';
import 'package:uman_event_manager/domain/repositories/flights_repository.dart';
import 'package:uman_event_manager/domain/value_objects/form_policy.dart';
import 'package:uman_event_manager/infrastructure/cloud/event_codec.dart';
import 'package:uman_event_manager/infrastructure/cloud/flight_codec.dart';
import 'package:uman_event_manager/infrastructure/cloud/trip_codec.dart';
import 'cloud_controller_test.dart' show sample;

void main() {
  test(
    'Event name-only draft round-trips nullable metadata; malformed provided data fails',
    () {
      const NewEvent(requestId: 'request', name: 'Draft').validateForSave();
      final row = encodeEvent(sample())
        ..addAll({
          'year': null,
          'start_date': null,
          'end_date': null,
          'base_currency': null,
        });
      expect(encodeEvent(decodeEvent(row)), row);
      expect(
        () => const NewEvent(requestId: 'request', name: ' ').validateForSave(),
        throwsFormatException,
      );
      expect(
        () => const NewEvent(
          requestId: 'request',
          name: 'Draft',
          startDate: '2026-02-31',
        ).validateForSave(),
        throwsFormatException,
      );
      expect(
        () => const NewEvent(
          requestId: 'request',
          name: 'Draft',
          startDate: '2026-09-02',
          endDate: '2026-09-01',
        ).validateForSave(),
        throwsFormatException,
      );
      expect(
        () => FormPolicy.eventOperation(
          year: null,
          start: null,
          end: null,
          currency: null,
        ),
        throwsFormatException,
      );
    },
  );
  test(
    'Flight draft codec keeps all unknown values null and UTC instants exact',
    () {
      final input = FlightInput(direction: FlightDirection.inbound);
      input.validate();
      final json = input.toJson();
      expect(json['status'], 'DRAFT');
      for (final key in [
        'airline',
        'flight_number',
        'departure_airport',
        'arrival_airport',
        'scheduled_departure_utc',
        'scheduled_arrival_utc',
      ]) {
        expect(json[key], isNull);
      }
      final f = decodeFlight({
        ...json,
        'id': 'id',
        'event_id': 'event',
        'is_deleted': false,
        'created_at_utc': '2026-09-01T00:00:00Z',
        'updated_at_utc': '2026-09-01T00:00:00Z',
        'created_by': 'actor',
        'updated_by': 'actor',
        'version': 1,
      });
      expect(f.scheduledArrivalUtc, isNull);
      expect(f.airline, isNull);
      expect(f.status, FlightStatus.draft);
      final partial = FlightInput(
        direction: FlightDirection.outbound,
        scheduledDepartureUtc: DateTime.parse(
          '2026-09-01T10:00:00+03:00',
        ).toUtc(),
      );
      partial.validate();
      expect(
        partial.toJson()['scheduled_departure_utc'],
        '2026-09-01T07:00:00.000Z',
      );
    },
  );
  test(
    'Flight operational completeness is separate from save; complete actions pass',
    () {
      for (final status in FlightStatus.values) {
        final input = FlightInput(
          direction: FlightDirection.inbound,
          status: status,
        );
        input.validateForSave();
        if (status.requiresComplete) {
          expect(input.validateForOperation, throwsFormatException);
        } else {
          input.validateForOperation();
        }
      }
      FlightInput(
        direction: FlightDirection.inbound,
        status: FlightStatus.scheduled,
        airline: 'Carrier',
        flightNumber: 'F1',
        departureAirport: 'AAA',
        arrivalAirport: 'BBB',
        scheduledDepartureUtc: DateTime.utc(2026),
        scheduledArrivalUtc: DateTime.utc(2026, 1, 1, 1),
      ).validate();
    },
  );
  test(
    'Trip planned and cancelled drafts preserve nulls; operational statuses require route and schedule',
    () {
      for (final status in TripStatus.values) {
        final input = TripInput(direction: TripDirection.local, status: status);
        input.validateForSave();
        expect(encodeTrip(input)['scheduled_departure_utc'], isNull);
        expect(encodeTrip(input)['origin'], isNull);
        final decoded = decodeTrip({
          ...encodeTrip(input),
          'id': 'trip',
          'event_id': 'event',
          'version': 1,
          'created_by': 'actor',
          'updated_by': 'actor',
          'created_at_utc': '2026-09-01T00:00:00Z',
          'updated_at_utc': '2026-09-01T00:00:00Z',
          'is_deleted': false,
        });
        expect(encodeTrip(decoded.input), encodeTrip(input));
        if (status.requiresComplete) {
          expect(input.validateForOperation, throwsFormatException);
        } else {
          input.validateForOperation();
        }
      }
      expect(
        () => TripInput(
          direction: TripDirection.local,
          scheduledDepartureUtc: DateTime.utc(2026),
          scheduledArrivalUtc: DateTime.utc(2026),
        ).validate(),
        throwsFormatException,
      );
    },
  );
}
