# TASK-TASK-01 - Tasks MVP

Status: PARTIAL - initial lifecycle decision pending. Owner: Codex implementation owner.
Branch: codex/task-01-vertical-slice. Base: exact Beta commit 2b1d43d.
Dependent on PR #5; Beta checkout and PR remain unchanged.

Scope: Master v2.6 sections 15.1 and entity 13; typed Task, event-scoped canonical
reads, explicit lifecycle, nullable metadata, CAS, audit, soft delete/restore,
realtime reconciliation, phone UI and minimal Event navigation integration.
Due local time is a display conversion of canonical UTC, not separate source data.
Overdue is a module-local derived indicator; global rules/alerts are out of scope.

Open clarification: initial status on title-only Save (unset vs explicit NEW).
Priority, assignee, due date, description and notes stay nullable.

Verification: Level 3, full client regression and DB harness, configured Android
build. No shared staging deployment while the owner tests Beta without a separate
rollout decision. Independent review required before integration.

## Current handoff

Implementation prepared: nullable metadata, separate lifecycle RPCs with server
terminal timestamps, explicit reopening, local overdue/open filters, full
soft-delete/restore, assignee history, idempotent creation, audited CAS writes,
RLS/event isolation and SDK realtime invalidation with bounded reconciliation.
Migration: `20260930083123_tasks_vertical_slice.sql` (local only).

Initial-state decision remains consequential: section 15.1 starts lifecycle at
NEW but supplies no default; assignment section 6 forbids inventing status for
Save. The migration currently has no status default, clearly marked provisional.
The optional EventShell path is tested; `main.dart` production factory is
intentionally not activated until the policy is resolved. This is PARTIAL, not
ready to merge or deploy. No hosted database or Beta APK was changed.

Executed: 677 local PostgreSQL WASM checks; targeted domain/controller/SDK tests;
phone widget workflows at 360x640 in RTL/LTR and light/dark; conflict preservation,
error recovery, optional date/clock cancellation and navigation disposal. Analyzer is clean; full Flutter regression passes (182 tests); configured Android
debug build passes; changed/new-file credential scan and diff checks pass. Runtime two-user
staging, independent review, physical Android and iOS/TestFlight are outstanding.

Owner decision: title-only creation keeps status unset until explicitly chosen,
or creation explicitly establishes NEW and displays that in the form. Priority,
assignee, description, notes and due date remain nullable either way.

After this decision: finalize initial-state invariant and tests, wire production
factory, repeat relevant verification, and continue review of this dependent PR.
Recommended next bounded domain after Tasks acceptance: Apartment Issues (15.2).
