# Work card — Complete Event management

Opened 2026-09-19. Status: implementing; **not accepted / not complete**.

## Traceability and scope

Master §§7–8, 22, 24, 26–32, 34; REQ-001/002/003/010/012/013/015/029/034/037;
AC-08/09/10/11; workbook V-03/15/19 and VC-02/03/04/06. Technical v1.2 and ADR-001
govern cloud authority, CAS, audit, draft preservation and cache boundaries.

| Requirement | Starting state | Delivery |
|---|---|---|
| Authorized create/read/rename | Implemented; owner device evidence | Preserve compatible RPCs |
| Hebrew name, description, notes, year, dates, currency | Modeled, editing missing | Explicit field editor and versioned RPC |
| Lifecycle | Modeled, operations missing | Explicit transition RPC; no automatic dates |
| Archive | Read-only enforced, action missing | Confirmed final archive action |
| Soft delete/restore | Modeled, actions missing | Separate versioned actions; no cascade |
| Settings | Object exists, semantics partial | No raw JSON editor; preserve untouched keys |
| Capabilities | Only online/saving | Auth/session, membership-visible Event, read-only, revoked, lifecycle |
| List/details/edit separation | One dialog | Feature components, immutable draft base |
| Bilingual UI | Missing | Pending bilingual/device acceptance |

Managers select an authorized Event, read details, edit explicit fields and
save against the opened version. New canonical data never rewrites the draft.
Conflict retains all entered text and requires closing/reopening intentionally.
Archived records remain readable; soft-deleted records have a separate list view.
Restore only clears a tombstone; it never reopens ARCHIVED to CLOSEOUT.
Membership is operator-controlled. Presentation capabilities are advisory only.

## Product boundaries

- §7 PLANNING → READY requires “minimum setup”, not defined beyond valid fields.
  Clarification requested; do not invent readiness checks or assert full lifecycle
  completion while unresolved. Automatic transition criteria remain undefined.
- §7 permits authorized archived corrections but gives no correction scope or
  required reason. Preserve archive read-only until that operation is specified.
- §8 names default airport/timezone/display preferences but does not define
  allowed values, defaults or shared/personal effects. Preserve settings; defer
  editing until explicit product semantics. No generic JSON input.
- Gregorian year remains explicit; Hebrew-year mapping is not inferred.
- Future finance must preserve historical conversions when base currency changes.
  No Expense/Payment domain is implemented here. OPD-002/003 remain open.

## Acceptance matrix

Local: invalid dates/ranges/names, field round-trip, capability states, draft
preservation under Realtime and conflict, revoked access, archived read-only,
soft delete/restore, stale lifecycle action, event isolation and audit rollback.
Live: migrations/catalog/grants/advisors, real CAS rejection, outsider/anonymous
denial. Separate independent authenticated clients must exercise propagation,
open-draft conflict, actor audit, missed notifications/reconnect, revocation.
Physical Android: every new UI flow. iPhone/TestFlight: pending external gate.
Run Flutter analyze/test, PostgreSQL harness and Android debug build.

Do not declare complete from local tests or operator-set database claims.
Do not begin Person implementation until Event is demonstrably stable.

## Next domain: Person preparation

Follow §9/24/26 and AC-06/08/10 through migration, RLS/RPC/audit, Dart, UI,
Realtime/reconnect, stale-write/isolation and device verification. Event-scoped;
nullable passport fields/expiry; duplicate warning only, never automatic merge.
Before storing passports define purpose/minimum fields, access, retention,
audit redaction and separate detail payloads. No passports in the Event cache,
ordinary list/realtime payloads, logs or error bodies. No Person table is added
by this card. Domain order follows the owner’s dependency sequence, not a dashboard.
