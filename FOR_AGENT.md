# UMAN EVENT MANAGER — Agent Instructions

## Start here

For normal implementation work, read:

1. `AGENT_CONTEXT.md`
2. `ACTIVE_WORK.md`
3. the assigned task instruction/workcard
4. the relevant implementation files/tests

Then work.

`AGENT_ENTRYPOINT.md` defines when additional documents are required. Do not reread the full Master Spec, Technical Spec, ADR, historical workcards, migration history, or old handoffs unless the task actually touches them.

## Settled engineering baseline

- Supabase/PostgreSQL is canonical and server-authoritative.
- Authenticated multi-user, event-scoped access remains mandatory.
- RLS/authorized RPCs, CAS/version checks, audit and realtime/reconciliation patterns are established.
- Domain stays pure Dart; Supabase SDK stays in infrastructure/composition.
- Manager-entered source data is never silently rewritten.
- Android and iOS remain product targets.
- Secrets and sensitive values never belong in source, prompts, logs or UI errors.
- Preserve Logic / Structure / Visual Design separation.

Use the nearest working feature as the implementation pattern. Do not reopen architecture as a routine step.

## Product-delivery behavior

The active mode is defined in `PRODUCT_DELIVERY_MODE.md`.

Prefer:
- small coherent outcomes;
- reusable existing patterns/components;
- changes that are easy to critique from real phone use;
- minimal documentation updates;
- short feedback loops.

Avoid:
- speculative frameworks;
- broad cleanup unrelated to the task;
- “while here” refactors;
- re-auditing completed domains without evidence of a problem;
- adding future features to make a current slice appear more complete.

## Verification

Use `TEST_MATRIX.md`.

Do not automatically run every project test, DB gate, staging check and Android build for every change.

Verification must match **what changed and what can break**:
- presentation-only → Level 1;
- contained product behavior → Level 2;
- schema/security/shared infrastructure → Level 3;
- milestone/release → Level 4.

State exactly what was actually verified.

## Independent review

Independent inspection is risk-based.

Use it for material schema/security/shared-infrastructure/destructive changes and milestone/release integration. It is normally unnecessary for contained low-risk UI/UX work that follows an established pattern and passes proportional verification.

## Documentation and handoff

Live docs stay concise:
- `AGENT_CONTEXT.md` = recurring context;
- `ACTIVE_WORK.md` = active work only;
- `STATUS.md` = current verified product state and milestone;
- task instruction/workcard = task-specific scope.

Detailed historical evidence belongs in task workcards, CI/Git history, or `docs/history/`.

Update live docs only when material project state changed.

If work is interrupted, leave the branch/diff understandable and record the minimum needed for the next agent to continue. Do not create a large narrative handoff when Git + a short note is sufficient.

## Release/platform gates

`CROSS_PLATFORM_DELIVERY.md` remains authoritative for Android/iOS release acceptance.

Windows/Android development cannot certify iPhone/TestFlight runtime behavior. Do not claim external/device verification that was not actually executed.
