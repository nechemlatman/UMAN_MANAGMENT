# UMAN EVENT MANAGER — PRODUCT DELIVERY MODE

**Status:** Active operating model  
**Effective:** 2026-09-29

## Purpose

The project has completed enough infrastructure and vertical-slice foundation to shift from architecture-heavy construction to product delivery.

The goal is now to put a usable product in the owner's hands, gather feedback from real phone usage, and iterate in short, safe cycles.

This mode does **not** weaken correctness, security, data integrity, or testing. It removes repeated work that no longer improves those qualities.

## Primary success measure

> What can the owner do in the app today that was not usable before?

Secondary measures:
- time from request to usable phone result;
- size and clarity of each change;
- regression rate;
- repeated context/review work per change.

Documentation volume, full-repository rereads, and repeated proof of settled architecture are not progress metrics.

## Current milestone — Usable Beta 0.1

Do not start another broad vertical slice before this milestone unless the owner explicitly changes priority.

Existing working domains:
- Events/Auth
- People
- Flights
- Transport: Drivers, Vehicles, Trips
- Accommodation

Beta 0.1 productization objectives:
- coherent navigation among implemented modules;
- no misleading dead/placeholder destinations in the normal user path;
- basic supported create/edit/delete-or-archive/restore flows are discoverable;
- phone layouts are usable in Hebrew RTL and English LTR where localization currently supports them;
- obvious loading, empty and error states;
- visual work stays within the approved design system;
- realistic end-to-end owner walkthrough on Android;
- produce/install a fresh Android build for owner use.

Do not add Tasks, Apartment Issues, Finance, Control Center rules, or another major domain merely to make Beta 0.1 look complete.

## Normal delivery loop

**USE → NOTICE → DEFINE SMALL CHANGE → IMPLEMENT → PROPORTIONAL VERIFY → USE AGAIN**

Normal tasks should be understandable from the task instruction and local code.

Examples:
- improve passenger-selection UX;
- expose remaining vehicle capacity already derivable from existing data;
- adjust list information hierarchy;
- fix a phone layout problem;
- make an existing restore action discoverable.

These do not require rereading the Master Spec or running the full project gate unless the actual blast radius requires it.

## Scope sizing

Prefer one coherent outcome per task.

Split work when a request mixes:
- schema/security changes with visual work;
- unrelated modules;
- architecture refactoring with product behavior;
- multiple independently releasable outcomes.

Do not split merely to create process overhead.

## Architecture policy

Existing architecture is a paved road.

Agents should:
- reuse nearest working patterns;
- extend existing abstractions only when needed;
- make the smallest coherent change;
- raise a blocker only for a real contradiction or safety/data-integrity risk.

Agents should not:
- reopen settled architecture routinely;
- introduce a second pattern for the same job without necessity;
- perform broad refactors because a local task reveals stylistic preferences;
- create speculative frameworks for future features.

## Documentation policy

Live documents must stay short.

- `AGENT_CONTEXT.md`: minimal recurring context.
- `ACTIVE_WORK.md`: active tasks only.
- `STATUS.md`: current verified state, next milestone, meaningful open gates.
- task instruction/workcard: the specific job.
- detailed historical evidence belongs in task workcards, Git history, CI, or `docs/history/`.

Do not copy long verification narratives into multiple live files.

## Review policy

Independent inspection is risk-based.

Require or strongly prefer it for:
- database migrations/schema constraints;
- RLS/Auth/security;
- synchronization/realtime shared behavior;
- destructive/irreversible data changes;
- broad shared architecture;
- milestone/release integration.

For ordinary low/medium-risk UI/product changes, targeted tests plus clean self-review are normally sufficient.

## Release rhythm

Produce a usable Android build at meaningful product milestones and whenever the owner needs to validate a batch of UX changes.

Do not rebuild/distribute an APK after every trivial text/style edit unless requested.

Full-system regression belongs at milestone/release boundaries or when the changed blast radius warrants it.

## After Beta 0.1

Owner usage feedback has first priority.

Absent a different owner priority, likely sequence:
1. UX/usability corrections discovered on device;
2. Tasks + Apartment Issues;
3. Finance;
4. Control Center / Dashboard + Unresolved Items after enough real domains feed them;
5. universal search, snapshots/sharing and refinements.

This is planning direction, not permission to implement future modules automatically.
