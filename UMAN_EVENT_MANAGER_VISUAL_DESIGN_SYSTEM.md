# UMAN EVENT MANAGER --- VISUAL DESIGN SYSTEM

**Status:** Authoritative visual-design instruction\
**Reference source:** `assets/design_reference/modern`\
**Design direction:** Classic · Modern · Clean · Calm · Operational\
**Scope:** Visual Design only unless a separate product/structure
instruction explicitly says otherwise.

------------------------------------------------------------------------

## 1. Purpose

This document defines the visual language of UMAN EVENT MANAGER from the
approved `modern` reference images.

The goal is not to imitate one screenshot mechanically. The goal is to
preserve the coherent visual system visible across the approved
references and apply it consistently throughout the application.

The application must feel:

-   beautiful and intentionally designed;
-   modern without looking fashionable for its own sake;
-   clean without becoming empty or sterile;
-   calm while still making operational priorities obvious;
-   professional and trustworthy;
-   easy to scan quickly on a phone;
-   comfortable for repeated daily use;
-   native and natural on both Android and iPhone;
-   equally coherent in Hebrew RTL and English LTR.

The UI is an operational command center. Information and actions take
priority over decoration.

------------------------------------------------------------------------

## 2. Source of Truth --- No Invention

The images in `assets/design_reference/modern` are the visual reference
set.

When implementing or extending the UI:

1.  Inspect the approved reference images before making visual
    decisions.
2.  Extract recurring visual rules rather than copying isolated
    accidents from a single screenshot.
3.  Prefer patterns that appear consistently across the reference set.
4.  Do not introduce a new visual language because a developer, agent,
    package, or generated component has a different default style.
5.  Do not add decorative elements, gradients, colors, shadows, icon
    styles, illustrations, textures, or visual effects that are not
    justified by the established system.
6.  Do not guess exact visual constants when they have not yet been
    measured. Measure from the references where possible, define the
    resulting value once as a token, and reuse it.
7.  When the references do not determine a detail, use the existing
    design-system token or the least visually disruptive
    platform-consistent solution. Do not create a new style family.
8.  New screens must look as if they were designed together with the
    existing screens, not added later by another product.

The design system, once encoded into tokens and shared components,
becomes the implementation source of truth. Individual screens must not
override it casually.

------------------------------------------------------------------------

## 3. Mandatory Separation of Layers

The project maintains three separate layers:

### 3.1 Logic

Functionality, state, data, validation, synchronization, permissions,
business rules, calculations, persistence, and domain behavior.

### 3.2 Structure

Which sections exist on a screen, their information hierarchy, ordering,
navigation, flows, and which actions or data are exposed.

### 3.3 Visual Design

Colors, typography, spacing, padding, radii, borders, surfaces, cards,
buttons, fields, icons, shadows, visual density, and presentation
styling.

A visual redesign must modify **Visual Design only** unless the task
explicitly authorizes a structural or logical change.

Never "improve the design" by silently: - changing business behavior; -
removing information; - adding new functionality; - changing navigation
or workflow; - changing database/state architecture; - moving or
deleting structural sections; - altering permissions or synchronization.

If a structural problem becomes apparent during visual work, document it
separately rather than silently changing it.

------------------------------------------------------------------------

## 4. Core Visual Character

The approved direction is **classic, simple, clean, modern,
professional, and calm**.

The visual character should communicate:

-   clarity before decoration;
-   confidence without visual heaviness;
-   generous but efficient spacing;
-   strong information hierarchy;
-   restrained use of color;
-   refined cards and surfaces;
-   readable typography;
-   soft, controlled depth;
-   clear actions;
-   operational status at a glance.

Avoid: - loud or saturated full-screen color; - excessive gradients; -
decorative religious/Breslov styling as the dominant UI language; -
cartoonish components; - oversized ornamental icons; - excessive
shadows; - glassmorphism used as decoration; - crowded dashboards; -
tiny text; - excessive border lines; - multiple competing accent
colors; - every section looking like an independent card style; -
generic unmodified Material defaults when they conflict with the
reference language.

------------------------------------------------------------------------

## 5. Visual Hierarchy

Every screen should make the following understandable within seconds:

1.  **Where am I?**
2.  **What is the important context?**
3.  **What requires attention?**
4.  **What can I do here?**

The standard visual hierarchy is:

**App/brand context → Screen title and subtitle → contextual
summary/banner → key status/summary → primary content → primary action →
persistent navigation**

Not every screen must contain every layer, but the hierarchy must remain
recognizable.

The user should never have to decode the interface visually.

------------------------------------------------------------------------

## 6. Color System

The reference direction uses a restrained, professional palette.

### 6.1 Primary family

A deep navy / professional blue family is the main identity and control
color.

Use it for: - primary actions; - selected navigation; - important
interactive emphasis; - selected states; - controlled brand emphasis; -
banner overlays where appropriate.

It must not flood every surface.

### 6.2 Warm accent

A soft gold / sand family may be used as a restrained secondary accent
where supported by the reference language.

It is an accent, not a second primary color.

### 6.3 Neutral surfaces

The application should rely primarily on: - warm off-white / light
neutral page backgrounds; - white or subtly differentiated cards; - soft
gray secondary surfaces; - dark neutral text; - muted secondary text.

This creates the calm, premium appearance visible in the modern
references.

### 6.4 Semantic colors

Success, warning, danger, and informational states must have dedicated
semantic tokens.

Semantic colors are functional. They must not be used merely to make a
screen "more colorful."

Red/orange should appear only when the state genuinely requires warning
or attention.

Severity must never depend on color alone. Pair color with text,
iconography, labeling, or another clear visual signal.

### 6.5 Token requirement

No screen may introduce ad-hoc color literals.

Define semantic tokens such as: - `backgroundPrimary` -
`backgroundSecondary` - `surfacePrimary` - `surfaceElevated` -
`textPrimary` - `textSecondary` - `textMuted` - `borderSubtle` -
`primary` - `primaryPressed` - `accentWarm` - `success` - `warning` -
`danger` - `info` - `overlayStrong` - `overlaySoft`

Exact values must be established centrally from the approved reference
set and changed centrally.

------------------------------------------------------------------------

## 7. Typography

Typography must feel editorially refined in headings while remaining
extremely readable in operational UI.

The reference direction supports: - a refined serif/display treatment
for selected high-level titles or prominent editorial moments; - a clean
sans-serif UI face for operational text, controls, data, forms, lists,
labels, and dense information.

Do not mix typefaces arbitrarily.

### Typography hierarchy

Centralize styles for: - display / hero; - screen title; - section
title; - card title; - body; - secondary body; - label; - metadata; -
metric/value; - button; - caption.

Rules: - hierarchy must come from size, weight, spacing, and
contrast---not from random colors; - body text must remain comfortably
readable on a phone; - secondary text must be quieter but not faint; -
important numbers/metrics should be immediately scannable; - avoid
excessive bold text; - avoid all-caps as a general UI style; - line
heights must allow comfortable reading in Hebrew and English; - layouts
must tolerate text expansion without clipping.

Typography values belong in centralized tokens/theme definitions.

------------------------------------------------------------------------

## 8. Spacing and Layout Rhythm

Spacing is a core part of the design, not leftover empty space.

Use a centralized spacing scale. Screens must not accumulate arbitrary
padding values.

The visual rhythm should provide: - comfortable page margins; -
consistent vertical separation between sections; - tighter spacing
between directly related label/value pairs; - consistent internal card
padding; - enough breathing room around headings; - deliberate
separation between primary and secondary actions.

Related content should visually group together. Unrelated content should
not be forced into one dense block.

Avoid both extremes: - cramped screens with insufficient whitespace; -
oversized empty areas that force unnecessary scrolling.

Use logical directional values: `start`, `end`, `leading`, `trailing`,
not hard-coded left/right assumptions.

------------------------------------------------------------------------

## 9. Cards and Surfaces

Cards are a major structural visual element in the reference language.

They should feel: - light; - calm; - slightly separated from the
background; - consistent; - touch-friendly; - information-first.

Use: - medium, consistent corner radii; - subtle borders and/or
restrained elevation; - controlled shadow; - generous but efficient
internal padding; - clear title/content/action hierarchy.

Do not: - give every card a different radius; - use dramatic floating
shadows; - put cards inside cards without a clear reason; - use heavy
outlines everywhere; - turn every line of information into its own card.

Create shared card primitives and variants instead of styling each
screen independently.

------------------------------------------------------------------------

## 10. Contextual Summary Banners

The small contextual banner visible in the reference direction is a
**first-class reusable component**, not a decorative afterthought.

Canonical component family: - `EventHeroBanner` -
`ModuleSummaryBanner` - `ContextSummaryBanner`

These may share one underlying component with explicit variants.

### Purpose

The banner gives immediate visual context and summarizes the most useful
information for the current screen.

It may contain: - a contextual image; - a controlled dark/blue
readability overlay; - title; - short subtitle; - date/context; - one or
more compact metrics; - an optional relevant action.

### Rules

-   Keep the banner compact enough that it does not push operational
    content too far below the fold.
-   Image choice must be contextually relevant.
-   Text must remain readable regardless of image brightness.
-   Use a consistent overlay treatment.
-   Metrics must be concise.
-   Do not overload the banner with a full dashboard.
-   Do not place decorative text over visually busy areas without
    sufficient contrast.
-   Banner radius, padding, overlay, typography, height family, and
    content placement must be shared tokens/components.
-   Variants may change content, not visual DNA.

The banner should make a screen feel polished and contextual while still
serving a real information purpose.

------------------------------------------------------------------------

## 11. Summary Metrics and Status

Operational summaries should be scannable without feeling like a
financial analytics dashboard.

Use: - concise metric values; - short labels; - restrained status
indicators; - consistent grouping; - clear tap targets when a metric is
actionable.

Do not use decorative charts merely to fill space.

A metric must answer a useful operational question.

Warnings and unresolved issues should be visually prominent enough to
notice quickly but should not make the entire application feel
permanently alarming.

------------------------------------------------------------------------

## 12. Buttons and Actions

Buttons must be visually consistent and clearly ranked.

Required hierarchy: - primary action; - secondary action; -
tertiary/text action; - destructive action; - icon-only action where
appropriate.

Rules: - one obvious primary action per local context whenever
possible; - primary buttons use the main identity color; - destructive
styling is reserved for destructive actions; - button heights, radii,
typography, icon spacing, loading state, disabled state, and pressed
state are centralized; - touch targets must be at least 48×48dp; -
labels should describe the action clearly; - avoid excessive rows of
equal-weight buttons.

Floating actions should be used only when they match the screen's actual
primary creation workflow, not automatically.

------------------------------------------------------------------------

## 13. Forms and Input Fields

Forms must feel calm and predictable.

Use: - consistent field height; - consistent radius; - clear labels; -
clear focus state; - clear validation state; - readable helper/error
text; - appropriate keyboard/input type; - logical grouping of related
fields.

Do not rely on placeholder text as the only label.

Validation must explain what needs attention without turning the entire
form red.

Long forms should remain visually segmented and scannable.

Hebrew and English input, including mixed-direction content such as
names, airport codes, phone numbers, flight numbers, and addresses, must
display naturally.

------------------------------------------------------------------------

## 14. Lists

Lists are operational surfaces and must prioritize scanning.

Each row should make the primary identity obvious, with secondary
metadata visually quieter.

Use consistent: - row height/density; - leading/trailing behavior; -
separators or spacing; - status placement; - action affordances.

Do not show every available field in a list row.

A list is for recognition and selection; detailed information belongs in
the detail view.

------------------------------------------------------------------------

## 15. Navigation

Navigation must be stable, predictable, and visually quiet.

The bottom navigation, where used, should: - keep a stable location; -
use a consistent icon family; - make the selected destination
unmistakable; - avoid unnecessary labels/badges; - use the same visual
treatment across modules.

Do not rearrange primary navigation based on temporary state.

Navigation icons must be familiar and semantically clear. Avoid
decorative or ambiguous iconography.

------------------------------------------------------------------------

## 16. Icons

Use one coherent icon family/style.

Icons should: - support comprehension; - have consistent visual
weight; - align correctly with text; - use semantic color only when
meaningful; - never become the dominant decoration.

Do not mix filled, outlined, cartoon, and custom illustration styles
casually.

An icon without an obvious meaning should have a label or accessible
description.

------------------------------------------------------------------------

## 17. Images and Illustration

Photography/images should be purposeful.

Use images primarily for: - contextual banners; - event/location
context; - approved visual moments that improve recognition or
atmosphere.

Do not use large imagery as wallpaper behind operational data.

Do not introduce a Breslov-themed decorative layer across the
application. Religious/location imagery may appear when contextually
appropriate and approved, but the application's base visual identity
remains classic, neutral, modern, and professional.

------------------------------------------------------------------------

## 18. RTL, LTR, and Bilingual Design

Hebrew RTL and English LTR are equal first-class modes.

Mandatory: - use logical `start/end` and `leading/trailing`; - mirror
directional layout appropriately; - do not mirror universally
recognizable non-directional symbols unnecessarily; - handle mixed
Hebrew/English text correctly; - ensure numbers, dates, currencies,
phone numbers, flight numbers, and codes remain readable; - verify
cards, banners, lists, navigation, forms, dialogs, and empty states in
both directions; - no layout should be designed in LTR first and merely
"flipped" later.

The same visual hierarchy must survive both directions.

------------------------------------------------------------------------

## 19. Light and Dark Themes

The design system must support centralized light and dark themes.

Light mode should remain highly readable in bright conditions.

Dark mode should: - preserve hierarchy; - avoid pure-black/pure-white
harshness where the established system calls for softer surfaces; -
maintain semantic status clarity; - use restrained elevation/surface
differentiation; - preserve image/banner readability.

Dark mode must be designed from tokens, not produced by mechanically
inverting colors.

------------------------------------------------------------------------

## 20. Accessibility and Usability

Beauty does not override usability.

Mandatory: - minimum 48×48dp touch targets; - sufficient text/background
contrast; - readable body sizes; - no critical meaning conveyed only by
color; - clear focus/pressed/disabled/error states; - support text
scaling without catastrophic clipping; - meaningful semantics for
controls; - avoid tiny low-contrast metadata; - avoid interactions that
require precision tapping.

The interface should remain understandable under stress, outdoors, and
during active event operations.

------------------------------------------------------------------------

## 21. Loading, Empty, Error, and Offline/Sync States

System states are part of the visual design and must be designed
consistently.

### Loading

Prefer calm skeleton/progress treatments that preserve layout stability.
Avoid unnecessary full-screen blocking loaders.

### Empty

Explain what is empty and, when useful, provide the relevant next
action. Do not make empty states visually louder than real content.

### Error

State the problem clearly and expose the appropriate recovery action.
Use danger styling proportionally.

### Sync/connectivity

When sync state needs to be surfaced, it must be understandable without
overwhelming normal operation. Do not create persistent alarming UI for
healthy background behavior.

All state components must use shared styles.

------------------------------------------------------------------------

## 22. Dialogs, Sheets, Menus, and Feedback

Use platform-appropriate interaction surfaces while preserving the
shared visual language.

Rules: - confirmations should be concise; - destructive confirmations
must be explicit; - bottom sheets should have clear hierarchy and
comfortable touch targets; - snackbars/toasts are for transient
feedback, not important persistent information; - menus should not
contain hidden critical workflow steps; - modal surfaces must not be
used when an inline interaction is clearer.

------------------------------------------------------------------------

## 23. Responsive Mobile Behavior

The primary target is phone use on Android and iPhone.

Design for: - narrow phone widths; - safe areas; - keyboard
appearance; - long Hebrew/English strings; - device text scaling; -
different screen heights; - iOS and Android system insets.

Do not optimize a screen only for one test phone.

Avoid fixed pixel positioning that breaks when content changes.

------------------------------------------------------------------------

## 24. Centralized Design Tokens

All recurring visual values must come from a single design-system layer.

At minimum centralize: - color palette; - semantic colors; -
typography; - spacing scale; - page padding; - card padding; - radii; -
borders; - shadows/elevation; - button dimensions; - input dimensions; -
icon sizes; - navigation dimensions; - banner variants; - animation
durations/curves where used; - light/dark theme mappings.

Do not scatter "magic numbers" through widgets.

A visual change such as card radius, page background, primary color,
standard padding, or button height should be possible without editing
every screen.

------------------------------------------------------------------------

## 25. Shared Components

Create/reuse shared presentation components for recurring patterns,
including where applicable:

-   page shell/scaffold;
-   screen header;
-   section header;
-   standard card;
-   status card;
-   summary metric;
-   empty state;
-   error state;
-   loading state;
-   primary/secondary/destructive buttons;
-   standard form field wrappers;
-   status chip/badge;
-   list row;
-   confirmation surface;
-   `EventHeroBanner`;
-   `ModuleSummaryBanner`;
-   `ContextSummaryBanner`;
-   bottom navigation.

Do not build a new "almost identical" component per module.

Variants should be explicit and documented.

------------------------------------------------------------------------

## 26. Screen Composition Rules

A well-designed UMAN screen should generally follow this rhythm:

1.  stable app/navigation context;
2.  clear screen title;
3.  concise contextual subtitle when needed;
4.  compact contextual banner or summary when useful;
5.  critical alerts/attention items before low-priority information;
6.  grouped operational content;
7.  clear primary action;
8.  stable navigation.

Do not blindly force this template onto a screen where a component has
no purpose. Consistency means consistent principles, not identical
layouts.

------------------------------------------------------------------------

## 27. Information Density

UMAN manages real operational data. The interface must support
meaningful density without becoming crowded.

Rules: - show what is needed for the current decision; - progressively
reveal secondary details; - use typography and spacing before adding
containers; - keep metadata visually subordinate; - avoid giant cards
for tiny amounts of information; - avoid compressing complex records
into unreadable rows; - prefer clear grouping over decorative
separation.

------------------------------------------------------------------------

## 28. Motion

Motion, if used, should clarify state change or spatial relationship.

Use subtle transitions for: - screen/state changes; -
expanding/collapsing content; - loading completion; - confirmation
feedback.

Avoid: - decorative bouncing; - long animations; - motion that delays
action; - inconsistent animation styles.

Operational speed takes priority.

------------------------------------------------------------------------

## 29. Visual QA Checklist

Every implemented or restyled screen must be reviewed for:

-   visual match to `assets/design_reference/modern`;
-   correct design tokens rather than hard-coded values;
-   consistent typography hierarchy;
-   consistent card treatment;
-   consistent button hierarchy;
-   consistent field styling;
-   spacing rhythm;
-   image/banner readability;
-   no unjustified decorative elements;
-   no accidental Breslov-heavy styling;
-   Hebrew RTL;
-   English LTR;
-   mixed-direction data;
-   light theme;
-   dark theme where supported;
-   text scaling;
-   48×48dp minimum touch targets;
-   long content;
-   empty state;
-   loading state;
-   error state;
-   small and tall phone layouts;
-   Android;
-   iOS compatibility;
-   no Logic changes caused by visual work;
-   no Structure changes unless explicitly approved.

A screen is not finished merely because it compiles.

------------------------------------------------------------------------

## 30. Implementation Workflow

For visual implementation:

1.  Read this document.
2.  Inspect the approved `assets/design_reference/modern` images.
3.  Inspect the existing centralized theme/tokens/shared components.
4.  Identify whether the requested work affects Logic, Structure, or
    Visual Design.
5.  If it is a visual task, keep Logic and Structure unchanged.
6.  Reuse or extend centralized tokens/components.
7.  Implement the smallest coherent visual change.
8.  Test Hebrew RTL and English LTR.
9.  Test representative phone sizes.
10. Run static/tests required by the project.
11. Compare the result visually with the reference set.
12. Document any genuinely unresolved design decision instead of
    inventing one.

------------------------------------------------------------------------

## 31. Prohibited Implementation Patterns

Do not: - hard-code visual constants throughout screens; - create
per-screen mini themes; - change Logic during styling; - change
Structure without explicit authorization; - introduce a new palette
because a package default looks convenient; - use random stock
imagery; - add decorative gradients/effects without reference support; -
overuse status colors; - use color as the sole severity signal; - create
inconsistent corner radii; - create inconsistent button heights; - mix
unrelated icon styles; - ship layouts tested only in one
language/direction; - treat iOS as an afterthought; - duplicate shared
components; - make "temporary" visual hacks that bypass the design
system.

------------------------------------------------------------------------

## 32. Design Governance

This document is the authoritative visual-design instruction for the
modern direction.

When another document conflicts with it on **visual styling**, this
document governs unless a newer explicitly approved design decision
supersedes it.

Product behavior, business rules, architecture, security, data, and
synchronization remain governed by their respective authoritative
specifications.

Any future design change should be made in this order:

**Reference/approved decision → Design token/component update → affected
screens**

not:

**Individual screen tweak → duplicated tweak elsewhere → inconsistent
system**

The long-term objective is that visual design can evolve without
destabilizing Logic, Structure, data, or architecture.

------------------------------------------------------------------------

## 33. Definition of Done --- Visual Design

A visual task is complete only when:

-   it is visually coherent with the approved modern references;
-   it uses the centralized design system;
-   it looks intentional rather than default-generated;
-   it is clean and attractive;
-   it is easy to scan and operate;
-   it remains consistent across related screens;
-   it works in Hebrew RTL and English LTR;
-   it remains usable on Android and iPhone;
-   it preserves accessibility;
-   it does not alter Logic or Structure unless separately authorized;
-   it introduces no unexplained visual invention.

**Target experience:** a calm, beautiful, modern operational application
in which the user immediately understands what is happening, what
matters, and what action is available.
