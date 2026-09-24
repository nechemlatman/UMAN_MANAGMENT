import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/driver.dart';
import 'package:uman_event_manager/domain/entities/vehicle.dart';
import 'package:uman_event_manager/domain/value_objects/uuid_v4.dart';

void main() {
  group('Driver Domain Entity', () {
    test('DriverStatus fromCode rejects unknown values', () {
      expect(DriverStatus.fromCode('AVAILABLE'), DriverStatus.available);
      expect(DriverStatus.fromCode('UNAVAILABLE'), DriverStatus.unavailable);
      expect(() => DriverStatus.fromCode('UNKNOWN'), throwsFormatException);
    });

    test('DriverInputToJson creates expected map', () {
      const input = DriverInput(
        fullName: 'Yossi Levi',
        phoneNumber: '0501234567',
        licenseNumber: '12345',
        notes: 'Driver notes',
        status: DriverStatus.available,
      );

      final json = input.toJson();
      expect(json['full_name'], 'Yossi Levi');
      expect(json['phone_number'], '0501234567');
      expect(json['license_number'], '12345');
      expect(json['status'], 'AVAILABLE');
    });

    test('Driver copyWith increments version correctly', () {
      final now = DateTime.now().toUtc();
      final driver = Driver(
        id: UuidV4.generate(),
        eventId: UuidV4.generate(),
        fullName: 'Original Name',
        phoneNumber: '050',
        licenseNumber: '111',
        notes: '',
        status: DriverStatus.available,
        isDeleted: false,
        version: 1,
        createdAtUtc: now,
        updatedAtUtc: now,
        createdBy: 'user-1',
        updatedBy: 'user-1',
      );

      final updated = driver.copyWith(
        fullName: 'New Name',
        version: 2,
      );

      expect(updated.fullName, 'New Name');
      expect(updated.version, 2);
      expect(updated.id, driver.id);
    });
  });

  group('Vehicle Domain Entity', () {
    test('VehicleType and VehicleStatus fromCode', () {
      expect(VehicleType.fromCode('VAN'), VehicleType.van);
      expect(VehicleType.fromCode('BUS'), VehicleType.bus);
      expect(() => VehicleType.fromCode('INVALID'), throwsFormatException);

      expect(VehicleStatus.fromCode('AVAILABLE'), VehicleStatus.available);
      expect(VehicleStatus.fromCode('MAINTENANCE'), VehicleStatus.maintenance);
      expect(() => VehicleStatus.fromCode('INVALID'), throwsFormatException);
    });

    test('VehicleInputToJson creates expected map', () {
      const input = VehicleInput(
        name: 'Sprinter 1',
        type: VehicleType.minibus,
        capacity: 19,
        licensePlate: '55-666-77',
        status: VehicleStatus.available,
        notes: 'Clean van',
      );

      final json = input.toJson();
      expect(json['name'], 'Sprinter 1');
      expect(json['vehicle_type'], 'MINIBUS');
      expect(json['capacity'], 19);
      expect(json['status'], 'AVAILABLE');
    });
  });
}
