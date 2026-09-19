# Style catalog — tokens, anchors, cascade rules and a worked example

Observed on production Landbot web chat v4 in September 2026. Verify on the target channel; a web-chat release can change internals.

## The model: three layers in one block

1. **Theme (tokens in `:root`, with `!important`).** The global look: background, text, borders, primary button, messages, inputs, calendar, header, typography.
2. **Anchors (plain rules, NO `!important`).** Specific parts, states and accents: the bot bubble background, focus/error, calendly, takeover, corners, hover.
3. **Scrollbars (global).** Browser bars; not an anchor, just standard CSS.

## The golden cascade rule (the key finding: when to use `!important`)

- **Anchors -> plain, WITHOUT `!important`.** The channel's Custom CSS is **unlayered**; web-chat's Tailwind v4 utilities live in `@layer utilities`. In CSS, **what is outside a layer beats what is inside**, no `!important` needed. Verified live.
- **Theme tokens -> `:root { --x: ... !important }`.** The v3 config sets those tokens **inline on `<html>`**, and an inline value is only beaten by `!important`. Without it, the tokens the config already touches (header, user bubble, font) don't change.
- **One-off exception:** if a specific property won't stick, a component may defend it with its own `!important`; there you add it to the anchor. Practical rule: emit plain; if a rule shows struck through in DevTools, add `!important`.

## Theme layer: the tokens (redefine in `:root` with `!important`)

| Group (control) | Tokens |
|---|---|
| Background (`background`) | `--background`, `--select-content-background`, `--select-item-background-default` |
| Text (`foreground`) | `--foreground`, `--muted`, `--muted-foreground`, `--select-item-color-default`, `--select-item-background-hover` |
| Border (`border`) | `--border`, `--select-content-border` |
| Primary / option button (`optionBackgroundColor` + `optionBorderColor` + `optionTextColor`) | `--button-color-primary-default`, `--button-border-color-primary-default`, `--button-font-color-primary-default` |
| Calendar | `--calendar-day-bg-selected`, `--calendar-day-color-selected`, `--calendar-day-color-today`, `--calendar-day-bg-today`, `--calendar-day-bg-hover`, `--calendar-day-color-default`, `--calendar-header-color`, `--calendar-day-color-outside`, `--calendar-day-color-disabled`, `--calendar-day-bg-range-middle` |
| Messages | `--chat-bubble-color-font-bot`, `--chat-bubble-surface-user`, `--chat-bubble-border-color-user`, `--chat-bubble-color-font-user` |
| Inputs / textarea / select | `--input-background-default`, `--textarea-background-default`, `--select-trigger-background-default`, `--input-border-color-default`, `--textarea-border-color-default`, `--select-trigger-border-default`, `--input-color-text-default`, `--textarea-color-text-default`, `--select-trigger-color-value`, `--select-trigger-color-placeholder` |
| Header | `--web-chat-header-background`, `--web-chat-header-text-color` |
| Typography | `--font-family-sans`, `--font-size` |

Note: **there is NO token for the bot bubble background** (only its text). That background goes through an anchor. The **selected calendar day** color comes from `--calendar-day-bg-selected` (token), not an anchor.

## Anchor layer: the catalog (39 parts)

Attributes: `data-lb-part` · `data-lb-interaction` · `data-lb-author` (`bot`/`user`) · `data-lb-variant` · `data-lb-state` (`active`/`error`/`selected`/`disabled`).

```
Message:   message · message-avatar · message-bubble · message-text
Options:   options-group · options-prompt · option-button
Multi:     option-checkbox · selection-counter · options-search
Inputs:    text-input · input-field · input-submit · input-error · free-text
           input-country-select · input-country-flag · date-picker
Media:     media · media-caption · media-download
Calendly:  calendly · calendly-prompt · calendly-cta · calendly-skip
Takeover:  takeover · takeover-avatar · takeover-title · takeover-subtitle
Chrome:    launcher · launcher-avatar · proactive-message ·
           proactive-message-bubble · proactive-message-close ·
           window · header · message-timestamp · options-list · branding
```

## Scrollbars (global, not an anchor)

This is a **pattern to adapt**, not a fixed snippet. Fill `<thumb>` and `<thumb-hover>` **from the brief's palette**, don't copy values from another example:
- `<thumb>`: a **mid gray** from the brief's scale. In a **dark** theme a dark gray (e.g. `#525252`); in a **light** theme a light gray (e.g. `#c6c6c6`).
- `<thumb-hover>`: **one contrast step** from the thumb (lighter in dark, darker in light).
- `track`: transparent, or the brief's surface.
- `width`/`radius`: match the style (e.g. `border-radius:0` if the brand is square like IBM).

The mechanism is doubled for compatibility: `scrollbar-width`/`scrollbar-color` (Firefox) + `::-webkit-scrollbar*` (Chromium/Safari). Global via `*` because there is no scrollbar anchor.

```css
/* Fill <thumb> and <thumb-hover> from the brief's palette (see above). */
* { scrollbar-width: thin; scrollbar-color: <thumb> transparent; }
*::-webkit-scrollbar { width: 8px; height: 8px; }
*::-webkit-scrollbar-track { background: transparent; }
*::-webkit-scrollbar-thumb { background: <thumb>; }
*::-webkit-scrollbar-thumb:hover { background: <thumb-hover>; }
```

## What the CSS does NOT reach (honest limits)

- **Forcing the options list height:** you can style `options-list` (color/border), but forcing its height from outside still overflows the chrome popover. **Leave the native scroll.**
- **Avatars:** they are **images** from the bot (bot config), not CSS color. CSS only styles the avatar container.
- **Multi-select checkboxes** (`option-checkbox`/`selection-counter`): only emitted with a **native** multi-choice node; the AI builder usually builds looped buttons and doesn't produce them.

## Brand preset: IBM Carbon

Values and fidelity rules (from IBM's design language / Carbon):

- **Typography:** IBM Plex Sans. Button labels in **Regular (400)**; 600 is reserved for headlines. `letter-spacing: 0.16px` on buttons (productive tracking).
- **Shape:** **square** corners (radius 0). No shadows; flat surfaces with a border.
- **Blue:** interactive `#0f62fe` (Blue 60); dark-theme accent `#4589ff` (Blue 50); **darker hover `#0353e9`** (button-primary-hover, in both light and dark).
- **Grays (Carbon scale):** `#161616` (100) · `#262626` (90) · `#393939` (80) · `#525252` (70) · `#6f6f6f` (60) · `#8d8d8d` (50) · `#a8a8a8` (40) · `#c6c6c6` (30) · `#e0e0e0` (20) · `#f4f4f4` (10).
- **Error:** `#da1e28` (light) / `#fa4d56` (Red 40, dark).
- **Fields:** Carbon style = **bottom border only** (`border:none; border-bottom:1px solid <gray>`) that turns blue on focus.
- **Whitespace:** generous (2x Grid). More padding on buttons (`12px 16px`), bubbles and cards.

## Full example: IBM Carbon dark

```css
/* IBM Carbon dark - THEME (:root, !important) + ANCHORS (plain) + SCROLLBARS */
@import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&display=swap');

:root {
  --background:#161616 !important;
  --select-content-background:#262626 !important;
  --select-item-background-default:#262626 !important;
  --foreground:#f4f4f4 !important;
  --muted:#8d8d8d !important;
  --muted-foreground:#c6c6c6 !important;
  --select-item-color-default:#f4f4f4 !important;
  --select-item-background-hover:#393939 !important;
  --border:#393939 !important;
  --select-content-border:#393939 !important;
  --button-color-primary-default:#0f62fe !important;
  --button-border-color-primary-default:#0f62fe !important;
  --button-font-color-primary-default:#ffffff !important;
  --select-trigger-border-focus:#4589ff !important;
  --select-item-color-selected:#4589ff !important;
  --select-item-background-selected:#393939 !important;
  --calendar-day-color-default:#f4f4f4 !important;
  --calendar-header-color:#f4f4f4 !important;
  --calendar-day-color-outside:#6f6f6f !important;
  --calendar-day-color-disabled:#525252 !important;
  --calendar-day-bg-hover:#393939 !important;
  --calendar-day-bg-today:#393939 !important;
  --calendar-day-bg-selected:#0f62fe !important;
  --calendar-day-color-selected:#ffffff !important;
  --calendar-day-color-today:#4589ff !important;
  --calendar-day-bg-range-middle:#1f3a5f !important;
  --chat-bubble-color-font-bot:#f4f4f4 !important;
  --chat-bubble-surface-user:#0f62fe !important;
  --chat-bubble-border-color-user:#0f62fe !important;
  --chat-bubble-color-font-user:#ffffff !important;
  --input-background-default:#262626 !important;
  --textarea-background-default:#262626 !important;
  --select-trigger-background-default:#262626 !important;
  --input-border-color-default:#6f6f6f !important;
  --textarea-border-color-default:#6f6f6f !important;
  --select-trigger-border-default:#6f6f6f !important;
  --input-color-text-default:#f4f4f4 !important;
  --textarea-color-text-default:#f4f4f4 !important;
  --select-trigger-color-value:#f4f4f4 !important;
  --select-trigger-color-placeholder:#8d8d8d !important;
  --web-chat-header-background:#000000 !important;
  --web-chat-header-text-color:#f4f4f4 !important;
  --font-family-sans:"IBM Plex Sans", sans-serif !important;
}

/* ANCHORS (plain) */
[data-lb-part="message-text"] { font-family:"IBM Plex Sans",sans-serif; line-height:1.5; }
[data-lb-part="message"][data-lb-author="bot"] [data-lb-part="message-bubble"] {
  background:#262626; color:#f4f4f4; border:1px solid #393939; border-left:3px solid #4589ff; padding:12px 16px;
}
[data-lb-part="message-bubble"],[data-lb-part="option-button"],[data-lb-part="input-field"],
[data-lb-part="input-submit"],[data-lb-part="date-picker"],[data-lb-part="calendly"],
[data-lb-part="takeover"],[data-lb-part="media"],[data-lb-part="options-search"],
[data-lb-part="proactive-message-bubble"] { border-radius:0; }
[data-lb-part="date-picker"],[data-lb-part="calendly"],[data-lb-part="takeover"],
[data-lb-part="options-group"] { background:#262626; border:1px solid #393939; }
[data-lb-part="calendly"],[data-lb-part="takeover"] { padding:16px; }
[data-lb-part="input-field"],[data-lb-part="free-text"] { background:#262626; border:none; border-bottom:1px solid #6f6f6f; }
[data-lb-part="text-input"][data-lb-state="active"] [data-lb-part="input-field"] { border-bottom:2px solid #4589ff; }
[data-lb-part="text-input"][data-lb-state="error"] [data-lb-part="input-field"] { border-bottom:2px solid #fa4d56; }
[data-lb-part="input-error"] { color:#fa4d56; }
[data-lb-part="options-prompt"] { color:#f4f4f4; font-weight:600; }
[data-lb-part="options-prompt"]::before { content:""; display:inline-block; width:8px; height:8px; margin-right:8px; background:#4589ff; }
[data-lb-part="option-button"] {
  background:#0f62fe; color:#fff; border:1px solid #0f62fe; font-weight:400; letter-spacing:0.16px; margin-bottom:8px; padding:12px 16px;
}
[data-lb-part="option-button"]:hover { background:#0353e9; color:#fff; }
[data-lb-part="options-search"] { background:#262626; }
[data-lb-part="option-checkbox"][data-lb-state="selected"] { accent-color:#4589ff; color:#4589ff; }
[data-lb-part="selection-counter"] { color:#c6c6c6; }
[data-lb-part="input-submit"] { background:#0f62fe; color:#fff; }
[data-lb-part="input-submit"]:hover { background:#0353e9; }
[data-lb-part="media-caption"] { color:#c6c6c6; }
[data-lb-part="media-download"] { color:#4589ff; }
[data-lb-part="calendly"] { border-top:3px solid #4589ff; }
[data-lb-part="calendly-prompt"] { color:#f4f4f4; }
[data-lb-part="calendly-cta"]:hover { background:#0353e9; }
[data-lb-part="calendly-skip"] { color:#c6c6c6; }
[data-lb-part="takeover"] { border-left:3px solid #4589ff; }
[data-lb-part="takeover-title"] { color:#f4f4f4; font-weight:600; }
[data-lb-part="takeover-subtitle"] { color:#c6c6c6; }
[data-lb-part="launcher"] { background:#0f62fe; }
[data-lb-part="proactive-message-bubble"] { background:#262626; color:#f4f4f4; border:1px solid #393939; border-left:3px solid #4589ff; }
[data-lb-part="proactive-message-close"]:hover { color:#4589ff; }
[data-lb-part="window"] { border:1px solid #393939; }
[data-lb-part="header"] { border-bottom:1px solid #393939; }
[data-lb-part="message-timestamp"] { color:#6f6f6f; }
[data-lb-part="branding"] { color:#6f6f6f; }

/* SCROLLBARS (global, dark) */
* { scrollbar-width: thin; scrollbar-color: #525252 transparent; }
*::-webkit-scrollbar { width: 8px; height: 8px; }
*::-webkit-scrollbar-track { background: transparent; }
*::-webkit-scrollbar-thumb { background: #525252; border-radius: 0; }
*::-webkit-scrollbar-thumb:hover { background: #6f6f6f; }
```

### Explanation (template)
The theme sets the base (background, header, user bubble, inputs, calendar, typography) with `!important` because they are inline. The plain anchors add what the theme doesn't reach: the bot card, focus/error states, Carbon fields (bottom line), calendly/takeover accents, the chrome (window frame, header, timestamp, branding), and the scrollbars. Out of scope: per-instance, forcing the options list height, and the avatars (bot image).
