# UMAN EVENT MANAGER — PROJECT STATUS

**Last reconciled:** 2026-09-28
**Current upstream main:** `17ebbffa95efd41cc628017e33bb01ac4a017542` (only design-agent documentation added after verified TRN-02 merge)
**Implementation branch:** `codex/acc-01-vertical-slice`
**Owner:** Codex Lead Builder (sole TASK-ACC-01 implementation owner)

## Current state

| Task | State | Verified reality |
|---|---|---|
| Event foundation | VERIFIED locally and staging | Auth, membership, RLS, CAS, audit, lifecycle and restore remain intact. |
| TASK-PEOPLE-01 | DONE | Integrated and deployed; regression gate remains green. |
| TASK-FLT-01 | DONE | Integrated/deployed, including forward RPC privilege hardening. |
| TASK-TRN-01 | DONE | Reviewed foundation repairs integrated and deployed. |
| TASK-TRN-02 | DONE | PR #2 independently APPROVED and merged unchanged; merged main verified locally and by CI. |
| TASK-ACC-01 | REVIEW — IMPLEMENTED / VERIFIED / READY FOR INDEPENDENT REVIEW | Complete hierarchy plus owner draft-form policy, shared localized calendars, forward migration and staging verification; independent review/integration pending. |

## TRN-02 integration evidence

Approved head `e86b81300f19aa65afb2b9c9f5d7d1b7ca91c837` merged through PR #2
as `ace677f16349c1034e4141daba3e35a1ca8519c9`. Approved head is an ancestor and
its tree matches merged main. Working tree was clean before post-merge checks.
Main passed clean analyzer, 111 Flutter tests and 370 DB checks; GitHub
[Core Verification 36306112850](https://github.com/nechemlatman/UMAN_MANAGMENT/actions/runs/36306112850)
passed on that merge. No accepted findings were reopened.

## Accommodation slice

Owner policy revision: Apartment name-only and Room name/number-only drafts;
unplaced/inactive SleepingPlace with no invented name/type; DRAFT assignments
with nullable person/place/date endpoints. Explicit activation checks operational
requirements. Historical assignment identity remains protected by server-only
`has_been_operational`. Drafts never occupy beds or generate overlap warnings.
Shared English/Hebrew date and range pickers preserve nulls, support Clear and
Cancel, and retain partial endpoints. Existing-slice conflicts and follow-ups are
recorded in TASK-ACC-01; unrelated Transport code is unchanged.

- Apartment → Room → SleepingPlace → AccommodationAssignment; all domain fields,
  exact decimal cost, CivilDate, codecs and restricted repository operations.
- Apartment list/search with occupancy for a chosen night; inline room/bed tree;
  editors, assignments, tombstones, restore and explicit reassignment workflow.
- `[start,end)` overlaps exclude cancelled/deleted assignments. Same-day turnover
  is valid. TEMPORARY participates. Manager override requires notes and never
  suppresses ACCOMMODATION_OVERLAP. No automatic source-data correction.
- New assignment preserves old history; previous dates/status change only through
  explicit edits. Parent deletion never cascades. Orphaned/inactive relationships
  remain visible with warnings. Revoked access clears canonical rows/hides drafts.
- Four same-event composite foreign keys, RLS, SELECT-only client grants,
  protected helper schema, 17 authorized RPCs with pinned search paths, CAS,
  idempotent creation and transactional audit. Event-scoped mutation serialization.
- One statement reads consistent hierarchy/advisories. Five event-filtered realtime
  dependencies, reconnect/foreground refresh, serialized reads, invalidations
  during reads, 20-second reconciliation and controller/repository disposal.
- No unrelated UI redesign, finance allocation or general rules-engine expansion.

## Staging and verification

Project `rrgzalzaaprdsmwihqxa`: twelve migrations match local history. Initial migration
`20260927082740_accommodation_vertical_slice.sql` created with pinned CLI 2.117.0,
verified locally, dry-run reviewed, then applied using `--skip-vault`. Earlier
applied migrations were not edited; no reset, seed or history repair.

Forward `20260928073059_accommodation_draft_forms.sql` applied after local tests,
target/history verification and dry-run. Both hosted rollback-only suites passed:
`remote_accommodation.sql` and `remote_accommodation_drafts.sql`. Upgrade checks
preserve preexisting rows, versions and audit verbatim while adding conservative
history protection. Catalog and anonymous HTTPS checks remain passing.

- Analyzer clean; 150 Flutter tests passed; 599 PostgreSQL/PGlite checks passed.
- Changed Dart formatting and diff checks clean; configured Android debug APK built.
- RTL/LTR, light/dark, hierarchy, overrides, date validation, stale drafts,
  foreground/realtime/reconciliation and disposal tests passed. Phone-sized RTL
  screenshots inspected; date range explicitly LTR inside the RTL layout.
- Hosted rollback-only `remote_accommodation.sql` passed: domain/date boundaries,
  overlap/lock/cancellation, CAS, idempotency, delete/restore, audit atomicity,
  history preservation, event isolation, outsider RLS and anonymous denial.
- `accommodation_catalog.sql` passed: four tables/composite FKs, constraints,
  RLS/grants/search paths, private schema, Realtime publication and no smoke residue.
- Real anonymous HTTPS probes for four tables and read RPC all returned HTTP 401.
- Advisors: 17 new intentional authenticated SECURITY DEFINER notices; explicit
  authorization/restricted grants verified. No new uncovered Accommodation FK
  indexes. Four existing FlightPassenger index notices and existing disabled
  leaked-password protection remain recorded in the environment ledger.
- [PR #3](https://github.com/nechemlatman/UMAN_MANAGMENT/pull/3) remains the independent-review PR. Earlier CI evidence applies to the original revision; the draft-policy revision has the local/hosted evidence above and its own CI run is recorded at handoff.

## Remaining gates

- TASK-ACC-01 independent review and integration; do not merge without review.
- Two independent authenticated staging clients: realtime/reconnect/concurrent
  saves and physical Android acceptance. SDK/rollback tests do not replace these.
- macOS/Xcode, physical iPhone, secure-storage runtime and TestFlight acceptance.
- Docker local service/reset verification; existing operator backup/restore and
  Auth hardening acceptance.

`PHASE1_PROGRESS.md` is historical. Current scope and evidence are in
`ACTIVE_WORK.md`, this file, and `docs/workcards/TASK-ACC-01.md`.
