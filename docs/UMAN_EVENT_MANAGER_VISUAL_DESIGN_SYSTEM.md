# UMAN EVENT MANAGER — VISUAL DESIGN SYSTEM

**Status:** Authoritative visual-design instruction  
**Reference source:** `assets/design_reference/modern`  
**Design direction:** Classic · Modern · Clean · Calm · Operational  
**Scope:** Visual Design only unless a separate product/structure instruction explicitly says otherwise.

## 1. Purpose

This document defines the visual language of UMAN EVENT MANAGER from the approved `modern` reference images.

The goal is not to imitate one screenshot mechanically. The goal is to preserve the coherent visual system visible across the approved references and apply it consistently throughout the application.

The application must feel beautiful, intentionally designed, modern without being fashionable for its own sake, clean without becoming sterile, calm while making operational priorities obvious, professional, trustworthy, easy to scan on a phone, comfortable for repeated daily use, natural on Android and iPhone, and coherent in Hebrew RTL and English LTR.

The UI is an operational command center. Information and actions take priority over decoration.

## 2. Source of Truth — No Invention

The images in `assets/design_reference/modern` are the visual reference set.

1. Inspect the approved reference images before making visual decisions.
2. Extract recurring visual rules rather than copying isolated accidents from one screenshot.
3. Prefer patterns consistent across the reference set.
4. Do not introduce another visual language because a developer, agent, package, or generated component has a different default style.
5. Do not add decorative elements, gradients, colors, shadows, icon styles, illustrations, textures, or effects not justified by the established system.
6. Do not guess exact visual constants when they have not been measured. Measure from the references where possible, define the result once as a token, and reuse it.
7. When references do not determine a detail, use an existing design-system token or the least disruptive platform-consistent solution. Do not create a new style family.
8. New screens must look as if designed together with the existing screens.

Once encoded, the centralized design system is the implementation source of truth. Individual screens must not override it casually.

## 3. Mandatory Separation of Layers

### Logic
Functionality, state, data, validation, synchronization, permissions, business rules, calculations, persistence, and domain behavior.

### Structure
Which sections exist, information hierarchy, ordering, navigation, flows, and which actions/data are exposed.

### Visual Design
Colors, typography, spacing, padding, radii, borders, surfaces, cards, buttons, fields, icons, shadows, visual density, and presentation styling.

A visual redesign modifies **Visual Design only** unless explicitly authorized otherwise. Never improve design by silently changing behavior, removing information, adding functionality, changing navigation/workflow, changing data/state architecture, moving/deleting structural sections, or altering permissions/synchronization. Document structural issues separately.

## 4. Core Visual Character

The approved direction is **classic, simple, clean, modern, professional, and calm**.

Communicate clarity before decoration; confidence without heaviness; generous but efficient spacing; strong hierarchy; restrained color; refined cards/surfaces; readable typography; soft controlled depth; clear actions; operational status at a glance.

Avoid loud saturated full-screen color, excessive gradients, dominant decorative Breslov styling, cartoonish components, oversized ornamental icons, excessive shadows, decorative glassmorphism, crowded dashboards, tiny text, excessive borders, competing accents, inconsistent card styles, and generic unmodified Material defaults that conflict with the reference language.

## 5. Visual Hierarchy

Every screen should make four things understandable within seconds: Where am I? What is the important context? What requires attention? What can I do here?

Standard hierarchy:

**App/brand context → Screen title/subtitle → contextual summary/banner → key status/summary → primary content → primary action → persistent navigation**

Not every screen requires every layer, but hierarchy must remain recognizable.

## 6. Color System

Use a restrained professional palette.

**Primary:** deep navy/professional blue for primary actions, selected navigation, important interactive emphasis, selected states, controlled brand emphasis, and appropriate banner overlays. It must not flood every surface.

**Warm accent:** soft gold/sand as a restrained secondary accent where supported by the references. It is not a second primary color.

**Neutrals:** warm off-white/light-neutral page backgrounds, white or subtly differentiated cards, soft-gray secondary surfaces, dark-neutral primary text, muted secondary text.

**Semantic:** dedicated success, warning, danger, and information tokens. Semantic colors are functional, not decoration. Red/orange appears only for genuine warning/attention. Severity must never rely on color alone.

No screen may introduce ad-hoc color literals. Centralize tokens such as `backgroundPrimary`, `backgroundSecondary`, `surfacePrimary`, `surfaceElevated`, `textPrimary`, `textSecondary`, `textMuted`, `borderSubtle`, `primary`, `primaryPressed`, `accentWarm`, `success`, `warning`, `danger`, `info`, `overlayStrong`, and `overlaySoft`.

Exact values are established centrally from the approved references.

## 7. Typography

Typography should feel editorially refined in headings and extremely readable in operational UI.

The reference direction supports a refined serif/display treatment for selected high-level titles/editorial moments plus a clean sans-serif UI face for operational text, controls, data, forms, lists, labels, and dense information.

Centralize display/hero, screen title, section title, card title, body, secondary body, label, metadata, metric/value, button, and caption styles.

Hierarchy comes from size, weight, spacing, and contrast—not random colors. Keep body text comfortable on phones, secondary text quieter but legible, metrics scannable, bold restrained, all-caps exceptional, line height suitable for Hebrew and English, and layouts tolerant of text expansion.

## 8. Spacing and Layout Rhythm

Use a centralized spacing scale; no arbitrary padding accumulation.

Provide comfortable page margins, consistent section spacing, tighter spacing for related label/value pairs, consistent card padding, breathing room around headings, and deliberate primary/secondary action separation.

Avoid cramped screens and oversized empty areas. Use logical `start/end` and `leading/trailing`, never hard-coded directional assumptions.

## 9. Cards and Surfaces

Cards are light, calm, slightly separated, consistent, touch-friendly, and information-first.

Use medium consistent radii, subtle borders and/or restrained elevation, controlled shadow, efficient internal padding, and clear title/content/action hierarchy.

Do not vary radii arbitrarily, use dramatic shadows, nest cards without reason, outline everything, or turn every datum into a card. Use shared primitives and explicit variants.

## 10. Contextual Summary Banners

The compact contextual banner is a **first-class reusable component**, not decoration.

Canonical family: `EventHeroBanner`, `ModuleSummaryBanner`, `ContextSummaryBanner`. These may share one underlying component with explicit variants.

Purpose: provide immediate visual context and summarize the most useful current-screen information.

May contain a contextual image, controlled dark/blue readability overlay, title, short subtitle, date/context, compact metrics, and an optional relevant action.

Keep banners compact; use contextually relevant imagery; guarantee text readability; use consistent overlays; keep metrics concise; do not turn banners into full dashboards; do not place text over busy imagery without sufficient contrast. Radius, padding, overlay, typography, height family, and placement are shared tokens/components. Variants change content, not visual DNA.

## 11. Summary Metrics and Status

Operational summaries must be scannable without resembling a decorative analytics dashboard. Use concise values, short labels, restrained indicators, consistent grouping, and clear tap targets when actionable. Charts exist only when they answer a useful operational question. Warnings should be noticeable without making the app permanently alarming.

## 12. Buttons and Actions

Maintain primary, secondary, tertiary/text, destructive, and appropriate icon-only variants. Prefer one obvious primary action per local context. Primary uses the identity color; destructive styling is reserved for destructive actions. Centralize heights, radii, typography, icon spacing, loading, disabled, and pressed states. Touch targets are at least 48×48dp. Avoid rows of equal-weight competing buttons.

## 13. Forms and Inputs

Forms must be calm and predictable: consistent field height/radius, clear labels, focus state, validation state, readable helper/error text, correct keyboard/input type, and logical grouping. Placeholder text is not the sole label. Validation explains the issue without turning the whole form red. Long forms remain segmented/scannable. Mixed Hebrew/English data must display naturally.

## 14. Lists

Lists prioritize scanning. Make primary identity obvious and metadata quieter. Standardize row density, leading/trailing behavior, separators/spacing, status placement, and actions. Do not expose every field in a row; details belong in detail views.

## 15. Navigation

Navigation is stable, predictable, and visually quiet. Bottom navigation, where used, keeps a stable location, coherent icon family, unmistakable selected state, restrained labels/badges, and shared treatment across modules. Do not rearrange primary navigation based on temporary state.

## 16. Icons

Use one coherent icon family/style with consistent weight and alignment. Icons support comprehension, use semantic color only when meaningful, and never dominate decoration. Do not casually mix filled, outlined, cartoon, and custom styles. Ambiguous icons need labels/accessibility descriptions.

## 17. Images and Illustration

Use images purposefully for contextual banners, event/location context, and approved moments that improve recognition/atmosphere. Do not use large imagery as wallpaper behind operational data. Do not introduce a Breslov-themed decorative layer across the app. Contextually appropriate approved religious/location imagery may appear, while the base identity remains classic, neutral, modern, and professional.

## 18. RTL, LTR, and Bilingual Design

Hebrew RTL and English LTR are equal first-class modes.

Use logical directional layout; mirror directional layout appropriately; do not unnecessarily mirror universal non-directional symbols; handle mixed Hebrew/English; keep numbers, dates, currencies, phones, flight numbers, and codes readable; verify cards, banners, lists, navigation, forms, dialogs, and empty states in both directions. Never design LTR and merely flip it later.

## 19. Light and Dark Themes

Support centralized light and dark themes. Light mode remains readable in bright conditions. Dark mode preserves hierarchy, avoids harsh pure-black/pure-white where softer surfaces are established, maintains semantic clarity, uses restrained surface differentiation, and preserves banner/image readability. Dark mode comes from tokens, not mechanical inversion.

## 20. Accessibility and Usability

Beauty never overrides usability. Require 48×48dp minimum touch targets, sufficient contrast, readable body sizes, no color-only critical meaning, clear focus/pressed/disabled/error states, text-scaling tolerance, meaningful semantics, legible metadata, and no precision-tap interactions. The UI must remain understandable under stress, outdoors, and during active operations.

## 21. Loading, Empty, Error, and Sync States

Design system states consistently.

Loading: calm skeleton/progress treatment preserving layout stability; avoid unnecessary full-screen blockers.

Empty: explain what is empty and provide the relevant next action when useful.

Error: state the problem clearly and expose recovery; use danger styling proportionally.

Sync/connectivity: surface only when useful, clearly and without overwhelming normal operation. Do not create persistent alarm for healthy background behavior.

## 22. Dialogs, Sheets, Menus, and Feedback

Use platform-appropriate interaction surfaces while preserving the shared language. Confirmations are concise; destructive confirmations explicit; bottom sheets have clear hierarchy/touch targets; snackbars/toasts are transient only; menus do not hide critical workflow steps; avoid modal surfaces when inline interaction is clearer.

## 23. Responsive Mobile Behavior

Primary target: phones on Android and iPhone. Account for narrow widths, safe areas, keyboard, long Hebrew/English strings, text scaling, varying heights, and platform insets. Never optimize only for one test phone. Avoid fixed positioning that breaks with content.

## 24. Centralized Design Tokens

Centralize color palette, semantic colors, typography, spacing, page/card padding, radii, borders, shadows/elevation, button/input dimensions, icon sizes, navigation dimensions, banner variants, animation durations/curves where used, and light/dark mappings.

Do not scatter magic numbers. A change to card radius, background, primary color, standard padding, or button height must not require editing every screen.

## 25. Shared Components

Create/reuse shared presentation components where applicable: page shell/scaffold, screen header, section header, standard card, status card, summary metric, empty/error/loading states, primary/secondary/destructive buttons, form wrappers, status chip/badge, list row, confirmation surface, `EventHeroBanner`, `ModuleSummaryBanner`, `ContextSummaryBanner`, and bottom navigation.

Do not build per-module near-duplicates. Variants are explicit and documented.

## 26. Screen Composition Rules

General rhythm: stable app/navigation context → clear screen title → concise subtitle if needed → compact contextual banner/summary when useful → critical attention items before low-priority information → grouped operational content → clear primary action → stable navigation.

Do not force purposeless components onto a screen. Consistency means consistent principles, not identical layouts.

## 27. Information Density

Show what is needed for the current decision; progressively reveal secondary details; use typography/spacing before containers; keep metadata subordinate; avoid giant cards for tiny information; avoid unreadably compressed records; prefer clear grouping over decorative separation.

## 28. Motion

Motion clarifies state change or spatial relationship. Use subtle transitions for state/screen changes, expansion/collapse, loading completion, and confirmation feedback. Avoid decorative bouncing, long animations, delayed action, and inconsistent motion. Operational speed wins.

## 29. Visual QA Checklist

Every implemented/restyled screen must be checked against `assets/design_reference/modern` for centralized tokens, typography hierarchy, cards, buttons, fields, spacing, banner readability, absence of unjustified decoration/Breslov-heavy styling, Hebrew RTL, English LTR, mixed-direction data, light/dark theme where supported, text scaling, 48×48dp touch targets, long content, empty/loading/error states, varying phone sizes, Android, iOS compatibility, and preservation of Logic/Structure boundaries.

A screen is not finished merely because it compiles.

## 30. Implementation Workflow

1. Read this document.
2. Inspect `assets/design_reference/modern`.
3. Inspect centralized theme/tokens/shared components.
4. Identify Logic vs Structure vs Visual Design impact.
5. For visual tasks, keep Logic and Structure unchanged.
6. Reuse/extend centralized tokens/components.
7. Implement the smallest coherent visual change.
8. Test Hebrew RTL and English LTR.
9. Test representative phone sizes.
10. Run project-required static/tests.
11. Compare visually with the reference set.
12. Document genuinely unresolved design decisions instead of inventing them.

## 31. Prohibited Patterns

Do not hard-code visual constants throughout screens; create per-screen mini themes; change Logic during styling; change Structure without explicit authorization; introduce package-default palettes; use random stock imagery; add unjustified gradients/effects; overuse status colors; rely on color alone; vary radii/button heights arbitrarily; mix icon styles; ship one-direction-only layouts; treat iOS as an afterthought; duplicate shared components; or create temporary visual hacks bypassing the design system.

## 32. Design Governance

This document is the authoritative visual-design instruction for the modern direction. When another document conflicts on **visual styling**, this document governs unless a newer explicitly approved design decision supersedes it.

Product behavior, business rules, architecture, security, data, and synchronization remain governed by their respective authoritative specifications.

Future design changes follow:

**Reference/approved decision → Design token/component update → affected screens**

not:

**Individual screen tweak → duplicated tweak elsewhere → inconsistent system**

The long-term objective is visual evolution without destabilizing Logic, Structure, data, or architecture.

## 33. Definition of Done — Visual Design

A visual task is complete only when it is coherent with the approved modern references, uses the centralized design system, looks intentional rather than default-generated, is clean and attractive, is easy to scan and operate, remains consistent across related screens, works in Hebrew RTL and English LTR, remains usable on Android and iPhone, preserves accessibility, does not alter Logic or Structure unless separately authorized, and introduces no unexplained visual invention.

**Target experience:** a calm, beautiful, modern operational application in which the user immediately understands what is happening, what matters, and what action is available.
