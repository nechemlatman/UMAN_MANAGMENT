import 'package:flutter_test/flutter_test.dart';
import 'package:uman_event_manager/domain/entities/person.dart';
import 'package:uman_event_manager/infrastructure/cloud/person_codec.dart';
import 'support/people_fakes.dart';

void main() {
  test(
    'all specified source fields round trip including nullable expiry and custom data',
    () {
      final p = personFixture();
      final fields = encodePersonInput(p.input);
      expect(fields.length, PersonField.values.length + 2);
      expect(fields['passport_expiration_date'], '2030-02-28');
      expect(fields['passport_number'], isNull);
      expect(fields['hebrew_first_name'], 'דוד');
      expect(p.summary.eventId, peopleEvent);
      expect(p.createdAtUtc.isUtc, isTrue);
      expect(fields['custom_fields'], {'group': 'test'});
    },
  );
  test(
    'partial records are allowed; names, email, calendar dates and lengths validated',
    () {
      expect(
        PersonInput(values: {PersonField.firstName: 'דוד'}).validate(),
        isEmpty,
      );
      final invalid = PersonInput(
        values: {
          PersonField.firstName: ' ',
          PersonField.email: 'bad@',
          PersonField.passportExpirationDate: '2030-02-30',
          PersonField.dateOfBirth: '1990-13-01',
          PersonField.phone: '1' * 101,
        },
      ).validate();
      expect(
        invalid.keys,
        containsAll([
          PersonField.firstName,
          PersonField.email,
          PersonField.passportExpirationDate,
          PersonField.dateOfBirth,
          PersonField.phone,
        ]),
      );
    },
  );
  test(
    'source text and nested custom values cannot be changed through aliases',
    () {
      final custom = <String, Object?>{
        'nested': {'value': 'original'},
      };
      final p = PersonInput(
        values: {PersonField.firstName: ' דוד '},
        customFields: custom,
      );
      (custom['nested'] as Map)['value'] = 'changed';
      (p.customFields['nested'] as Map)['value'] = 'changed again';
      expect(p.customFields, {
        'nested': {'value': 'original'},
      });
      expect(p[PersonField.firstName], ' דוד ');
    },
  );
}
