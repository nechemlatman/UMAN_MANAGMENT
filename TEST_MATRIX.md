# UMAN EVENT MANAGER — TEST MATRIX

**Purpose:** Proportional verification without sacrificing safety.  
**Effective:** 2026-09-29

Always verify the behavior you changed. Expand verification according to blast radius and risk.

## Level 1 — Local presentation / visual

Typical changes:
- spacing, typography, cards, colors through design tokens;
- labels/copy;
- contained layout changes;
- presentation-only states with no persistence/business-rule change.

Minimum:
- format changed Dart files;
- analyzer;
- targeted widget/unit tests for affected behavior if present;
- visually inspect affected phone-sized UI when practical.

Add RTL/LTR/light/dark checks when the change can affect them.

Normally no DB harness, staging verification, Android rebuild, or independent inspector is required.

## Level 2 — Contained product behavior

Typical changes:
- form behavior/validation;
- controller logic inside one domain;
- derived display data;
- navigation within an existing module;
- repository behavior using existing schema/RPC contracts.

Minimum:
- format;
- analyzer;
- targeted tests for affected domain/controller/widget;
- adjacent regression tests with credible coupling;
- build/runtime check when platform/runtime behavior changed.

Run the full Flutter suite when shared code changed or targeted coverage is insufficient.

Normally no full DB/security suite if database contracts did not change.

## Level 3 — Data/shared-infrastructure/high risk

Typical changes:
- schema or migration;
- RLS/Auth/grants;
- RPC contract;
- CAS/audit semantics;
- realtime/reconciliation shared behavior;
- cross-domain/shared repository contract;
- destructive/restore behavior;
- central routing/composition with broad blast radius.

Required as applicable:
- format + analyzer;
- targeted tests;
- full affected DB harness;
- relevant security/authorization tests;
- migration history/dry-run checks;
- full Flutter regression when shared client behavior changed;
- configured Android build if runtime wiring changed;
- staging/runtime verification where the contract depends on Supabase behavior;
- independent review before integration for material high-risk changes.

## Level 4 — Milestone / release

Use for Beta/release integration, not routine edits.

Run the repository's complete practical gate, including:
- formatter/diff checks;
- analyzer;
- full Flutter test suite;
- full DB verification suite;
- configured Android build;
- CI;
- milestone-specific physical-device walkthrough;
- staging/two-user checks when relevant.

iOS runtime/TestFlight gates remain separate and require macOS/physical iPhone; never claim them from Windows/Android evidence.

## Escalation rule

If a task starts at one level but reveals a broader blast radius, escalate verification.

If a nominally large feature only changes contained presentation code, do not run unrelated DB/security validation merely because the feature name is large.

Verification follows **what changed and what can break**, not ceremony.

## Reporting

State exactly what was run and what was not.

Use:
- **VERIFIED** only for executed checks;
- **IMPLEMENTED BUT UNVERIFIED** when required evidence is missing.

An unavailable external gate should remain recorded for the proper milestone/release; it should not automatically block unrelated low-risk development.
