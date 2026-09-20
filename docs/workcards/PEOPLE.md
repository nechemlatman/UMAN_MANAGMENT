# People vertical slice

Opened 2026-09-20; implementing. Master §§9, 21, 24, 26–30, 34;
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
Flutter analyze/test, SQL harness, Android build. Record executed evidence below.
