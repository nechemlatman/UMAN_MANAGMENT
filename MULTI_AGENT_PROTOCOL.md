# UMAN EVENT MANAGER — MULTI-AGENT DEVELOPMENT PROTOCOL

**Version:** 1.1  
**Status:** Mandatory operational protocol  
**Applies to:** Every AI coding agent working on this repository

## 1. Purpose

UMAN EVENT MANAGER may be developed by multiple interchangeable AI coding agents. No agent has a permanent specialty or permanent ownership of an area.

The purpose of this protocol is to allow agents to start, stop, review, replace one another, and work in parallel without losing context, duplicating work, creating architectural drift, or damaging shared resources.

> **Core rule:** The repository owns the project. The task owns the role. The agent is replaceable.

## 2. Source of Truth and Reading Order

The current repository is authoritative. Chat history is supporting context only.

Before making any change, every agent must read and inspect, in this order:

1. `STATUS.md`
2. `MULTI_AGENT_PROTOCOL.md`
3. `ACTIVE_WORK.md`
4. The authoritative specification(s) relevant to the task
5. The current Git state, relevant code, migrations, tests, and recent relevant commits

If documentation, code, migrations, or current status disagree, do not silently choose one. Identify the discrepancy and resolve or report it before consequential changes.

## 3. Agents Are Interchangeable

Any agent may work on architecture, Flutter, Supabase, database, synchronization, UI, visual design, testing, documentation, or another area when assigned.

Important decisions must not exist only in an AI conversation. Anything required for another agent to continue safely must be represented in the repository through code, specifications, status, task state, commits, or handoff notes.

A new agent must continue from the actual repository state, not recreate work from memory.

## 4. Task Ownership

Every active implementation task has exactly one current owner.

Ownership belongs to the **task**, not permanently to the agent. Ownership may be transferred from one agent to another.

Other agents may review or investigate the same area, but they must not independently modify the same active task unless ownership has been explicitly transferred or a coordinated parallel plan exists.

When overlap is uncertain: **stop before editing**.

## 5. `ACTIVE_WORK.md` — Coordination Ledger

`ACTIVE_WORK.md` is the live coordination ledger for concurrent work.

Before implementation begins, the task must appear there with:

- Task ID and objective
- Current owner
- Branch/worktree
- Scope
- Status
- Shared resources / dependencies
- Last handoff or note

Allowed statuses:

`PLANNED → ACTIVE → REVIEW → CHANGES_REQUIRED → READY_TO_MERGE → DONE`

`BLOCKED` may be used from any active stage.

`ACTIVE_WORK.md` coordinates current work. `STATUS.md` records the broader verified state of the project. Neither replaces the other.

## 6. Task Brief Required

Every implementation assignment must have a concise Task Brief containing:

- **Objective** — required outcome
- **Scope** — what may be changed
- **Out of Scope** — what must not be changed
- **Relevant Specifications** — governing documents/sections
- **Dependencies / Shared Resources** — areas that may interact with other work
- **Acceptance Criteria** — observable completion conditions
- **Verification** — checks expected before handoff

Do not expand scope because nearby cleanup, refactoring, redesign, or optimization looks useful. Record such opportunities separately.

## 7. Git and Work Isolation

Before editing, inspect the current branch and Git status.

For substantial independent work:

- use a dedicated branch;
- use a separate worktree when simultaneous local work requires physical isolation;
- keep commits focused and understandable;
- do not mix unrelated cleanup into task commits;
- do not overwrite, reset, discard, force-push, or destroy another agent's work to resolve a conflict;
- do not merge significant work until the integration gate is satisfied.

Git isolation does **not** isolate external shared resources such as Supabase.

## 8. Shared-Resource Safety

The following are high-impact shared resources:

- Supabase schema and migrations
- RLS and authentication
- Realtime/synchronization contracts
- central routing/navigation
- core domain contracts
- shared dependency/platform configuration
- secrets/configuration
- other shared infrastructure

Only one active implementation task should modify the same high-impact shared resource at a time unless a coordinated plan explicitly allows otherwise.

Never:

- expose passwords, service-role keys, tokens, or secrets in source, prompts, logs, or commits;
- rewrite migration history that may already have been applied;
- weaken security controls merely to make development easier;
- perform destructive or irreversible shared-resource operations without explicit human approval.

## 9. Architecture and Design Boundaries

Preserve the project's separation between:

- **Logic** — state, data, business rules, behavior, synchronization
- **Structure** — screen composition, hierarchy, navigation, and content placement
- **Visual Design** — colors, typography, spacing, surfaces, imagery, decoration, styling

A Visual Design task must not silently alter Logic or Structure.

Visual implementation should remain centralized and replaceable so visual redesign does not require rewriting application behavior.

## 10. Verification

Written code is not verified work.

Before reporting completion, perform all relevant available checks, such as:

- formatting/static analysis
- automated tests
- build validation
- migration/database validation
- runtime validation
- synchronization/realtime validation
- regression checks for affected behavior

Reports must distinguish:

- **VERIFIED** — actually checked successfully
- **IMPLEMENTED BUT UNVERIFIED** — implemented, but one or more required checks could not be completed

Never report an assumption as a successful verification.

### Lightweight CI gate

The repository contains a lightweight GitHub Actions verification workflow for pushes and pull requests targeting `main`. When available, its core checks should be green before significant work is treated as integrated. CI complements rather than replaces task-specific, live Supabase, Android/iOS, multi-account, and physical-device verification. Do not add release pipelines, mandatory PR bureaucracy, or additional CI complexity unless the project owner explicitly approves it.

## 11. Independent Review

Significant changes should be reviewed by an agent other than the primary implementer whenever practical.

Review should inspect:

- compliance with authoritative specifications
- architecture and boundaries
- unintended scope expansion
- regressions
- data integrity
- security
- Supabase/shared-resource implications
- tests and verification evidence
- maintainability
- unnecessary complexity
- undocumented behavior

A reviewer reports findings. It must not silently rewrite or redesign the implementation unless explicitly assigned to fix it.

## 12. Takeover / Agent Replacement

An agent may be replaced at any time.

Before continuing an existing task, the incoming agent must:

1. Follow the mandatory reading order.
2. Inspect the task branch/worktree and Git status.
3. Inspect relevant diff, recent commits, code, tests, and migrations.
4. Read the previous handoff if available.
5. Determine what is complete, verified, incomplete, unverified, or blocked.
6. Update ownership in `ACTIVE_WORK.md`.
7. Continue within the existing task scope.

A takeover transfers responsibility; it does not authorize scope expansion.

## 13. Handoff and Interrupted Work

Whenever an agent stops — completed, blocked, interrupted, or approaching quota/tool limits — it must leave the work recoverable whenever possible.

The handoff must record:

- task and current status
- branch/worktree
- completed work
- material files/components changed
- verification performed and results
- incomplete or unverified work
- known risks/blockers
- next recommended action

If an agent stops without a handoff, the next agent must perform a recovery inspection from Git, code, tests, migrations, `STATUS.md`, and `ACTIVE_WORK.md` before editing. Never assume interrupted work is complete.

## 14. Integration Gate / Definition of Done

A task is not `DONE` merely because code was written.

Before significant work is integrated into the main development line, confirm:

- scope and acceptance criteria are satisfied;
- relevant verification was performed and recorded;
- independent review is complete when required;
- review findings are resolved or explicitly accepted;
- shared-resource changes are coordinated and safe;
- merge conflicts were resolved by understanding both changes, not by blindly choosing one side;
- `STATUS.md` and `ACTIVE_WORK.md` reflect the resulting state.

Only then mark the task `DONE`.

## 15. Mandatory Stop Conditions

Stop before editing or executing consequential operations when:

- another active task may modify the same code or shared resource;
- the requested change conflicts with an authoritative specification;
- a database/security operation may be destructive or irreversible;
- ownership or scope is unclear;
- resolving a conflict would require discarding another agent's work;
- the actual repository state cannot be reconciled with the task instructions.

Report the issue instead of improvising.

## 16. Standard Operating Flow

**READ → CHECK ACTIVE WORK → CLAIM/TAKE OVER → ISOLATE → IMPLEMENT → VERIFY → REVIEW → FIX IF NEEDED → READY TO MERGE → INTEGRATE → UPDATE STATUS/ACTIVE WORK → HANDOFF**

This protocol is provider-neutral. Codex, Antigravity, Android Studio agents, and future agents follow the same rules.
