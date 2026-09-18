> HISTORICAL ONLY — superseded by Master v2.6 / Technical v1.2 / ADR-001. Not implementation instructions.

# UMAN EVENT MANAGER — Master Product & System Specification v2.5

## SECTION 1: Document Header & Status Matrix

- **Document Title:** UMAN EVENT MANAGER — Master Product & System Specification v2.5
- **Version:** 2.5
- **Status:** IMPLEMENTATION BASELINE — OPEN PRODUCT DECISIONS EXPLICITLY DEFERRED
- **Version 2.5 Change Note:** v2.4 is frozen and unmodified in substance. v2.5 adds a single authoritative cross-reference to the new `UMAN_EVENT_MANAGER_DESIGN_SPEC_v1.0.md` (Breslov Design Language). No product/domain requirement, entity, rule, or acceptance criterion changed. DESIGN_SPEC controls visual/UI language; this Master Spec continues to control product/domain behavior; TECH_SPEC controls technical architecture; CROSS_PLATFORM_DELIVERY controls delivery/platform requirements. Where documents conflict, functional correctness and accessibility override decorative styling.
- **Classification:** Internal — Authoritative Product Specification
- **Audience:** AI Development Agents, Product Owner, Technical Leads

### Status Matrix

| Area | Status | Notes |
| :--- | :--- | :--- |
| Event Model | MVP — Defined | Core event scoping and isolation |
| People | MVP — Defined | Profiles, groups, relationships |
| Flights | MVP — Defined | Inbound/Outbound, assignments |
| Transport | MVP — Defined | Ground transit, routes, passengers |
| Accommodation | MVP — Defined | Buildings, rooms, beds, assignments |
| Tasks | MVP — Defined | Actionable items, assignments |
| Finance | MVP — Defined | Incomes, expenses, balances |
| Control Center | MVP — Defined | Real-time operational dashboard |
| Rules Engine | MVP — Defined | Validation, warnings, derivations |
| Unresolved State | MVP — Defined | Global issue tracking and resolution |
| Today View | MVP — Defined | Time-sensitive context |
| Search | MVP — Defined | Global and contextual search |
| Bilingual UX | MVP — Defined | EN/HE UI and data support |
| Sharing Snapshot | MVP — Defined | Plain-text static snapshot for copy/share/WhatsApp |
| Structured Data Export | MVP — Defined | Event-scoped CSV and JSON export |
| Formatted Reports | Phase 2 — Deferred | PDF/HTML reports are not MVP sharing |
| Data Integrity | MVP — Defined | Validation, conflict prevention |
| Backup/Restore | MVP — Defined | Local DB backups |
| Security | MVP — Defined | Local machine security |
| Offline-First | MVP — Defined | 100% local operation |
| Future Sync | Future — Constraints Defined | Architecture supports future sync |
| Future Permissions | Future — Constraints Defined | RBAC concepts deferred |
| Audit | MVP — Defined | Action logging (local) |
| Import/Export | MVP — Defined | CSV data loading/extraction |
| Migration | MVP — Defined | DB schema versioning |
| Performance | MVP — Defined | Optimized for single device |
| Data Model | MVP — Defined | Core entities and relationships |
| Edge Cases | MVP — Defined | Handling unusual scenarios |
| Acceptance Criteria | MVP — Defined | Success metrics for MVP |
| Traceability | MVP — Defined | Tracking actions to issues |
| Visual/UI Design | MVP — Defined (System) / Phase 2 — Screen Implementation | Breslov Design Language governs all future UI; see `UMAN_EVENT_MANAGER_DESIGN_SPEC_v1.0.md` |

*(Note: The matrix covers representative areas from the full list of 40 requested, categorized per instructions.)*

### Platform Delivery Baseline

Android is the primary Windows development and daily-testing platform; Android and iOS are mandatory production targets. Final user acceptance is on a real iPhone. The binding delivery policy, iOS Compatibility Gate, and TestFlight release path are defined in `CROSS_PLATFORM_DELIVERY.md` v1.0.

### Visual Design Baseline

All UI implementation MUST comply with `UMAN_EVENT_MANAGER_DESIGN_SPEC_v1.0.md` (the "Breslov Design Language"). That document is now an authoritative part of this project. It governs colors, typography, ornamentation, iconography, component language, and screen-level visual treatment. It does not alter any entity, rule, workflow, or acceptance criterion defined elsewhere in this Master Spec. Visual design is part of the architecture, not a final-stage decoration: no future agent may independently replace the Breslov Design Language with generic Material, Cupertino-only styling, corporate dashboard styling, or another unrelated visual theme without an explicit product-level decision. Where the Design Spec and this Master Spec conflict, functional correctness and accessibility override decorative styling.

## SECTION 2 THROUGH SECTION 40

All content of SECTION 2 through SECTION 40 is UNCHANGED from `UMAN_EVENT_MANAGER_SPEC_v2.4.md` and is incorporated here by reference and is byte-identical to that file. Refer to `UMAN_EVENT_MANAGER_SPEC_v2.4.md` (retained as the historical frozen baseline) for the full text of Sections 2–40, covering: Executive Summary; Product Definition & Core Promises; The Three Questions; Non-Negotiable Product Principles; MVP Scope vs. Phase 2 Boundary; Event Model & Lifecycle; Manager Control & Customization; People Management; Flight Management; Driver Management; Vehicle Management; Transport Management; Accommodation & Sleeping Logistics; Tasks & Apartment Issues; Financial & Multi-Currency System; Control Center; Reactive Domain Rules Engine; Unresolved Operational State; Today View; Universal Search; Bilingual UX; External Sharing Snapshots & PII Sanitization; Data Integrity & Record Lifecycle; Backup, Restore & Recovery; Security & Privacy; Offline-First Architecture; Future Synchronization Constraints; Future Multi-User & Permissions Constraints; Audit Readiness; Data Import & Export; Data Migration & Versioning; Performance Requirements & Benchmark Methodology; Conceptual Data Model & Relationship Schema (19 entities); Uman Operational Edge Cases & Mitigation Rules; Acceptance Criteria (AC-01–AC-12); Requirement Traceability; Definition of Done; Open Decisions & Explicitly Deferred Items; Final Internal Consistency Audit.

# Visual Design System & Full UI Customization

> **v2.5 note:** This section defines the *architectural framework* for design tokens, components, density, and agent behavior (Sections 1–18 below), and remains fully in force, unchanged from v2.4. As of v2.5, the *concrete* visual identity — actual color values, typography choices, ornamentation, iconography, and screen-level treatment — is authoritatively defined in `UMAN_EVENT_MANAGER_DESIGN_SPEC_v1.0.md` (the Breslov Design Language) and supersedes any placeholder/example values below. Read the concrete values from the Design Spec; read the architectural rules (hard-coding rule, AI Agent Design Rule, Design Playground, density levels, iterative workflow) from this section. The full text of Sections 1–18 and the Acceptance Principle is unchanged from v2.4 and is incorporated by reference from that file.

## SUPERSEDING CROSS-REFERENCE

Wherever v2.4's "Visual Design System & Full UI Customization" section (Objective through Acceptance Principle, items 1–18) discusses example/placeholder color tokens, typography choices, spacing values, or visual themes, those examples are now superseded by the concrete values in `UMAN_EVENT_MANAGER_DESIGN_SPEC_v1.0.md`. The architectural rules themselves (no screen invents its own visual language; centralized tokens; the Hard-Coding Rule; the AI Agent Design Rule; the Design Playground; density levels; the iterative visual development workflow; Product Owner control via centralized definitions; the Acceptance Principle) remain in force exactly as written in v2.4.
