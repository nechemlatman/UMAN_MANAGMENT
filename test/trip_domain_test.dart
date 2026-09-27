import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/trip.dart';
import 'package:uman_event_manager/infrastructure/cloud/trip_codec.dart';
import 'support/trip_fakes.dart';

void main() {
  test('schedule must be strictly increasing UTC', () {
    expect(
      () => tripInput(arrival: DateTime.utc(2026, 9, 1, 10)).validate(),
      throwsFormatException,
    );
    expect(
      () => tripInput(arrival: DateTime(2026, 9, 1, 12)).validate(),
      throwsFormatException,
    );
    expect(() => tripInput().validate(), returnsNormally);
  });
  test('capacity below and exact are valid; overflow warns', () {
    expect(tripSample(count: 0).overCapacity, false);
    expect(tripSample(count: 1).overCapacity, false);
    expect(tripSample(count: 2).overCapacity, true);
  });
  test('actual arrival preserves explicit planned status', () {
    final i = tripInput(actual: DateTime.utc(2026, 9, 1, 12));
    i.validate();
    expect(encodeTrip(i)['status'], 'PLANNED');
    expect(encodeTrip(i)['actual_arrival_utc'], isNotNull);
  });
  test('pickup remains nullable and statuses round trip', () {
    for (final status in TripPassengerStatus.values) {
      final input = TripPassengerInput(
        tripId: tripId,
        personId: tripEvent,
        status: status,
      );
      input.validate();
      expect(encodeTripPassenger(input)['pickup_location'], null);
      expect(encodeTripPassenger(input)['passenger_status'], status.code);
    }
  });
  test('invalid UUIDs and oversized notes rejected', () {
    expect(
      () => const TripPassengerInput(
        tripId: 'invalid',
        personId: tripEvent,
      ).validate(),
      throwsFormatException,
    );
    expect(
      () => TripPassengerInput(
        tripId: tripId,
        personId: tripEvent,
        pickupNotes: 'x' * 2001,
      ).validate(),
      throwsFormatException,
    );
  });
  test('cancelled and tombstoned passengers are not active', () {
    for (final deleted in [false, true]) {
      for (final status in TripPassengerStatus.values) {
        final p = TripPassenger(
          id: tripId,
          eventId: tripEvent,
          input: TripPassengerInput(
            tripId: tripId,
            personId: tripEvent,
            status: status,
          ),
          version: 1,
          createdAtUtc: DateTime.utc(2026),
          updatedAtUtc: DateTime.utc(2026),
          createdBy: tripEvent,
          updatedBy: tripEvent,
          isDeleted: deleted,
        );
        expect(p.active, !deleted && status != TripPassengerStatus.cancelled);
      }
    }
  });
}
