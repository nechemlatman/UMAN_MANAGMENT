# UMAN EVENT MANAGER — Technical Specification v1.2

Authoritative architecture: ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md and Master v2.6.

## Change-friendly forms — owner amendment 2026-09-28

- Save validation protects minimum identity, type/length/range integrity. Explicit
  operational status/activation invokes separate completeness validation. ACC
  inputs expose `validateForSave` and `validateForOperation`; `validate` composes
  both for the chosen state. Server constraints/RPCs remain authoritative.
- `lib/presentation/forms/optional_civil_date.dart` owns calendar selection,
  localized display, cancellation, and clear actions. Values remain `CivilDate?`;
  local `DateTime` is only a calendar adapter, never a UTC conversion. Range
  controls accept label/help overrides; no missing endpoint is inferred.
- `CloudApp` supplies Flutter English/Hebrew localization delegates. Shared
  controls inherit locale, direction and the centralized design system.
- Add an ACC field through the typed input/validation, codec, forward migration
  allowlist/constraints, then editor/display. Labels belong to presentation;
  persistence column names stay in codecs. Add enum values in domain and a new
  database constraint migration; selectors derive their options from enums.
- Browsing, editing and common feedback have separate ACC presentation files.
  Controller/repository retain established realtime, polling, CAS and disposal.
- Unknown references remain nullable with unchanged same-event composite FKs.
  Server-only `has_been_operational` protects assignment identity after first use;
  clients cannot write it. Migration rollout keeps existing data and audit intact.
  Old clients cannot decode new DRAFT/null records; deploy the updated client
  with this migration before allowing draft creation. No old data is rewritten
  into fake completed records for compatibility.
- Existing screen conversion inventory lives in TASK-ACC-01, not a second
  architecture document. Do not combine those migrations with an unrelated task.

### FORM-01 extension points (2026-09-29)

- `domain/value_objects/form_policy.dart` owns provided-value validation and Event/
  route operational completeness. Event inputs, FlightInput and TripInput expose
  save validation; explicit operational states compose their additional rules.
  Enum getters centralize which states require completeness. RPCs/CHECKs enforce
  the same boundaries. SQL null preserves unknown data in codecs and caches.
- `presentation/forms/optional_timestamp.dart` owns shared date/time interaction,
  fixed-offset conversion and localized UTC display. Offset selection applies to
  the entered wall time, previewed before commit; it is not an IANA timezone or
  inferred DST rule. Existing timestamp precision is retained on unchanged confirm.
- Event uses the existing optional civil range; People uses its two calendar fields.
  Form errors appear on an attempted Save/action. Canonical refresh never overwrites
  editor drafts; stale CAS retains the form and requires intentional reopening.
- `20260928214807_legacy_draft_forms.sql` is additive/nullable, with no source-row or
  audit backfill. Flight operational completeness is in the restricted save RPC so
  legacy incomplete operational rows survive untouched; Trip CHECK can validate
  legacy rows because their route/schedule were previously NOT NULL. All old
  migration files and same-event/security/CAS/audit contracts remain unchanged.
- Deploy the updated client with the migration before managers create null drafts:
  older clients assume non-null Event/Flight/Trip fields. No synthetic compatibility
  values or automatic migration of operational records into draft are allowed.
- Extend a field in typed input/policy → codec → forward migration → editor/display;
  labels stay in presentation, visual tokens in the design system. FORM-01 evidence
  is in its workcard; ACC-01's original inventory remains historical evidence.

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
increments it and fails stale writes. Additional narrow RPCs edit Event details,
transition its stage, archive, soft-delete and restore tombstones. Settings are
not generic edits; PLANNING → READY remains unavailable pending minimum setup.
Archive is final operationally. ISO currency validation and attribution FK indexes
are versioned migrations. Triggers generate old/new audit snapshots
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
Design tokens remain centralized under UMAN_EVENT_MANAGER_VISUAL_DESIGN_SYSTEM.md. The active direction is classic, clean, simple, modern and professional; historical Breslov references do not govern new screens.
