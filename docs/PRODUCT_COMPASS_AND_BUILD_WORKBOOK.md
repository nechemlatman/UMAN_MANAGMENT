# Product Compass and Build Workbook — Uman Rosh Hashanah Operations

Date: 2026-09-18. Based on the product owner's description and the project documents.

Status: supplementary working document. It maps the vision to the existing specification and records gaps and proposals. It does not replace the specification, claim that features are implemented, or automatically add new requirements to the current development phase. Requirements from the owner's description are distinguished from proposed solutions.

## 1. Refined product vision

The application is Yonatan's personal command center for the annual journey to Uman and the Rosh Hashanah stay. It brings preparation, travel, operations at the accommodation complex, and post-holiday closeout into one actionable operational picture.

Yonatan is the primary user around whom the product is designed. Yosef is a fellow administrator: each has an individual account, and both can view and edit the events to which they have been granted access. Tailoring the application to Yonatan does not reduce Yosef's ability to work or imply a shared account.

At any moment, the product should help them answer: **What is happening now, what is missing or has changed, and what should we do next?** The operational picture should connect people, flights, ground transport, accommodation and beds, meals and kitchen operations, workers, inventory and equipment, purchasing, maintenance, landlords, and finances.

The system organizes information, detects problems, and suggests ways to address them. Operational decisions remain with the administrators; automation does not replace their decisions. Every change is recorded with its actor and time, and a clear way of bringing it to the other administrator's attention must be designed.

The application should be easy to use for people who are not technically confident, especially under pressure and on a phone. Language, home screens, shortcuts, and display options should fit Yonatan's work. The active visual direction is classic, clean, simple, modern and professional (docs/DESIGN_SYSTEM.md). Historical atmosphere/content proposals below are deferred references, not instructions to theme the application.

The foundation should be structured, maintainable, and extensible, separating business rules, presentation, and infrastructure services. Components and the application skeleton can then be reused in a similar future project without turning this product into a complicated general-purpose system.

## 2. Sources and reading guidance

| Source | Purpose |
|---|---|
| [Master v2.6](../UMAN_EVENT_MANAGER_SPEC_v2.6.md) | Product and domain specification; section references below refer to this document |
| [Technical v1.2](../UMAN_EVENT_MANAGER_TECH_SPEC_v1.2.md) | Current technical architecture |
| [ADR-001](../ADR-001-CLOUD-FIRST-REALTIME-MULTIUSER.md) | Decision to adopt cloud persistence, separate accounts, realtime synchronization, and audit |
| [Cross-Platform Delivery](../CROSS_PLATFORM_DELIVERY.md) | Mandatory Android/iOS support and device validation gates; any historical storage instructions are superseded by the ADR |
| Product owner's description dated 2026-09-18 | Product intent and new requirements mapped in this workbook |

**Review finding:** most of the core is specified. However, some requirements are missing, some domains are explicitly deferred, and some working instructions are outdated. There is no need to rewrite the entire specification, but it would be inaccurate to conclude that everything is already defined.

The original review was a documentation review, not a verification of code, cloud deployment, or readiness for real operation. Subsequent implementation evidence belongs in [Phase 1 Progress](../PHASE1_PROGRESS.md).

## 3. Coverage against the owner's description

“Covered” means documented, not necessarily implemented or tested.

| ID | Need | Documentation status and source | Next action |
|---|---|---|---|
| V-01 | Command center for the annual operation | Covered: sections 2–7, 17, 20 | Retain the three operational questions as the basis of each screen |
| V-02 | Tailored to Yonatan | Partial: sections 8, 22 and the design appendix; both administrators are named, but personal workflows are not detailed | Evaluate screens and tasks with Yonatan and record actual preferences |
| V-03 | Yonatan and Yosef view and edit shared information with separate accounts | Covered: sections 26–30, ADR-001, Technical v1.2 | Verify that both are members of each relevant event; event creation currently adds only the creator |
| V-04 | Individual username and password | Partial: individual accounts are defined; the product description does not specify the login identifier | Decide whether “username” means a personal alias or email address before finalizing sign-in UX |
| V-05 | Do not miss the other administrator's changes | Partial: sections 28–30 cover synchronization and audit, not individual tracking of viewed changes | Specify the “what changed” experience; see section 4 |
| V-06 | People, flights, ground transport, drivers, and vehicles | Covered: sections 9–13 | Implement against the existing specification and acceptance criteria |
| V-07 | Apartments, rooms, beds, and assignments | Covered: section 14 | Preserve date-aware assignments and overlap handling |
| V-08 | Holiday meals and kitchen operations | Explicitly deferred: sections 6, 39, DEF-006 | Part of the full vision; requires specification before its implementation phase |
| V-09 | Workers, inventory, equipment, and purchasing | Partial/missing: tasks and assignment to a person exist in section 15; food inventory and automated purchasing are deferred in sections 6, 39 | Define dedicated workflows and entities as needed; a general task is not complete inventory or workforce management |
| V-10 | Maintenance and issue resolution at the complex | Core covered: section 15, Task and ApartmentIssue | Check that reporting, ownership, handling, and closure fit Yonatan's workflow |
| V-11 | Working with landlords | Partial: section 14 includes name, phone, and notes; no structured agreements or commitments workflow | Specify what needs to be remembered and tracked beyond contact details |
| V-12 | Finances | Partial: section 16; expense allocation and individual balances remain open in OPD-002/003 | Do not invent an allocation or debt formula |
| V-13 | Dedicated domain screens, quick access, and multiple views | Partial: sections 8, 17, 20–22 and the design appendix | Prepare a navigation map; distinguish domain data from multiple views of that data |
| V-14 | Optional introductory tour | No explicit definition found | Add a tour, skip, and replay flow; do not expose real data before authentication |
| V-15 | Create “Rosh Hashanah [year]” after entry | Partial: Event exists in section 7; entry flow and Hebrew-year semantics are not specified | Define suggested naming, Hebrew year, and dates; do not change the meaning of the year field without a mapping |
| V-16 | Hebrew/Gregorian calendar, local clock and weather, halachic times | No complete definition found; general date/timezone instructions exist | Define location, timezone, sources, refresh, and missing-information behavior |
| V-17 | Holy-site banner, encouraging teachings, and countdown | No behavior definition found; reference images exist in assets/design_reference/breslov/source_reference | Choose content, quotation sources, image, and countdown target |
| V-18 | Personalized reminders and notifications | Partial: operational alerts exist in sections 18–20; Push is deferred in DEF-009 | Distinguish an operational warning, a scheduled reminder, and a change notification |
| V-19 | Usability and professional maintainability | Core covered: section 22, Technical v1.2, and the design appendix | Demonstrate usability through real tasks alongside technical tests |
| V-20 | Reuse the skeleton for a similar application | Partial: layer separation and reusable design components exist; reuse boundaries are not detailed | Proposal: separate Uman branding/content from infrastructure; do not add multi-organization functionality now |

## 4. Turning the vision into testable behavior

### 4.1 Partnership and awareness of changes

Owner requirement: no change should go unnoticed by Yonatan or Yosef. Software cannot guarantee that a person has read and understood a message; it can guarantee recording, access to changes, and explicit tracking of acknowledgment.

Four separate concerns need a solution:

1. **Persistence:** the server committed the change and the user received reliable feedback.
2. **Synchronization:** the other device received current state; disconnected views show the last synchronization time.
3. **Audit:** the actor, time, previous value, and new value were recorded.
4. **Awareness:** the other administrator can identify changes that still need attention.

The first three are already planned in the architecture. The fourth needs additional product definition.

**Proposal for further specification:** a “what changed since your last visit” area, a change list linking to affected records, and separate viewed state for each user. Changes classified as critical could require an explicit “I have read this” acknowledgment. Background receipt and Push delivery do not count as acknowledgment. Resolving an operational issue does not establish that both administrators saw a change.

A committed change remains recorded even if notification delivery fails. Reconnection should restore current data and access to unviewed changes. List scope, sensitive details, and retention policy need definition before implementation.

### 4.2 Personal control

Owner requirement: Yonatan controls the information, operations, and his working experience. The existing specification allows customization while protecting integrity, event isolation, and audit.

Proposal: distinguish shared event settings, such as currency and timezone, from personal preferences, such as shortcut order and display density. This separation is not fully specified or an already-approved schema change. Define which customizations Yosef shares and which are stored individually.

“Full control” does not mean erasing audit history, bypassing authentication, or breaking data relationships. Manual edits and operational overrides must be explicit and attributable.

### 4.3 Entry and opening a new year

Proposed flow based on the request: welcome screen → tour or skip → individual sign-in → choose an existing event or create “Rosh Hashanah [year]” → command center.

The tour can be reopened from Help. Before authentication, it shows explanations or demonstration data only. Returning users must not be forced to repeat the tour or create another event. Both administrators should reach the same authorized event rather than accidentally creating two versions of the same year.

Define the relationship between the Hebrew year, event name, stay dates, and Rosh Hashanah date. A countdown to the holiday is not necessarily a countdown to departure.

### 4.4 Time, place, and atmosphere

“Local” needs a definition: device location, Uman, or the activity's location. Master section 20 currently defines Today using the device date; its relationship to an Uman clock must be explicit before adding these widgets.

External information needs a source and update time. Halachic times need a location and calculation convention; weather needs a forecast location and validity; the countdown needs a target instant and timezone. “Calendar synchronization” may mean dual-date display, an in-app calendar, or external calendar integration; do not assume two-way integration.

The banner must keep text legible and leave room for urgent actions. Teachings presented as quotations require verified attribution; inspirational wording must not be presented as an original quotation. Content and image selection are future design tasks, not part of the original documentation review.

## 5. Current dependency order (owner direction, 2026-09-19)

Close foundation evidence and complete Event before Person. Then proceed one slice
at a time: Person → Flight → FlightPassenger → Driver → Vehicle → Trip →
TripPassenger → Apartment → Room → SleepingPlace → AccommodationAssignment →
Tasks → Apartment Issues → Operational Rules → Unresolved Items → Control Center →
Today View → Finance / Expenses / Payments → search/sharing/import-export.
Do not build a decorative dashboard before operational data. The older proposed
sequence below is retained as vision context and does not override this order.

### Historical proposed work sequence

This is a dependency sequence, not a change to existing phase numbering or a delivery-date commitment.

| Step | Deliverable | Gate |
|---|---|---|
| 1. Align working instructions | Clear references and authority for current documents | A new developer is not instructed to build a local source of truth |
| 2. Shared foundation | Accounts, Event, authorization, persistence, synchronization, audit, and conflicts | Yonatan/Yosef scenario on two devices; no completion claim without evidence |
| 3. Working shell | Entry/tour, year selection, navigation and command center, change-awareness design | Yonatan can identify urgent work and changes |
| 4. Operational core | People → arrivals/transport → accommodation → tasks/maintenance → finances within defined boundaries | End-to-end participant workflow and existing acceptance tests |
| 5. Uman experience | Calendar/dates, clock, weather, halachic times, banner, reminders | Sources and time semantics defined; missing external information does not break the interface |
| 6. Complete operational scope | Kitchen, meals, workers, inventory, equipment, purchasing, landlord relationships | Each domain has a defined workflow, data, ownership, and acceptance test |

Step 6 belongs to the full vision even where deferred in the current MVP. If the coming year's operation depends on it, record a scope and priority change before planning delivery. Notes and tasks are not automatically substitutes for inventory and meal management.

## 6. Work card for each capability

Copy when opening a task:

```text
Capability name:
Need ID V-xx and specification section:
Status: specified / requirement from the new description / unresolved proposal
Yonatan's or Yosef's problem:
Scenario: when ___, the user wants ___, so that ___
Entry screen/action and next step:
Data and event relationships:
Who can view and edit:
What is persisted, synchronized, and audited:
How the partner discovers the change, if applicable:
Missing information, disconnection, failure, and conflict behavior:
Shared settings and personal preferences:
Included in this delivery / deferred:
Testable acceptance criteria:
Open decisions and dependencies:
Progress: mapped / specifying / ready / implementing / verifying / complete
Evidence: code, test, device, date; unverified items explicitly marked
```

Example: **V-05 — Yosef changes a flight time.** The updated time is recorded with his identity and reaches Yonatan; the changed time and flight link are visible. A flight change does not silently change transport time (Master sections 10 and 35). If Yonatan is editing concurrently, his draft is not overwritten. Audit history is checked separately from personal viewed state. Viewed-state tracking remains a proposed addition, not an existing capability.

## 7. Vision acceptance scenarios

These supplement AC-01–AC-12; they are not test results and do not replace those criteria.

| ID | Scenario | Evidence required |
|---|---|---|
| VC-01 | First and returning visits | Tour or skip, replay Help, return to an existing event without creating another |
| VC-02 | Two administrators, one year | Separate identities, membership in the same event, committed changes visible without manual refresh |
| VC-03 | Change while the partner is disconnected | Current data and the change become accessible on return; background receipt does not count as viewing |
| VC-04 | Concurrent edits | No silent overwrite; current data and draft remain available for deliberate resolution |
| VC-05 | Person without transport or accommodation | Command center exposes the gap and a path to action; the system does not assign on the administrator's behalf |
| VC-06 | Switching operational years | No data/change leakage across events; the current year is evident |
| VC-07 | Time and local information | Device timezone changes do not change the countdown target instant; location/calculation convention are known; stale information is marked |
| VC-08 | Nontechnical users | Yonatan and Yosef find a person, change an assignment, and discover the partner's change without developer guidance; difficulties are recorded |
| VC-09 | Display customization | Global changes use shared components/settings; a personal preference does not accidentally modify event data |
| VC-10 | Expanded operational domain | A complete defined workflow can be demonstrated and tested before claiming kitchen or inventory management |

## 8. Documentation issues found in the original review

The source documents were unchanged during the original review. The following issues were identified for resolution before dependent development. Subsequent resolution and evidence are recorded in Phase 1 Progress; this table preserves the original findings.

| Document | Finding | Targeted correction |
|---|---|---|
| FOR_AGENT.md | Old filenames and instructions for a single-device product without synchronization | Align to Master v2.6, Technical v1.2, ADR-001 while preserving valid domain rules |
| README.md | Offline-first description and generic Flutter starter text | Describe cloud authority and cached offline reads; link active documents |
| PHASE1_PROGRESS.md | Tracks the old Drift foundation; cannot establish cloud verification | Preserve history and record current status based on actual tests |
| CROSS_PLATFORM_DELIVERY.md | Dual-platform requirement remains valid; old baseline/storage instructions remain | Update authentication, cache, cloud, and synchronization checks on both platforms |
| Master v2.6 section 39 | Deferral reasons still say single manager, no synchronization, and no server infrastructure | Remove obsolete reasons without silently changing feature scope |
| Master v2.6 section 7 | Transition table mentions time/arrival automation, while Technical v1.2 requires explicit transitions | Clarify that automatic transitions await defined thresholds and a decision |
| spec_parts and old versions | Copies coexist with the current Master | Verify alignment or mark historical before use; full alignment was not verified in the original review |

## 9. Decisions to resolve when needed

These do not prevent understanding the vision. Resolve each before implementing the dependent capability:

- What is required for the first real operational release: must kitchen, workers, and inventory be included?
- What is the preferred login identifier, and how does Yosef gain access to each new event created by Yonatan, and vice versa?
- Which changes need explicit acknowledgment, which only need a change list, and what are each administrator's notification preferences?
- Which customizations are personal and which are shared across the event?
- What does calendar synchronization mean; which location governs each view; which halachic calculation convention and countdown target apply?
- What are the real workflows for kitchen operations, workers, inventory, and landlord relationships?
- What are the expense allocation and balance rules, as required by existing OPD-002/003?

**Working rule:** before building a capability, find its V row, read the source, fill in a work card, and define acceptance evidence. Specify new needs first; implement defined needs against the existing specification without inventing alternative rules.
