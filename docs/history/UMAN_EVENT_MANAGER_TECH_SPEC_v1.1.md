> HISTORICAL ONLY — superseded by Master v2.6 / Technical v1.2 / ADR-001. Not implementation instructions.

# UMAN EVENT MANAGER — Technical Architecture & Implementation Specification v1.1

## 1. Baseline and non-negotiables

- **Version:** 1.1
- **Status:** IMPLEMENTATION BASELINE — OPEN PRODUCT DECISIONS EXPLICITLY DEFERRED
- **Product authority:** Master Product & System Specification v2.4. Product/domain requirements prevail on conflict.
- **Scope:** offline, single-device Android and iOS MVP. No cloud, sync, RBAC, or PDF/HTML reports.
- **Platform delivery:** Windows/Android are the current development path, never an Android-only product boundary. iOS is mandatory for production and must pass the `CROSS_PLATFORM_DELIVERY.md` iOS Compatibility Gate before handoff.
- **Architecture:** Flutter presentation/BLoC → application use cases → pure-Dart domain entities/rules/repository contracts → Drift infrastructure. `lib/domain/` must not import Flutter, Drift, database, file-system, or platform packages.
- **IDs and time:** normal persistent entities, including event-scoped `OperationalRule`, use UUIDv4. `UnresolvedItem.id` is a deterministic SHA-256 identity. Persist timestamps in UTC.

## 2. Rules and unresolved state

### 2.1 Canonical catalog

The only codes are: `PERSON_WITHOUT_SLEEPING_PLACE`, `PERSON_WITHOUT_TRANSPORT`, `PASSPORT_EXPIRY_RISK`, `PERSON_MISSING_CRITICAL_INFO`, `FLIGHT_DELAY_IMPACT`, `FLIGHT_CANCELLED`, `DUPLICATE_FLIGHT_ASSIGNMENT`, `FLIGHT_MISSING_INFO`, `VEHICLE_OVER_CAPACITY`, `TRN_NO_DRIVER`, `UNLINKED_FLIGHT_ARRIVAL`, `TRIP_VEHICLE_UNAVAILABLE`, `ACCOMMODATION_OVERLAP`, `OVERFLOW_ROOM_CAPACITY`, `OVERDUE_TASK`, `UNRESOLVED_APARTMENT_ISSUE`, `EXPENSE_WITHOUT_RATE`, `UNPAID_BALANCE`, and `EVENT_LIFECYCLE_TRANSITION_NEEDED`.

`ACCOMMODATION_OVERLAP` is the sole overlap code. `ACC_OVERLAP`, `FLIGHT_SCHEDULE_CHANGE`, `FLIGHT_ARRIVAL_DEVIATION`, and `PASSENGER_WITHOUT_TRANSPORT` are forbidden aliases. `UNPAID_BALANCE` is seeded inactive and cannot be evaluated until OPD-002/003 are approved.

### 2.2 Identity and lifecycle

```text
canonical = ruleCode + "|" + entityType + "|" + entityId + "|" + (scopeKey ?? "")
id = SHA-256(UTF-8(canonical)).hex
```

For unordered facts, the scope key is sorted IDs joined by `|`; query order is never used. Rules return candidate conditions, never random IDs or lifecycle timestamps.

A transactional `UnresolvedItemStore.upsertEvaluationResult()` owns lifecycle:
1. New ID: insert DETECTED with `detectedAtUtc=now`, `autoResolved=false`.
2. Existing DETECTED/ACKNOWLEDGED ID returned again: retain status, original detection time, acknowledgments, and `autoResolved=false`; update explanatory text only.
3. Existing active ID absent from a newly evaluated *same event/rule scope*: transition once to RESOLVED with `resolvedAtUtc=now`, `autoResolved=true`.
4. A manager-resolved item has `autoResolved=false`. A dismissed item remains dismissed by default; only `reTriggerAfterDismiss=true` permits a recurrence to reopen the same deterministic ID as DETECTED.

Rules never alter source data. Re-evaluation neither duplicates alerts nor resets acknowledgment/first-detection state.

### 2.3 Scoped rule inputs and scheduling

Do not implement an all-entity `RuleEvaluationContext`. Each pure rule accepts a small immutable snapshot from indexed repository queries, e.g. `AccommodationOverlapInput { eventId, sleepingPlaceId, activeAssignmentsForPlace }` or `TripCapacityInput { eventId, trip, vehicle, activePassengers }`.

`RuleScheduler` maps a write to affected rule scopes. An assignment evaluates its sleeping place and person/date coverage; a trip passenger evaluates that trip and relevant arrival linkage. Critical isolated writes run immediately after commit; related bursts coalesce for 300 ms. Full-event evaluation is only for startup integrity review, recovery, explicit audit, or manual refresh. CRUD must never load all tables/an entire event.

## 3. Single Drift-native encrypted database path

This is the only Android/iOS execution path:

- Use `drift` 2.32+, `drift_dev`, `build_runner`, and `sqlite3` 3.x. Do **not** use `drift_sqflite`, `sqflite_sqlcipher`, `encrypted_drift`, `sqlcipher_flutter_libs`, or `sqlite3_flutter_libs`.
- Configure the `sqlite3` build hook in `pubspec.yaml`: `sqlite3: source: sqlite3mc` (SQLite3MultipleCiphers), the current Drift-documented new-app encrypted native path.
- Use one `AppDatabase` and `NativeDatabase.createInBackground(File(path), setup: ...)` from `package:drift/native.dart`. Setup runs before Drift use: set key, enable FKs, and abort if cipher support is unavailable. Do not open a second unkeyed connection.
- Resolve the database, temporary restore, and export locations through supported cross-platform application-directory services. Never hardcode Android external storage, Windows paths, or device Downloads locations. Persistent, temporary, and user-selected export locations have distinct lifecycles.
- SQLCipher-file interoperability is not MVP scope. SQLite3MultipleCiphers is the selected AES-256 encrypted SQLite engine. A future SQLCipher-file migration needs separately tested compatibility pragmas before `PRAGMA key`; do not silently enable it.

```dart
QueryExecutor openEncryptedExecutor(File file, String hexKey) {
  return NativeDatabase.createInBackground(file, setup: (rawDb) {
    if (rawDb.select('PRAGMA cipher;').isEmpty) {
      throw StateError('Cipher unavailable; refusing plaintext database');
    }
    rawDb.execute("PRAGMA key = \"x'$hexKey'\";");
    rawDb.execute('PRAGMA foreign_keys = ON;');
    rawDb.execute('PRAGMA cipher_memory_security = ON;');
  });
}
```

Validate/escape the exact 64-lowercase-hex key before use and never log it. Release-test Android and iOS for correct-key reopen, wrong-key failure, cipher guard, migration, and backup/restore. Background work uses the same keyed executor or Drift-supported connection sharing—not a separately opened database.

### 3.1 Schema, queries, and migration

Implement exactly the 19 Master v2.4 Section 34 entities, including nullable `Person.passport_expiration_date`. Cross-event relationships are application-validated and FKs enforce existence. `OperationalRule` has unique `(event_id, rule_code)`; `UnresolvedItem` indexes `(event_id, rule_code, status)`.

Index default event lists by `(event_id, is_deleted)`, assignments by `(sleeping_place_id, start_date, end_date, is_deleted)`, and trip passengers by `(trip_id, is_deleted)`. Use SQLite FTS5 for normalized Hebrew/English search text with event ID and soft-delete filtering in the join/query; benchmark and release-test FTS5 availability in the selected cipher build. Include Master-defined soft-delete/version/device metadata; audits are append-only.

Use Drift `MigrationStrategy`, forward-only stepwise migrations, schema snapshots, and tests. For destructive migration, make a consistent pre-migration encrypted copy, migrate, run `PRAGMA quick_check`, and retain the old copy until validation. Do not downgrade a newer schema.

## 4. Security and backup

Use PBKDF2-HMAC-SHA256: 600,000 iterations, random 16-byte salt per database/backup, 32-byte output. This is the selected Phase 1 KDF; do not expose an Argon2id/PBKDF2 runtime choice. Never store the passphrase. Keep the derived DB key in memory only for the open session; store non-secret KDF metadata/configuration via `flutter_secure_storage` (Android Keystore/iOS Keychain), never raw keys/passphrases in preferences, logs, crash reports, exports, or source.

Backups use a versioned AES-256-GCM envelope: authenticated header `{formatVersion,kdfId,iterations,salt,nonce,ciphertextLength}`, ciphertext, tag, and a distinct purpose-labelled backup derivation. Verify the tag over header-as-AAD entirely in memory before creating/decrypting any archive path.

Restore order: authenticate → decrypt to unique app temporary directory → reject absolute/escaping archive paths → `quick_check` and schema compatibility → explicit destructive confirmation → pre-restore backup → close handles → atomic replace DB and sidecars → reopen/key/cipher/integrity validation. Failure leaves active data untouched and removes temp contents.

## 5. UI, output, and testing

Use BLoC. Use logical `start/end` layout and central `BidiTextFormatter` for mixed Hebrew/English names, dates, phones, passports, and flight codes. Locale changes never modify source text. Support high-contrast themes, 48dp targets, and non-colour-only severity signals.

Use responsive Flutter layouts with `SafeArea`, logical directional placement, keyboard-aware scrolling, text scaling, and no hard-coded device coordinates. Any native capability (secure storage, file export, permissions, notifications, device details) is exposed only through an infrastructure abstraction. No permission or notification is part of the current Phase 1 implementation; a future addition must be configured and tested on both Android and iOS, including required iOS `Info.plist` usage text.

MVP sharing is static bilingual plain text for copy/share/WhatsApp, timestamped and not live. Mask passport/phone fields by default and require confirmation for unmasked output. MVP export is event-scoped CSV/JSON. PDF/HTML reports are Phase 2.

Before Phase 1 completion test: pure-domain rule identity/lifecycle (including pair-order and acknowledgement preservation); event isolation and indexed scoped repositories; Android/iOS encrypted-open and migration integration; backup tamper/wrong-passphrase/Zip-Slip/atomic restore; AC-01–AC-12 (AC-04 limited to individual conversion and non-allocated totals); BIDI/widget and performance tests against Master v2.4 Section 33.

## 6. Deferred product decisions

Do not invent expense allocation, participant share, per-person unpaid balance, or `UNPAID_BALANCE` evaluation (OPD-002/003). PDF/HTML reports, global people, attachments, and custom-field structure remain deferred. Automatic lifecycle-transition criteria are undefined: Phase 1 may expose manager-authorized transitions but must not infer thresholds.
