# Bannaa Design Reference For Forem

Source of truth:

```text
https://github.com/moeghashim/bannaa/blob/main/DESIGN.md
```

This file is a compact implementation reference for applying the Bannaa design language to the Forem deployment without vendoring or forking the separate Bannaa frontend.

## Direction

Bannaa is Arabic-first and bilingual. Forem UI work should preserve RTL behavior and use CSS logical properties where possible so Arabic and English layouts mirror cleanly.

The visual language is terminal brutalism:

- dense and functional,
- operator-console feel,
- sharp squared edges,
- flat surfaces,
- high contrast,
- technical metadata where useful,
- minimal deliberate motion,
- no decorative softness.

Avoid:

- rounded marketing cards,
- soft shadows,
- glass blur,
- decorative gradients,
- oversized airy landing-page spacing,
- extra accent colors,
- pill buttons except for tag chips.

## Color Tokens

Use one accent per theme.

Dark theme:

```css
--bannaa-bg: #0a0a0a;
--bannaa-surface: #111111;
--bannaa-recessed: #161616;
--bannaa-line: #242424;
--bannaa-line-strong: #2e2e2e;
--bannaa-text: #f2f2ef;
--bannaa-muted: #9a9a93;
--bannaa-subtle: #6b6b66;
--bannaa-accent: #d4ff3a;
--bannaa-accent-ink: #0a0a0a;
--bannaa-warning: #ff6a3d;
--bannaa-ok: #8ae66e;
```

Light theme:

```css
--bannaa-bg: #ffffff;
--bannaa-surface: #f6f6f4;
--bannaa-recessed: #eeece6;
--bannaa-line: #e6e4dc;
--bannaa-line-strong: #c9c6bb;
--bannaa-text: #0e0e0c;
--bannaa-muted: #4a4740;
--bannaa-subtle: #8a8677;
--bannaa-accent: #ff6a3d;
--bannaa-accent-ink: #ffffff;
--bannaa-warning: #c94a1f;
--bannaa-ok: #2f6d2d;
```

Terminal panels keep the dark palette in both themes.

## Typography

Preferred type roles:

- Display: Rubik 800-900, only for large headings and stat numerals. Do not use below 22px.
- Body and all Arabic text: IBM Plex Sans Arabic 400-700.
- Technical metadata: JetBrains Mono 400-600, uppercase where appropriate, letter spacing around 0.1em-0.14em.

If a monospace container can contain Arabic, override it back to the body font because JetBrains Mono does not cover Arabic well.

## Components

Buttons:

- Primary buttons: accent fill, accent-ink text, 2px radius, 600 weight.
- Secondary buttons: transparent fill, 1px strong-line border, primary text.
- Ghost buttons: transparent, muted text, brighten on hover.
- No pill or circular icon buttons for normal actions.

Cards and containers:

- Flat surface.
- 1px hairline border.
- 2px radius.
- No shadow, no lift, no scale transform.
- Use a small accent corner notch sparingly for repeated card modules.

Inputs and forms:

- Stroke-only fields.
- Transparent fill.
- 1px strong-line border.
- Placeholder uses subtle text color.
- Browser focus behavior is acceptable unless accessibility requires a stronger custom state.

Tags:

- Tags/chips are the only pill-shaped component.
- 999px radius, 1px border, mono uppercase label, optional small accent pip.

## Layout

- Compact density by default.
- Fixed outer gutter: 24px.
- Max content width: 1440px.
- Use explicit grids, strong rules, and structural dividers.
- Prefer 1px section rules over whitespace-only separation.
- Body line-height around 1.5; display line-height around 0.92.
- Prefer CSS logical properties: `margin-inline-start`, `border-inline-start`, `inset-inline-end`, etc.

## Forem Application Notes

When applying this to Forem:

- Keep changes in `build/overlays/` and patch through `build/scripts/apply-bannaa-overlays.sh`.
- Do not edit live containers except for emergency recovery.
- Do not fork broad Forem templates unless an overlay stylesheet cannot express the change.
- Treat the current `bannaa_rtl.css` as RTL support, not the full brand theme.
- Add future brand CSS as an overlay file, then link it through the manifest and layout in the image build.
- Verify both `https://club.bannaa.ai/` and Arabic RTL rendering after every visual deployment.

## Current Gap

The live Forem deployment currently has Arabic locale/RTL support and the homepage renders `lang="ar" dir="rtl"`, but it does not yet fully implement the Bannaa terminal-brutalist visual system. That should be a follow-up brand-theme overlay, not ad hoc edits on the VPS.
