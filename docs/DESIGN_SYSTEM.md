# UMAN design system

Authority: owner direction, 2026-09-19. Classic, clean, simple, modern,
professional. This is the single active visual authority; historical Breslov
assets remain preserved but do not govern screens. No decorative religious theme.
Implementation tokens live in `lib/presentation/design_system.dart`.

## Tokens

| Role | Light value |
|---|---|
| Primary / on primary | #244A73 / #FFFFFF |
| Secondary | #526579 |
| Background / surface | #F5F7FA / #FFFFFF |
| Text / secondary text | #17212B / #52606D |
| Border | #CBD2D9 |
| Success / warning / error / information | #23633B / #805500 / #B3261E / #244A73 |

Dark mode uses Material's centrally generated dark color scheme from the same
primary seed; never reuse dark text on dark surfaces. Status always includes
words and, where appropriate, icons. Color alone must not convey meaning.

Typography uses platform sans-serif with Hebrew fallback. Material semantic
roles: page title 24/32, section title 20/28, card title 18/26, body 16/24,
secondary body 14/20, label 14/20, caption 12/18 dp. Titles weight 600; body 400.
Do not download a new font dependency merely for decorative styling.

Spacing scale: 4, 8, 12, 16, 24, 32 dp. Screen padding 24, compact padding 16;
form width at most 640, content width at most 960. Field/section gaps 16/24.
Buttons and interactive icons: minimum 48×48 dp; normal field minimum 56 dp.
Heights are minimums, never clipping constraints for scaled or wrapped text.
Buttons/fields radius 8, cards 12, dialogs 16. Cards are flat with a subtle
border, elevation 0; modal elevation 3. No screen-specific shadows.
Fields use persistent labels and outlined borders; errors appear adjacent to
the field or in a clearly announced form summary. Destructive actions require
specific confirmation. Disabled actions explain the relevant state.

## Layout and accessibility

Use SafeArea, scrollable forms, keyboard insets and logical directional padding.
Hebrew UI is RTL; English UI is LTR. Runtime language switching must preserve
source text and open drafts. Dates, ISO currency codes, email and phone fields
use isolated LTR direction. Hebrew names use RTL. Mixed-direction display goes
through one BidiTextFormatter helper; never alter stored strings or scatter
directional control characters through screens.

Support OS text scaling without clamping; verify at 200%, narrow phones and
landscape. Controls have semantic labels, keyboard traversal and visible focus.
Maintain WCAG AA text contrast, 48 dp targets and readable error/status labels.
No fixed-height text containers. Verify light/dark, Hebrew/English, screen reader,
keyboard and physical devices independently; definition is not test evidence.

## Delivery boundaries

This establishes tokens, not decorative polish or visual sign-off. Current
English foundation UI is not bilingual completion. Future components must use
these tokens and theme roles; change global values centrally. A development
component playground is deferred until more shared components exist.
