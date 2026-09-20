import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/flight.dart';
import 'package:uman_event_manager/infrastructure/cloud/flight_codec.dart';

void main() {
  test('flight codec decodes all fields correctly', () {
    final json = {
      'id': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      'event_id': '22222222-2222-4222-8222-222222222222',
      'direction': 'INBOUND',
      'airline': 'El Al',
      'flight_number': 'LY001',
      'departure_airport': 'JFK',
      'arrival_airport': 'TLV',
      'scheduled_departure_utc': '2026-09-21T10:00:00Z',
      'scheduled_arrival_utc': '2026-09-21T20:00:00Z',
      'actual_departure_utc': '2026-09-21T10:05:00Z',
      'actual_arrival_utc': null,
      'status': 'DELAYED',
      'delay_minutes': 5,
      'terminal': '4',
      'gate': 'B20',
      'notes': 'Test notes',
      'is_locked': true,
      'is_deleted': false,
      'created_at_utc': '2026-09-20T10:00:00Z',
      'updated_at_utc': '2026-09-20T10:00:00Z',
      'created_by': 'u1',
      'updated_by': 'u1',
      'version': 3,
    };

    final flight = decodeFlight(json);
    
    expect(flight.id, 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
    expect(flight.direction, FlightDirection.inbound);
    expect(flight.status, FlightStatus.delayed);
    expect(flight.delayMinutes, 5);
    expect(flight.isLocked, true);
    expect(flight.actualDepartureUtc, DateTime.parse('2026-09-21T10:05:00Z'));
    expect(flight.actualArrivalUtc, isNull);
  });

  test('flight passenger codec decodes correctly', () {
    final json = {
      'id': 'p1',
      'flight_id': 'f1',
      'person_id': 'per1',
      'seat_number': '12A',
      'booking_reference': 'ABCDEF',
      'notes': 'Veg meal',
      'status': 'CONFIRMED',
      'version': 1,
      'person_first_name': 'David',
      'person_last_name': 'Cohen',
    };

    final fp = decodeFlightPassenger(json);
    expect(fp.seatNumber, '12A');
    expect(fp.status, FlightPassengerStatus.confirmed);
    expect(fp.personFullName, 'David Cohen');
  });
}
