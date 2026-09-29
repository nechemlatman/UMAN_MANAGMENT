# UMAN EVENT MANAGER — PROJECT STATUS

**Last reconciled:** 2026-09-30
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

`TASK-BETA-01` is implemented on `codex/beta-01-productization`, awaiting review
and owner phone acceptance. Operational navigation now exposes implemented modules;
contained keyboard, empty/error-state and action-discovery fixes are included.
Local gate: clean analyzer, 156 Flutter tests, 599 DB checks, configured debug APK.
CI is pending. See `docs/workcards/TASK-BETA-01.md` for the short walkthrough and
remaining gates. Main has not been changed by this task.

## Historical detail

Detailed pre-transition verification evidence is preserved at:
`docs/history/STATUS_2026-09-29_PRE_PRODUCT_DELIVERY.md`

Completed feature details remain in their workcards and Git history.
