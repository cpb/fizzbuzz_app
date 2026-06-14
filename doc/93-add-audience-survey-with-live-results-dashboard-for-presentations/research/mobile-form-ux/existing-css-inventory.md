# Existing CSS Inventory

Source: `app/assets/stylesheets/application.css` — "Johari design language"

---

## Design Tokens (CSS custom properties)

```css
:root {
  --cream:         #F5EDD6;   /* page background */
  --teal:          #4A9B8E;   /* primary action / fizz color */
  --peach:         #E8855A;   /* secondary / buzz color */
  --blush:         #D4849C;   /* accent */
  --mint:          #7AC4B6;   /* accent */
  --charcoal:      #2C2C2C;   /* text, border */
  --border:        #2C2C2C;   /* all borders use same charcoal */
  --grid:          rgba(44,44,44,0.06);  /* faint list dividers */
  --drawer-height: 80px;      /* fixed bottom toolbar height */
}
```

---

## Base Reset and Body

| Rule | Value | Notes |
|---|---|---|
| `*, *::before, *::after` | `box-sizing: border-box` | Universal box model — safe |
| `body` | `background: var(--cream)` | Warm cream background |
| `body` | `font-family: 'Courier New', Courier, monospace` | Monospace throughout |
| `body` | `margin: 0; min-height: 100vh` | Full-height body |
| `h1` | `font-family: Arial/Helvetica sans-serif; font-weight: 900; text-transform: uppercase; font-size: 2.5rem` | Bold condensed headers |
| `a` | `color: var(--teal); text-decoration: none` | Teal links |
| `label` | `font-size: 0.75rem; text-transform: uppercase; letter-spacing: 0.05em` | Small-caps labels |

**No media queries anywhere in the file.** The app is not yet responsive.

---

## Layout

| Class | Description |
|---|---|
| `main.page-content` | `padding: 2rem` — main content area, no max-width constraint |
| `.bottom-drawer` | Fixed bottom bar: `height: 80px`, flex row, `padding: 0 2rem`, `gap: 1rem` |
| `.sr-only` | Screen-reader only (standard visually-hidden pattern) |

---

## Buttons

| Class | Description |
|---|---|
| `.btn` | Square-bordered button: `border: 1px solid charcoal`, `border-radius: 0`, transparent bg, uppercase monospace text, `padding: 0.45rem 0.9rem`. Hover inverts to charcoal bg / cream text. |
| `.btn-form` | Inline wrapper for `button_to` `<form>` element (display: inline, no margins) |

**Gap:** `.btn` has no minimum touch target. `0.45rem + 1 line-height ≈ ~28px` — below the 44px minimum for mobile touch targets.

---

## Drawer Form (existing form pattern)

Used in `fizz_buzz/start.html.erb` — a small utility form in the fixed bottom bar.

| Element | Styles |
|---|---|
| `.drawer-form` | Flex row, `align-items: center`, `gap: 0.6rem` |
| `.drawer-form label` | `font-size: 0.7rem` |
| `.drawer-form input[type="number"]` | `border: 1px solid charcoal`, `border-radius: 0`, `width: 5rem`, `padding: 0.4rem` |
| `.drawer-form input[type="number"]:focus` | Light charcoal tint background |
| `.drawer-form input[type="checkbox"]` | `accent-color: var(--teal)`, `width: 1rem; height: 1rem` |
| `.drawer-form .checkbox-group` | Flex row with label + checkbox |

**Mobile gap:** The drawer form puts label + number input + checkbox + button in a horizontal flex row that will overflow on narrow phone screens (≤375px).

---

## New Link Form Pattern

Used in `links/new.html.erb`:

| Class | Styles |
|---|---|
| `.form-field` | `margin-bottom: 1rem` — vertical spacing between fields |
| `.form-field label` | `display: block; margin-bottom: 0.3rem` — label above input |
| `.form-field input[type="text"], input[type="url"]` | `border: 1px solid charcoal`, `border-radius: 0`, `width: 24rem`, `font-size: 0.9rem`, `padding: 0.4rem 0.5rem` |
| `.form-field input:focus` | Light charcoal tint |

**Mobile gap:** `width: 24rem` (384px) will overflow viewport on phones (375px screen width). No `max-width` or `width: 100%` fallback.

---

## Results / FizzBuzz stream

| Class / Selector | Description |
|---|---|
| `#results` | Fixed-position list above drawer, flex column-reverse, scrollable |
| `.result` | Animated float-up item, `font-size: 1.5rem`, bold monospace |
| `.result--fizz/buzz/fizzbuzz/number` | Color variants using design tokens |
| `@keyframes float-up` | translateY(40px)→0, opacity 0→1, 0.5s ease-out |

---

## Links Page

| Selector | Description |
|---|---|
| `#links` | `list-style: none`, `padding: 0`, `margin: 1rem 0` |
| `#links li` | `border-bottom: 1px solid var(--grid)`, `padding: 0.6rem 0`, `font-size: 0.9rem` |
| `#qr_code_container` | `margin: 1.5rem 0` |
| `#qr_code_container img` | `border: 1px solid charcoal`, `display: block` |

---

## Flash

| Class | Description |
|---|---|
| `.flash-notice` | `font-size: 0.75rem`, uppercase, teal color, `margin-bottom: 1rem` |

---

## What Is Already Mobile-Friendly

- `box-sizing: border-box` on everything
- `viewport` meta tag in layout (`width=device-width, initial-scale=1`)
- `apple-mobile-web-app-capable` and `mobile-web-app-capable` meta tags
- `apple-touch-icon` link tag
- `body { margin: 0; min-height: 100vh }` — no unwanted overflow
- `main.page-content { padding: 2rem }` — reasonable padding (shrinks content area, doesn't hide it)
- `.sr-only` pattern available

## What Is NOT Mobile-Friendly (Gaps)

| Gap | Impact |
|---|---|
| No media queries at all | Nothing adapts to screen width |
| `.form-field input { width: 24rem }` | Overflows 375px phone viewport |
| `.btn` padding ~28px effective height | Below 44px touch target minimum |
| `.drawer-form` horizontal flex | Overflows narrow screens |
| `.bottom-drawer { padding: 0 2rem }` | 80px drawer reserves space; survey forms should NOT inherit this layout |
| No `textarea` styles | Free-text survey answers have no defined style |
| No `select` styles | Not needed but confirms no existing pattern |
| No radio/checkbox group layout (only `.drawer-form .checkbox-group`) | Too small for survey form use — not touch-friendly |
| No grid/flex utilities for Likert matrix | Must be added from scratch |
| No progress indicator styles | Must be added |
