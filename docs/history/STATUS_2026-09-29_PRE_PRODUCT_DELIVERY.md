# Historical snapshot — STATUS before Product Delivery Mode

Historical only. Not required reading for normal tasks.

# UMAN EVENT MANAGER — PROJECT STATUS

**Last reconciled:** 2026-09-29
**Verified main integration commit:** `efeac1304453515bb4306add78c468d9b67f16da` (PR #3 merge; subsequent closure commit changes documentation only)
**Current branch:** `main`
**Integration owner:** Codex Lead Builder; ACC-01 closed, no next feature started

## Current state

| Task | State | Verified reality |
|---|---|---|
| Event foundation | VERIFIED locally and staging | Auth, membership, RLS, CAS, audit, lifecycle and restore remain intact. |
| TASK-PEOPLE-01 | DONE | Integrated and deployed; regression gate remains green. |
| TASK-FLT-01 | DONE | Integrated/deployed, including forward RPC privilege hardening. |
| TASK-TRN-01 | DONE | Reviewed foundation repairs integrated and deployed. |
| TASK-TRN-02 | DONE | PR #2 independently APPROVED and merged unchanged; merged main verified locally and by CI. |
| TASK-ACC-01 | DONE | PR #3 independently APPROVED, merged unchanged, and verified on actual main. External acceptance gates remain separate. |

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
- [PR #3](https://github.com/nechemlatman/UMAN_MANAGMENT/pull/3) independently APPROVED and merged. Post-merge evidence is recorded below; earlier hosted verification remains historical evidence, not a claim of repeated smoke tests during integration.

## Remaining gates

- Two independent authenticated staging clients: realtime/reconnect/concurrent
  saves and physical Android acceptance. SDK/rollback tests do not replace these.
- macOS/Xcode, physical iPhone, secure-storage runtime and TestFlight acceptance.
- Docker local service/reset verification; existing operator backup/restore and
  Auth hardening acceptance.

`PHASE1_PROGRESS.md` is historical. Current scope and evidence are in
`ACTIVE_WORK.md`, this file, and `docs/workcards/TASK-ACC-01.md`.

## ACC-01 final integration — 2026-09-29

The owner supplied independent inspector verdict APPROVE with no findings,
security vulnerabilities or scope violations. Immediately before merge, PR #3
was open/mergeable at exactly `c6c6a50a920e07a6454bfe5de1df14f533821a61`;
main remained at reviewed base `17ebbffa95efd41cc628017e33bb01ac4a017542`, with a
clean working tree. GitHub merged using the established merge-commit method as
`efeac1304453515bb4306add78c468d9b67f16da`. Approved head is an ancestor; the
merged tree is byte-for-byte identical to the approved tree. No unrelated branch
was merged, including `claude/ui-design-system`.

Post-merge checks on actual main: formatter checked 18 relevant Dart files with
zero changes; analyzer no issues; full Flutter suite **150 passed**; PostgreSQL/
PGlite **599 passed**; `git diff --check` clean; configured Android debug APK built.
[Main Core Verification 36486898094](https://github.com/nechemlatman/UMAN_MANAGMENT/actions/runs/36486898094)
passed on the merge commit. No implementation repairs were required.

Staging `rrgzalzaaprdsmwihqxa`: twelve local/remote versions match, including
`20260927082740_accommodation_vertical_slice.sql` and
`20260928073059_accommodation_draft_forms.sql`. An initial connection timeout
resolved on retry; migration list and read-only history comparison succeeded.
Final dry-run: `upToDate=true`, no pending migrations. No remote mutations,
reapplications, resets, history edits or smoke data were necessary.

**Draft-Friendly / Progressive Completion remains a project-wide principle**:
permissive Save is separate from operational/action validation; retain nullable
drafts, minimal natural identity, calendar/date-picker UX, and no invented dates
or relationships. Master spec Section 5 and Technical v1.2 remain authoritative.
The bounded legacy-form conversion inventory in TASK-ACC-01 remains outstanding;
no claim is made that every older screen is converted. External acceptance gates
above remain open. ACC-01 is DONE as an integrated software slice.
