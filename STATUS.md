# UMAN EVENT MANAGER — PROJECT STATUS

**Last reconciled:** 2026-09-29
**Operating mode:** Product Delivery Mode
**Verified main baseline:** ACC-01 integrated; latest verified integration evidence preserved in Git/CI and `docs/history/STATUS_2026-09-29_PRE_PRODUCT_DELIVERY.md`.

## Current verified product state

| Area | State |
|---|---|
| Event/Auth foundation | Implemented and verified |
| People | Implemented and integrated |
| Flights + passengers | Implemented and integrated |
| Drivers + Vehicles | Implemented and integrated |
| Ground Transport Trips + passengers | Implemented and integrated |
| Accommodation | Implemented and integrated |
| Control Center / Dashboard | Placeholder only |
| Tasks | Placeholder only |
| Apartment Issues | Placeholder only |
| Finance | Placeholder only |
| Unresolved Items | Placeholder only |

Cloud foundation already in use includes Supabase/PostgreSQL canonical persistence, authenticated multi-user membership, event isolation, RLS/authorized writes, CAS/version checks, audit, realtime invalidation and reconciliation.

## Current milestone

### Usable Beta 0.1

Before another broad domain slice, make the already-implemented product coherent enough for real owner use on Android.

Focus:
- coherent navigation across implemented modules;
- remove or hide misleading dead destinations from the normal path;
- ensure existing CRUD/archive/restore flows are discoverable;
- improve phone usability without redesigning settled architecture;
- preserve approved visual system and RTL/LTR direction;
- perform a realistic end-to-end owner walkthrough;
- produce a fresh Android build for owner feedback.

Detailed operating rules: `PRODUCT_DELIVERY_MODE.md`.

## Verification policy

Use `TEST_MATRIX.md`.

Routine low-risk work does not automatically require full Flutter + full DB + staging + APK + independent inspection. Verification expands with blast radius and risk. Full-system regression is reserved for shared/high-risk changes and milestone/release gates.

## Meaningful open acceptance gates

These remain release/milestone concerns and must not be falsely claimed as complete:
- two independent authenticated staging clients for realtime/concurrent-save acceptance;
- physical Android owner acceptance for the Beta milestone;
- macOS/Xcode + physical iPhone + TestFlight runtime acceptance;
- remaining operator backup/restore/Auth-hardening acceptance where applicable.

These gates do not block unrelated low-risk product iteration.

## Next work

TASK-FORM-01 is **REVIEW — IMPLEMENTED / VERIFIED / READY FOR INDEPENDENT REVIEW**.
Event name-only drafts, People calendar fields, Flight DRAFT and Trip PLANNED
nullable route/schedule are implemented on `codex/form-01-draft-friendly-legacy`.
Operational completeness and passenger relational identity remain strict. Shared
pickers preserve null/cancel/clear and explicit UTC-offset conversion.

Verified: 161 Flutter tests, 642 PostgreSQL/PGlite checks including upgrade/audit
preservation, clean analyzer/33-file formatter/diff, configured Android debug APK.
Staging has 13 aligned migrations including `20260928214807_legacy_draft_forms.sql`;
hosted rollback probe passed with no permanent data. No self-merge or independent
approval claimed. Review: [PR #4](https://github.com/nechemlatman/UMAN_MANAGMENT/pull/4).
Detailed rules/rollout evidence: `docs/workcards/TASK-FORM-01.md`.
Drivers/Vehicles remain a bounded follow-up; ACC-01's historical inventory is retained.
No Tasks/Issues or Beta implementation started in this task.

The next implementation assignment should target **Usable Beta 0.1 productization**, not another broad vertical slice, unless the owner explicitly changes priority.

## Historical detail

Detailed pre-transition verification evidence is preserved at:
`docs/history/STATUS_2026-09-29_PRE_PRODUCT_DELIVERY.md`

Completed feature details remain in their workcards and Git history.
