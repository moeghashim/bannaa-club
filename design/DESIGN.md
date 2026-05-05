# Design System: Bannaa

**Project ID:** bannaa-v3

This document is the single source of truth for Bannaa's visual language,
written in the [Stitch DESIGN.md format][stitch]. It pairs atmospheric
descriptions with precise tokens so AI tooling and human contributors can
both generate and verify new screens. Keep it in sync whenever you add or
replace a brand asset.

[stitch]: https://github.com/google-labs-code/stitch-skills/blob/main/skills/design-md/SKILL.md

## 1. Visual Theme & Atmosphere

Bannaa is a bilingual (Arabic-first) technical learning platform whose
visual language is **Terminal Brutalism**. The interface reads like a
dense operator console rather than a soft marketing page: sharp
squared-off edges, high-contrast blocks of ink and canvas, monospace
annotation layered over a bold display face, and generous technical
metadata (status bars, coordinates, version strings) surfaced
unapologetically.

The atmosphere is **dense and functional**, never airy. Surfaces are
flat — no blurred glass, no drop shadows, no gradients except a single
radial wash of the accent colour behind the hero. Negative space is
structural: it exists so hard-edged rules can breathe, not to soften
the composition. Motion is minimal and deliberate (a fading four-stage
pipeline terminal, a slow marquee scroll, a blinking cursor);
decoration is absent.

The palette is **binary and confident** — near-black paper with a
single electric accent in dark mode, near-white paper with a warm
industrial accent in light mode — so every colour on screen carries
a functional role, never pure decoration.

## 2. Color Palette & Roles

Two themes share one token shape; the active theme is toggled by
`data-theme="light"` on `<html>`. All colours are declared as CSS
custom properties in `app/globals.css`.

### Dark theme (default)

- **Ink Black (`#0a0a0a`)** — primary canvas; the page itself.
- **Graphite 800 (`#111111`)** — raised surfaces: cards, marquee strip, status bar.
- **Graphite 700 (`#161616`)** — recessed wells: track-card artwork frames.
- **Line 900 (`#242424`)** — low-contrast hairlines; defines structure without dominating.
- **Line 800 (`#2e2e2e`)** — medium-contrast borders on interactive elements.
- **Off-White Ink (`#f2f2ef`)** — primary text and the frame of the logo mark. Warm, faintly yellowed.
- **Ash Gray (`#9a9a93`)** — secondary text and supporting copy.
- **Pebble Gray (`#6b6b66`)** — tertiary metadata: timestamps, counters, mono labels.
- **Electric Lime (`#d4ff3a`)** — the only accent. Reserved for the primary button fill, the centered block of the logo mark, the active phase of the pipeline terminal, section eyebrow pips, and the selected tab underline. Carries all attention; never decorative.
- **Accent Ink (`#0a0a0a`)** — text colour on top of the lime accent fill.
- **Warning (`#ff6a3d`)** and **OK (`#8ae66e`)** — terminal-only indicators (traffic-light dots, status glyphs). Never used as page-level accents.

### Light theme

- **Paper White (`#ffffff`)** — primary canvas.
- **Bone 50 (`#f6f6f4`)** — raised surfaces.
- **Linen 100 (`#eeece6`)** — recessed wells.
- **Line 100 (`#e6e4dc`)** and **Line 300 (`#c9c6bb`)** — structural rules, borders.
- **Carbon Ink (`#0e0e0c`)** — primary text and logo frame.
- **Dust (`#4a4740`)** — secondary text.
- **Sand (`#8a8677`)** — tertiary text.
- **Industrial Orange (`#ff6a3d`)** — the only accent.
- **Accent Ink (`#ffffff`)** — text colour on the orange accent fill.
- **Warning (`#c94a1f`)** and **OK (`#2f6d2d`)** — terminal-only.

Terminal panels hold their **dark palette in both themes** deliberately,
as a visual signifier that "this is machinery."

## 3. Typography Rules

Three families, loaded via `next/font/google` in `app/layout.tsx` and
exposed as CSS variables.

- **Rubik 800–900 (display)** — reserved for the hero headline, section
  titles, and oversized stat numerals. Tight tracking (`-0.02em`),
  compressed line-height (`0.92`), and dramatic scale
  (`clamp(48px, 7.5vw, 128px)` in the hero) give the page its
  brutalist weight. Never use Rubik below 22px.
- **IBM Plex Sans Arabic 400–700 (body)** — the default for paragraphs,
  UI copy, button labels, and **any Arabic text anywhere in the app**.
  JetBrains Mono has no Arabic glyphs, so monospace containers that
  may contain Arabic must override back to this face (see the pipeline
  terminal's plan rows, where `.stage-plan__row .k` and `.v` explicitly
  reset to `var(--f-body)`).
- **JetBrains Mono 400–600 (mono)** — exclusively technical context:
  eyebrow labels, terminal chrome, tag pills, status-bar strings, stat
  sublabels, timestamps, coordinates. Letter-spaced generously
  (`0.1em`–`0.14em`) and uppercased to reinforce the operator-console feel.

## 4. Component Stylings

### Buttons

- **Primary:** Sharp, **squared-off edges** (2px corner radius — effectively a rectangle). Filled with the active accent colour; label in the accent-ink colour; `font-weight: 600`. On hover, brightness lifts by ~8% and a 4px-wide diffused accent glow (`accent 20%`) expands around the element. Label casing tracks the content — uppercase is not forced.
- **Secondary / outline:** Transparent fill, 1px border in the medium line colour, label in primary ink. On hover, the border darkens to the primary ink colour. Same 2px corners.
- **Ghost:** Transparent border and fill; dim text that brightens to primary ink on hover. For tertiary actions only (e.g., "Sign in" in the nav).
- No rounded buttons, no pill buttons, no icon-only circular buttons.

### Cards and Containers

- Flat surfaces with a single hairline border. 2px corner radius. **No shadow** — elevation is communicated by stepping the background one tier (`--bg` → `--bg-2`) and by a small bracket-style accent-coloured corner notch (`.card .corner`) anchored to the top-inline-end corner of each card.
- On hover, the border colour steps up one tier (`--line` → `--line-2`). No lift, no scale transform.
- Padding scales with density: `calc(20px * var(--density))` where `--density: 0.85` (compact) across the design.

### Inputs and Forms

- **Stroke-only.** 1px border in the medium line colour, transparent fill, no inner shadow.
- The CTA email field shares a single stroke with its submit button, forming one rectangle split in two by a vertical line (no radius between them).
- Placeholder text renders in the tertiary muted colour.
- Focus state is implicit — the caret is the signal. No custom focus ring is added (the browser default is acceptable here).

### Terminal Panels

- A distinct UI primitive. Dark `--term-bg` background (held dark in
  **both** themes), 1px medium-line border, 2px radius.
- **Chrome row:** 11px monospace title in dimmed ink on the start edge;
  three 8px traffic-light dots (warning / amber / ok) on the end edge.
- **Pipeline variant:** four phase labels across the top; the four
  stages (Plan / Design / Agent / Site) stack absolutely over each
  other and crossfade on a 0.4s opacity transition; the active stage's
  label block tints to translucent accent (`accent 8%`).
- **Status row:** 10px monospace at the bottom showing current phase
  status and a "● live" ok-coloured dot.

### Tags (Chips)

- **Pill-shaped** (999px radius — the only place curved edges appear).
  1px border in the medium line colour, 10.5px uppercase mono label
  with `0.1em` tracking. A 5px accent-coloured circle "pip" leads the
  label. A `.warn` modifier flips the pip to the warning colour. A
  `.solid` modifier inverts to a filled accent pill (used sparingly).

### Status Bar

- A sticky utilitarian ribbon at the top of every page. Mono 11px,
  dimmed text, a pulsing accent-coloured dot on the start edge, and a
  live 24-hour clock plus theme toggle on the end edge. Backdrop-blurred
  at 90% opacity so page content bleeds faintly through.

### Navigation

- Flat bar under the status bar, separated by a 1px hairline. Brand mark
  + wordmark on the start edge; anchor links, language switch, ghost
  CTA, and primary CTA on the end edge. Active link pill uses `--bg-2`
  fill with a `--line-2` border.

## 5. Layout Principles

- **Fixed outer gutter:** 24px on all sides, scaling up to a 1440px max
  content width (`.wrap`). No fluid containers beyond this cap — the
  design holds the same column widths on any display.
- **12-column implicit grid in the hero** (a 7/5 split between copy and
  pipeline terminal); 3-column and 4-column explicit grids everywhere
  else (tracks, concepts, templates, footer).
- Grids lean on **CSS logical properties** (`border-inline-start`,
  `inset-inline-end`, `margin-inline-start`, …) so every layout mirrors
  cleanly between the `/en` and `/ar` routes without duplicate rules.
- **Section heading pattern:** a small monospace eyebrow
  ("`/ 01 — TRACKS`"), a two-line display headline, and a right-aligned
  mono paragraph with an optional inline underlined link. Every section
  that uses this pattern is separated from the next by an explicit 1px
  rule, never by whitespace alone.
- **Whitespace is structural.** Stat blocks sit snug against their
  inline dividers (`padding: 4px 20px`); section tops use
  `padding: 56px 0 24px` to create a single dominant breathing moment
  per section; the CTA uses `padding: 80px 24px` to punctuate the end
  of the page.
- **Density is "compact."** Body line-height is `1.5`, display is
  `0.92`. Card padding is `20px * 0.85`. Everything reads denser than
  a typical marketing site, on purpose.

---

## Appendix: Brand Assets

Not part of the Stitch spec — contributor-facing pointers to the files
that embody the system above.

### Logo / brand mark

The mark is a single solid 12-unit accent block, centered inside a
36-unit square frame with a 4-unit stroke, drawn on a 40×40 viewBox.
The inner block is 30% of the viewBox edge; the frame stroke is 10%.
It reads as "a block held inside a structure."

| File | Purpose | Frame | Block | Background |
| --- | --- | --- | --- | --- |
| [`public/bannaa-logo-dark.svg`](public/bannaa-logo-dark.svg) | Standalone dark-theme preview. | `#f2f2ef` | `#d4ff3a` | `#0a0a0a` |
| [`public/bannaa-logo-dark.png`](public/bannaa-logo-dark.png) | 512×512 rasterised PNG of the dark SVG. | — | — | — |
| [`public/bannaa-logo-light.svg`](public/bannaa-logo-light.svg) | Standalone light-theme preview. | `#0e0e0c` | `#ff6a3d` | `#ffffff` |
| [`public/bannaa-logo-light.png`](public/bannaa-logo-light.png) | 512×512 rasterised PNG of the light SVG. | — | — | — |
| [`app/icon.svg`](app/icon.svg) | Favicon served by Next.js convention. Dark variant. | `#f2f2ef` | `#d4ff3a` | `#0a0a0a` |
| [`components/site/brand-mark.tsx`](components/site/brand-mark.tsx) | Inline SVG component used in the site header and footer. Uses `currentColor` for the frame stroke and `var(--accent)` for the block, so it tracks theme automatically and has no baked-in background. | dynamic | dynamic | transparent |

### Regenerating PNGs

From the repo root:

```
rsvg-convert -w 512 -h 512 public/bannaa-logo-dark.svg  -o public/bannaa-logo-dark.png
rsvg-convert -w 512 -h 512 public/bannaa-logo-light.svg -o public/bannaa-logo-light.png
```

### Clear space and minimum size

- **Minimum rendered size:** 20 px tall. Below that the frame stroke
  loses fidelity — fall back to `app/icon.svg` only above that size.
- **Clear space:** at least one inner-block height (≈ `mark-size / 3.3`)
  on every side of the mark.
- **Do not** introduce a third colour, recolour the block outside the
  two defined variants, distort the aspect ratio, or add shadows,
  gradients, or outlines beyond the existing frame.

### Social media assets

Social assets live under [`public/social/`](public/social/) as PNGs
(no SVG sources checked in — regeneration notes below). They share
one design language: dark canvas, faint grid, the logo mark on the
RTL start edge, Arabic wordmark **بنّاء** in IBM Plex Sans Arabic,
and mono technical metadata (`BANNAA_OS // v3.0.1`,
`BANNAA.AI // MENA // AR`) in the corners. Horizontal banners keep
only the wordmark next to the icon (bottom-aligned). The portrait
cover (stacked layout) also carries the tagline **ابنِ ثم ابنِ أكثر**.

| Platform | Profile | Banner / cover | Size |
| --- | --- | --- | --- |
| TikTok | [`profile.png`](public/social/profile.png) | [`portrait-cover.png`](public/social/portrait-cover.png) | profile 1024×1024 · cover 1080×1920 |
| X | [`profile.png`](public/social/profile.png) | [`x-banner.png`](public/social/x-banner.png) | profile 1024×1024 · banner 1500×500 |
| Facebook | [`facebook-profile.png`](public/social/facebook-profile.png) | [`facebook-cover.png`](public/social/facebook-cover.png) | profile 1080×1080 · cover 1640×624 |
| Instagram | [`profile.png`](public/social/profile.png) | [`portrait-cover.png`](public/social/portrait-cover.png) (shared with TikTok; suitable for story / highlight cover) | profile 1024×1024 · story 1080×1920 |
| LinkedIn | [`profile.png`](public/social/profile.png) | [`linkedin-banner.png`](public/social/linkedin-banner.png) | profile 1024×1024 · banner 1584×396 |
| YouTube | [`youtube-profile.png`](public/social/youtube-profile.png) | [`youtube-banner.png`](public/social/youtube-banner.png) | profile 1080×1080 · banner 2048×1152 |

### Regenerating social PNGs

The PNGs are generated from inline SVGs rendered through Chrome
headless so Google Fonts (IBM Plex Sans Arabic + JetBrains Mono)
load correctly; a final top-left crop with ImageMagick removes a
~40 px baseline offset that Chrome introduces. Keep the source
SVGs out of the repo — rebuild from scratch when the design
changes. See `git log -- public/social/` for prior iterations if
you need a reference.
