# UMAN EVENT MANAGER — Technical Specification v1.2

Authoritative architecture: ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md and Master v2.6.

## Foundation
Flutter → BLoC/Cubit → pure Dart repository contracts → Supabase infrastructure.
PostgreSQL is canonical; Android and iOS remain mandatory. Phase 1 is
**Authenticated Cloud Persistence & Realtime Foundation**, with Event as its
representative entity. Bulk business features follow verification of this slice.

Auth uses distinct provisioned accounts, restored sessions in platform-secure
storage, explicit logout and no public membership grant. Configuration contains
only an HTTPS project URL and publishable key. Auth, RLS and RPC authorization
are mandatory even if widgets hide an action.

## Database
Versioned migrations implement events, event_members and audit_entries. Event
UUIDs, timestamps and attribution are assigned by the server. RLS grants event
reads only to its members; only administrator RPCs mutate. Mutation functions
use pinned search paths and explicit authorization, with execute privileges
revoked from PUBLIC/anon. No generic client DML is granted. Membership setup is
operator-controlled. Atomic create_event inserts Event and creator membership;
rollback removes both. update_event compares expected version while updating,
increments it and fails stale writes. Triggers generate old/new audit snapshots
in the transaction. Clients cannot insert/update/delete audit entries.

## Realtime and cache
Realtime invalidates data, never authorizes a write. On subscribed/re-subscribed,
foreground, login, mutation completion and conflict, reload canonical rows. A
bounded periodic read repairs missed notifications and revoked access. Serialize
reconciliations and rerun invalidations arriving during a fetch. Never overwrite
draft controllers with incoming rows. Dispose subscriptions on logout/account
change. Soft deletion/archive is an update; hard deletes are not exposed.

Cache only confirmed Event snapshots, partitioned by project and authenticated
user, with sync time and 24-hour maximum age. Store the small foundation snapshot
in flutter_secure_storage; do not store passports. Offline reads require a restored
identity, show staleness and disable writes. A successful empty authorized read
replaces cache (including membership revocation). No offline edits or queued retry.
Saving is acknowledged only after RPC commit; a timeout is an uncertain outcome,
so reconcile before retrying. Creation uses a stable request UUID for idempotency.

## Domain migration review
All 19 domain entities retain Master semantics. Every mutable row requires server
UUID (except deterministic UnresolvedItem), event_id, created_at/created_by,
updated_at/updated_by, version and appropriate soft deletion. Event is its own
scope. Audit is immutable rather than versioned. Junctions gain explicit event_id
and composite same-event foreign keys, including FlightPassenger, TripPassenger,
Room, SleepingPlace and AccommodationAssignment. Index event + active state and
relation/date lookups; unique active flight/person and event/rule as appropriate.
Dates remain civil dates; timestamps UTC; money numeric with preserved original
amount/rate. JSON uses jsonb, not serialized database text.

Person requires nullable passport_expiration_date; Driver remains separate;
Flight changes never silently alter Trip; Vehicle capacity allows exact capacity;
Apartment/Room/SleepingPlace have no embedded occupant; Assignment uses [start,end).
Task/ApartmentIssue lifecycle stays explicit. Expense/Payment preserve original
conversion, reversal history and locked values. OperationalRule is event-scoped;
UnresolvedItem keeps deterministic SHA-256 identity, sorted pair keys and existing
acknowledgment. Server transactions own material source/alert consistency. Pure
Dart rule previews remain advisory. No UNPAID_BALANCE until OPD-002/003 approval.

These entities beyond Event are reviewed design, not implemented tables. Their
migrations must include server tests before feature delivery. Capacity/overlap
operations must serialize scope evaluation while preserving explicit overrides
and AC-01/02 warning semantics. Do not replace warnings with an accidental hard
constraint. Finance reversal must be atomic and idempotent; no invented balances.

## Security, delivery and verification
TLS only; Android INTERNET permission, backup disabled for secure local material;
iOS Keychain device-only/unlocked access. Raw tokens, passwords, passports, SQL
payloads and exception bodies never reach logs/UI. Configure operator backups
and practice server restore in an isolated project. Clients never restore local
snapshots over canonical state. See supabase/README.md and PHASE1_PROGRESS.md.

Tests: authorization/outsider/anonymous, stale CAS, atomic creation, audit
attribution/immutability, realtime invalidation, reconnect and offline cache.
Android APK and iOS static review are separate from device/cloud integration.
Design tokens remain centralized; referenced Breslov design markdown is missing
in this checkout, so the foundation UI is provisional, not a new visual baseline.
