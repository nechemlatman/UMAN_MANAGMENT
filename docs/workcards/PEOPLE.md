# People vertical slice

Opened 2026-09-20; implemented and staging-tested, external acceptance pending.
Master §§9, 21, 24, 26–30, 34;
AC-06/08/10; workbook V-03/06/19. Latest owner instruction authorizes People
before the remaining Event product/device gates; those gates remain unresolved.
No visual redesign or other business module is authorized.

Inspection: clean starting tree at 0636eb4; live migration history matches the
three source migrations. Existing Auth, Event Cubit/repository, CAS, audit,
cache and Realtime are implemented. No People schema or active domain shell exists.
Master §34 explicitly requires only first_name; §9 lists last_name/phone as
strings. Keep these non-null but allow empty values, preserving partial records
as required by §35. No new required travel-information policy is invented.

Plan: active event shell; paged People list/search; protected details; create,
edit, soft-delete/restore; membership authorization, CAS and atomic audit;
event-filtered Realtime invalidation, polling and foreground reconciliation.
No hard deletion, cascade, rules engine, sharing/import or logistics implementation.

Privacy review: only explicit event administrators can read/write details.
Passport fields live in a private, non-published extension of Person, accessed
through authorized detail RPCs. No passport values in ordinary lists, Realtime,
local storage, diagnostics or audit snapshots. Audit retains changed field names
for protected details, actor/version and ordinary record snapshots. Existing
managed storage encryption is used; no custom cryptography. Privileged operators
and backups remain trusted operational boundaries.
Owner approved preserving passport data until an explicit removal policy is
defined. Soft deletion preserves all fields for restore; no invented purge timer.
Only collect the specified optional passport fields when operationally needed.

Owner requested available automated verification; physical/two-session acceptance
must remain pending. Tests must distinguish local PostgreSQL role simulation,
hosted rollback tests, SDK transport tests and actual independent-session Realtime.

Acceptance: mapping/validation; list/add/details/edit/search/delete/restore;
unauthorized and cross-event denial; CAS/audit/rollback/idempotency; reconnect,
duplicate invalidations, disposal and retained drafts; existing regressions;
Flutter analyze/test, SQL harness, Android build.

## Executed implementation and verification

The original Codex implementation added the pure-Dart Person input/summary/detail
models, data source and repository, People Cubit, route-scoped Event shell,
paged list/search, all specified fields, detail/editor, duplicate warning,
soft-delete/restore confirmations and protected detail storage. Existing Auth,
Event RPCs, cache, theme and lifecycle decisions were retained. No Flights or
other business module was implemented by this task.

Migration `20260920063325_people_vertical_slice.sql` was created with the pinned
CLI, locally tested, dry-run reviewed, then pushed to linked project
`rrgzalzaaprdsmwihqxa`. Remote history confirmed four migrations at that point.
The public People table has SELECT-only authenticated privileges, membership
RLS and no client DML. Private details have RLS/default-deny, no client schema
privilege and no publication. Restricted RPCs authorize every read/write; writes
use expected versions and transactional attributed audit. Event/member locks
serialize with archive/deletion/revocation; IDs are server-generated UUIDv4.
No cascade or hard-delete API was introduced.

Verified before concurrent Flights integration:

- `flutter analyze --no-pub`: no issues.
- `flutter test --no-pub`: 58 tests passed, including existing Auth/Event tests.
- `node tools/db-test/verify.mjs`: 158 actual PostgreSQL/PGlite checks passed.
- `flutter build apk --debug --no-pub --dart-define-from-file=config.local.json`:
  passed, configured debug APK built in 29.1 seconds.
- Hosted `remote_people.sql` executed inside an explicit rollback transaction
  under the approved owner claim: create/idempotency, bilingual search,
  cross-event read denial, stale update, direct-DML/private access denial,
  delete/restore preservation, redacted audit, archive and outsider/anonymous
  denial all passed. These are operator-set role tests, not real Auth sessions.
- Post-probe catalog inspection: People/private row counts 0/0; existing Events,
  memberships and audit counts remained 2/3/10. No synthetic data was committed.
- Confirmed empty function search paths, restricted execute grants, membership
  SELECT policy and publication of public.people only.

SDK tests use a local HTTP endpoint with the actual Supabase Dart client to
inspect event scope, pagination, expected-version/request parameters, mappings
and safe error translation. They do not establish hosted PostgREST/Auth or
websocket delivery. Controller tests cover duplicate notifications, reconnect,
in-flight invalidation, disposal and cross-event rejection. Widget tests cover
navigation/disposal, validation, retained conflicting drafts and revoked access.

Security advisors: five new intentionally authenticated SECURITY DEFINER RPCs
(13 total including existing Event functions), private-table no-policy INFO
(intentional default-deny), existing leaked-password-protection warning, and
seven unused FK indexes. No uncovered-FK warning; no Auth settings changed.
References: [restricted RPC advisor](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable),
[default-deny policy advisor](https://supabase.com/docs/guides/database/database-linter?lint=0008_rls_enabled_no_policy).

## Concurrent checkout changes discovered on continuation

On owner instruction “continue”, Git HEAD had advanced from `0636eb4` to
`4f0c7cb`. Antigravity had integrated the People work, and Gemini owned active
Flights work in the same checkout. New `STATUS.md`/`ACTIVE_WORK.md` and the
multi-agent protocol were read. This task did not implement, revert or deploy
the concurrent Flights changes.

Two additional People regressions verify write-authorization denial and
revocation during an in-flight read. The latest combined run reached 58 passing
tests but failed loading Flights tests and the shell widget test because
`FakeFlightsRepository.listFlights` lacks the new `query` parameter; a Flights
passenger fixture also fails its updated codec. Analysis reported that override
error and six Flights lint notices. Thus the earlier clean 58-test/build result
does NOT certify the current combined checkout. Keep these findings with the
Flights owner; do not weaken or remove tests.

Final scoped run: `flutter test --no-pub test/people_controller_test.dart
test/people_domain_test.dart test/people_repository_test.dart` passed **19/19**.
This includes both newly added authorization-race regressions. The shell widget
test remains in the full suite; it was not removed to hide the Flights fake
compile error. The two new regression tests and final formatting/documentation
are left uncommitted for integration.

## Limitations and stop point

Owner explicitly accepted leaving independent-session/two-device verification
pending. People websocket propagation, simultaneous-client CAS, actual login
regression and new physical Android walkthrough have not been executed here.
iOS/Xcode/iPhone/TestFlight remain external gates. Realtime publication/filtering
and client recovery are implemented and locally tested, not live two-client proven.

People summaries are session-memory read resilience only, timestamped and expired
after 24 hours on failed reconciliation; no persistent People cache exists.
Protected details are cleared on read failures and never persisted on device.
Search is event-scoped and paged in 50-row windows; full benchmark/device latency,
diacritic folding and full bilingual UI remain unverified/not implemented.
Duplicate warnings use normalized phone and exact/prefix name candidates, with
explicit manager override; no automatic merge. Custom fields preserve existing
structured values, with simple text additions/removal in this slice.
Retention remains preserve-until-approved-removal per owner; no automated purge.

Next: Flights owner restores the shared build/test gate; verify the People UI on
the phone and later two independent authorized sessions, including create/update/
delete/restore, open-draft conflict, reconnect and cross-event filtering.
This task stops at People and does not certify full production acceptance.
