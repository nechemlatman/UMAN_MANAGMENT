import '../../domain/entities/person.dart';
import '../../domain/repositories/event_repository.dart';

String personLabel(PersonField field) => switch (field) {
  PersonField.firstName => 'First name',
  PersonField.lastName => 'Last name',
  PersonField.hebrewFirstName => 'Hebrew first name',
  PersonField.hebrewLastName => 'Hebrew last name',
  PersonField.phone => 'Phone',
  PersonField.whatsappPhone => 'WhatsApp phone',
  PersonField.email => 'Email',
  PersonField.passportName => 'Passport name',
  PersonField.passportNumber => 'Passport number',
  PersonField.passportExpirationDate => 'Passport expiry (YYYY-MM-DD)',
  PersonField.dateOfBirth => 'Date of birth (YYYY-MM-DD)',
  PersonField.nationality => 'Nationality',
  PersonField.emergencyContactName => 'Emergency contact name',
  PersonField.emergencyContactPhone => 'Emergency contact phone',
  PersonField.notes => 'Notes',
};

String peopleFailure(CloudFailureKind? failure) => switch (failure) {
  CloudFailureKind.unauthorized =>
    'Access is unavailable. Return to Events and check your membership.',
  CloudFailureKind.conflict =>
    'This record changed. Your draft is kept. Close and reopen it to review current details.',
  CloudFailureKind.invalid =>
    'Some values could not be saved. Review the fields and try again.',
  CloudFailureKind.unavailable =>
    'Connection unavailable. Check your connection and retry.',
  _ =>
    'The operation could not be confirmed. Review current data before retrying.',
};
