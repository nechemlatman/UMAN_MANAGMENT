# UMAN EVENT MANAGER — MULTI-AGENT PROTOCOL

**Version:** 2.0  
**Mode:** Product Delivery  
**Purpose:** Prevent collisions and lost context without making every task expensive.

## Core rule

> The repository owns the project. The task owns the role. The agent is replaceable.

## Normal reading

For a normal task, read:
1. `AGENT_CONTEXT.md`
2. `ACTIVE_WORK.md`
3. the assigned task instruction/workcard
4. the relevant code/tests

Read broader specifications or history only when the task actually requires them.

## Ownership

- One implementation owner per active task.
- Register active implementation work in `ACTIVE_WORK.md`.
- Do not edit overlapping active work without coordination.
- Review/investigation may happen in parallel if it does not modify owned work.
- Ownership transfers by updating the active row after inspecting the current branch/diff.

## Task brief

A task needs a clear objective, scope and observable completion condition.

A separate workcard is useful for medium/high-risk or multi-step work. It is not mandatory bureaucracy for every small UI/product correction when the assignment itself is sufficiently precise.

## Git isolation

Use a dedicated branch for substantial or risky work. Small coordinated changes may follow the repository's current integration practice.

Never discard, reset, force-push over, or overwrite another agent's work to resolve a conflict.

## Shared resources

Treat these as high-impact:
- Supabase schema/migrations;
- RLS/Auth/grants;
- shared realtime/synchronization;
- central routing/composition;
- shared domain contracts;
- platform/dependency configuration.

Avoid concurrent edits to the same high-impact resource unless explicitly coordinated.

Never weaken security, rewrite applied migration history, expose secrets, or execute destructive shared-resource operations without explicit human approval.

## Architecture boundaries

Preserve:
- **Logic** — state, data, business rules, sync;
- **Structure** — screen composition/navigation/content placement;
- **Visual Design** — styling/tokens/components.

Do not turn a visual task into logic/structure work without explicit scope.

Established architecture is the default path. Do not re-litigate it during ordinary tasks.

## Verification

Use `TEST_MATRIX.md`.

Verification is proportional to blast radius:
- Level 1: local presentation/visual;
- Level 2: contained product behavior;
- Level 3: data/shared-infrastructure/high risk;
- Level 4: milestone/release.

A task is complete only when its required checks actually pass or the missing evidence is explicitly reported.

## Independent review

Independent review is required or strongly preferred for material:
- schema/migration;
- RLS/Auth/security;
- destructive data behavior;
- shared sync/realtime or broad architecture;
- milestone/release integration.

It is not a mandatory second construction cycle for every ordinary UI/UX change.

## Handoff / interruption

Leave only the context another agent actually needs:
- task/status;
- branch/diff or commit;
- what changed;
- verification performed;
- remaining blocker/next action if any.

Do not duplicate long histories already present in Git, CI or task workcards.

If an interrupted task has no handoff, inspect its active row, branch/diff, relevant code and tests. Do not default to a full-project audit.

## Stop conditions

Stop the consequential change when:
- active ownership overlaps;
- the change conflicts with an authoritative requirement;
- a database/security operation may be destructive or irreversible;
- resolving a conflict would discard another agent's work;
- the relevant task state cannot be reconciled.

Report the specific blocker. Do not expand this into an unrelated repository-wide review.

## Standard flow

**CONTEXT → CHECK ACTIVE WORK → IMPLEMENT → PROPORTIONAL VERIFY → INTEGRATE/HANDOFF**

For high-risk work only, expand as needed:

**CONTEXT → CLAIM → ISOLATE → IMPLEMENT → LEVEL-3 VERIFY → INDEPENDENT REVIEW → INTEGRATE**

This protocol is provider-neutral.
