# TASK-FORM-01 — Draft-Friendly Legacy Forms Conversion

Owner: Codex Lead Builder (sole implementation owner)
State: REVIEW — IMPLEMENTED / VERIFIED / READY FOR INDEPENDENT REVIEW
Branch: `codex/form-01-draft-friendly-legacy`
Verified initial base: `ffea9be019fbde31982af6754c90c3e79583089c`

## Objective and scope

Convert Event, People dates, Flights and Trips to the authoritative project-wide
Draft-Friendly / Progressive Completion policy. Follow ACC-01's bounded inventory,
Master spec Sections 5/7/9/10/13, Technical v1.2, ADR-001 and existing visual tokens.
No Accommodation changes except unavoidable consumers of nullable Event metadata;
no Drivers/Vehicles conversion, Tasks/Issues, Finance, auth redesign or global UI work.

## Contracts and boundaries

- Event: name-only Save; year/date endpoints/currency unknown as null. Preserve
  lifecycle graph and the unresolved PLANNING→READY gate. Operational transitions
  TRAVEL/IN_UMAN/DEPARTURE need complete Event metadata; CLOSEOUT/archive remain
  available without a new completeness requirement.
- People: first-name minimum unchanged; replace birth/passport manual dates only.
- Flight: new DRAFT status, nullable airline/number/airports/schedule; explicit
  operational status requires route, identity and ordered schedule. CANCELLED and
  UNKNOWN may retain partial information. Never infer actual times or statuses.
- Trip: PLANNED is the existing draft state; nullable route/schedule. Explicit
  CONFIRMED/IN_PROGRESS/COMPLETED requires route and ordered schedule. CANCELLED
  may remain incomplete. Existing advisories/assignments/capacity remain intact.
- FlightPassenger and TripPassenger retain both endpoints as relational identity;
  parent drafts save without passengers. No meaningless orphan join records.
- Shared date/time picker: explicit fixed UTC offset chosen by manager, display
  conversion before confirmation, canonical UTC persistence. No hidden device-zone
  or DST interpretation, fabricated midnight, current time, or default schedule.

## Shared resources and verification

Event/Flight/Trip typed contracts, codecs/RPCs, forward-only migration and shared
date picker infrastructure. Preserve same-event FKs, RLS, authorization, CAS,
transactional audit, lifecycle/realtime/disposal. Existing source/audit unchanged.
Test minimal saves, null round-trips, operational boundaries, picker cancel/clear,
UTC conversion, migration upgrades and all security/concurrency regressions.
Run formatter, analyzer, full Flutter/PGlite suites, diff check, configured Android
build and controlled staging history/dry-run/rollback verification. Push PR and stop
at independent review; do not merge or start Tasks & Apartment Issues.

## Implementation and verification evidence

- Forward migration: `20260928214807_legacy_draft_forms.sql`; no applied files edited.
  Event drops four NOT NULL constraints; Flight drops six plus empty-string defaults,
  adds DRAFT; Trip drops route/schedule NOT NULL and validates operational states.
  Existing type/length/ordered-pair constraints, enums, RLS, composite FKs, CAS,
  authorization and transactional audit persist. Existing source/audit preserved
  exactly by an isolated upgrade test, including incomplete legacy SCHEDULED flights.
- Domain policy and status getters centralize Save/operational checks. Nullable
  typed inputs/codecs remain separate from presentation; no placeholder domain data.
- Shared civil controls reused for Event range and People dates; shared timestamp
  dialog used for all four scheduled/actual Flight and Trip timestamps. English/
  Hebrew localized display, RTL/LTR, cancel/clear, explicit offset preview, and
  unchanged sub-minute timestamp precision tested. No raw ISO typing required.
- Existing Event read/cache, unnamed Flight/Trip display and Trip flight selector
  tolerate null. Accommodation occupancy asks for a night when Event has none;
  no inferred date or broader Accommodation change. Flight edit preserves actual
  timestamps/delay metadata and explicit conflict reopening retains draft safety.
- Save minimum: Event name; Person first name; Flight direction + DRAFT state;
  Trip direction + PLANNED state. UI defaults the existing direction/status choices,
  not route/date/identity metadata. Passenger endpoints remain required.
- Operational actions: Event TRAVEL/IN_UMAN/DEPARTURE need year/dates/currency;
  Flight SCHEDULED/DELAYED/DIVERTED/LANDED need airline/number/airports/schedule;
  Trip CONFIRMED/IN_PROGRESS/COMPLETED need route/schedule. Existing provided-value
  validation always applies. No automatic status, scheduling or reassignment.

Commands and actual results:
- `dart format --output=none --set-exit-if-changed <33 affected Dart files>`: 0 changed.
- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 161 passed, including retained lifecycle/disposal/security
  regressions and new policy/picker/legacy-editor tests.
- `node tools/db-test/verify.mjs`: 642 checks passed; upgrade preserves Event/member/
  People/Flight/Trip/audit rows, draft CAS/RLS/anon/outsider/audit rollback plus old
  same-event/capacity/advisory/delete/restore tests retained.
- `git diff --check`: clean.
- `flutter build apk --debug --no-pub --dart-define-from-file=config.local.json`:
  built `build/app/outputs/flutter-apk/app-debug.apk`.

Staging: linked project `rrgzalzaaprdsmwihqxa`, pinned CLI 2.117.0. History showed
12 aligned + one pending; dry-run only that migration; first push connection timed
out with history unchanged, verified read-only before successful retry. 13 versions
now aligned. `db query --linked --file supabase/tests/remote_legacy_drafts.sql`
passed, transaction rolled back; catalog query confirms nullable fields, anon RPC
EXECUTE false and zero probe Event rows. No reset, history repair or permanent data.

Remaining gates: independent inspection/approval and later integration; coordinated
updated-client rollout for nullable drafts; two independent authenticated physical
clients, physical Android/iPhone, macOS/Xcode/TestFlight/secure-storage runtime,
operator backup/restore and Auth operational acceptance. These are not claimed.
Drivers/Vehicles remain a later bounded follow-up; ACC-01 inventory is retained.
No unrelated `claude/ui-design-system` work merged; no Tasks/Issues started.

Hosted advisors completed with zero ERROR findings: 58 intentional authenticated
SECURITY DEFINER warnings (existing restricted API surface), existing leaked-password
protection warning, and INFO notices for four existing FlightPassenger FK indexes,
33 unused indexes and private People RLS without client policies. No new functions,
indexes or RLS policies were introduced by FORM-01. Final dry-run reports up to date.

Final fetch found documentation-only main advancement to
`f413741a4944c0bc367c7b5fef6ae728e1c092b5` (Product Delivery Mode). The branch is
rebased onto that review base; no implementation changes came from main. Updated
live STATUS/ACTIVE_WORK use its concise format and retain the new historical
archives. FORM-01 is Level 3 and retains the owner's full verification/review gate.
No Beta work started. Original build base remains recorded above.

Independent-review handoff: [PR #4](https://github.com/nechemlatman/UMAN_MANAGMENT/pull/4).
Implementation commit `a4c6e0b6de8fa4a76f3ce54efee77f53ae00bf4d`; subsequent handoff
commit is documentation only. Review base `f413741a4944c0bc367c7b5fef6ae728e1c092b5`.
PR is open and unmerged. No inspector verdict is claimed.
