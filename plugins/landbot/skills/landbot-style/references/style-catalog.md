# Style model — layers, cascade rules and a worked example

What Custom CSS can style, the anchors, their roles and the tokens of each layer, comes from the Landbot MCP server: `get_web_chat_style_catalog` (SKILL.md Step 2). This file holds only what the server does not give: how the pieces go together, a full example, and what CSS cannot reach.

Observed on production Landbot web chat v4 in September and October 2026. Verify on the target channel; a web-chat release can change internals.

## The model: three layers in one block

1. **Tokens.** The global look: background, text, borders, primary button, messages, inputs, calendar, header, typography. Theme tokens go in `:root`; component tokens go in the `selector` the catalog gives each one.
2. **Anchors (plain rules, NO `!important`).** Specific parts, states and accents: the bot bubble background, focus/error, calendly, takeover, corners, hover. A rule on a part sets only what its `role` allows.
3. **Scrollbars (global).** Browser bars; not an anchor, just standard CSS.

## The golden cascade rule (when to use `!important`)

- **Anchors -> plain, WITHOUT `!important`.** The channel's Custom CSS is **unlayered**; web-chat's Tailwind v4 utilities live in `@layer utilities`. In CSS, **what is outside a layer beats what is inside**, no `!important` needed. Verified live.
- **Tokens -> in their `selector`, with `!important` exactly when the catalog says `important: true`.** The channel config sets the theme tokens **inline on `<html>`**, and an inline value is only beaten by `!important`. Component tokens are not set inline: in `:root` they win plain, and the `input-field` ones must go on `[data-lb-part="input-field"]`, because web-chat sets them on that element and a value in `:root` loses to the element's own.
- **Derived tokens.** A theme token with `derived_from` is computed from its base when the chat loads. Changing the base in CSS does not move them: set the derived ones you need too (the example below sets them for a dark look).
- **One-off exception:** if a specific property won't stick, a component may defend it with its own `!important`; there you add it to the anchor. Practical rule: emit plain; if a rule shows struck through in DevTools, add `!important`.

There is **no token for the bot bubble background** (only its text): it goes through an anchor. The selected calendar day has **no anchor**: it goes through `--calendar-day-bg-selected`.

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
- **Fields:** Carbon style = **bottom border only** that turns blue on focus.
- **Whitespace:** generous (2x Grid). More padding on buttons (`12px 16px`), bubbles and cards.

## Full example: IBM Carbon dark

Token names, selectors and `important` checked against `get_web_chat_style_catalog` on 2026-10-23. Read the catalog again before reusing it.

```css
/* lb-style: ibm-carbon-dark — THEME + COMPONENT tokens, ANCHORS (plain), SCROLLBARS */
@import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&display=swap');

/* THEME tokens: :root, !important (the config sets them inline on <html>) */
:root {
  /* background and what derives from it */
  --color-surface-1:#161616 !important;
  --color-surface-2:#262626 !important;
  --color-surface-3:#161616 !important;
  --color-surface-4:#393939 !important;
  --color-surface-backdrop:#000000 !important;
  --color-surface-interactive-1:#161616 !important;
  --color-surface-interactive-2:#262626 !important;
  --color-surface-interactive-3:#393939 !important;
  --color-surface-chat-user-1:#0f62fe !important;
  --color-control-1:#262626 !important;
  --color-control-2:#262626 !important;
  --color-control-3:#262626 !important;
  --color-control-4:#393939 !important;
  --color-action-primary-4:#393939 !important;
  --color-action-primary-5:#525252 !important;
  --color-action-secondary-1:#161616 !important;
  --color-action-secondary-2:#262626 !important;
  --color-action-secondary-3:#393939 !important;
  --color-action-secondary-4:#393939 !important;
  --color-action-tertiary-1:#161616 !important;
  --color-action-tertiary-2:#262626 !important;
  --color-action-tertiary-3:#393939 !important;
  --color-action-tertiary-4:#393939 !important;
  --color-border-1:#393939 !important;
  --color-border-control-1:#6f6f6f !important;
  --color-border-control-3:#8d8d8d !important;
  --color-border-interactive-1:#393939 !important;
  --color-border-interactive-2:#6f6f6f !important;
  --color-border-interactive-3:#6f6f6f !important;
  --color-border-action-secondary-1:#393939 !important;
  --color-border-action-secondary-4:#393939 !important;
  --color-border-chat-user-1:#0f62fe !important;
  /* text and what derives from it */
  --color-font-1:#f4f4f4 !important;
  --color-font-2:#c6c6c6 !important;
  --color-font-3:#8d8d8d !important;
  --color-font-chat-bot-1:#f4f4f4 !important;
  --color-font-chat-user-1:#ffffff !important;
  --color-font-control-1:#f4f4f4 !important;
  --color-font-control-2:#8d8d8d !important;
  --color-font-control-4:#f4f4f4 !important;
  --color-font-action-secondary-1:#f4f4f4 !important;
  --color-font-action-secondary-2:#6f6f6f !important;
  --color-font-action-tertiary-1:#c6c6c6 !important;
  --color-font-action-tertiary-2:#f4f4f4 !important;
  --color-font-action-tertiary-3:#f4f4f4 !important;
  --color-font-action-tertiary-4:#6f6f6f !important;
  /* primary and what derives from it */
  --color-action-primary-1:#0f62fe !important;
  --color-action-primary-2:#0353e9 !important;
  --color-action-primary-3:#002d9c !important;
  --color-ring-focus:#4589ff !important;
  --color-surface-interactive-selected:#002d9c !important;
  --color-control-selected-1:#002d9c !important;
  --color-font-4:#4589ff !important;
  --color-font-action-primary-1:#ffffff !important;
  --color-font-action-primary-2:#8d8d8d !important;
  --color-border-action-primary-1:#0f62fe !important;
  --color-border-control-selected:#4589ff !important;
  --color-border-interactive-selected:#4589ff !important;
  /* the rest of the theme */
  --border:#393939 !important;
  --select-content-border:#393939 !important;
  --button-border-color-primary-default:#0f62fe !important;
  --button-font-color-primary-default:#ffffff !important;
  --calendar-day-color-selected:#ffffff !important;
  --chat-bubble-color-font-bot:#f4f4f4 !important;
  --chat-bubble-surface-user:#0f62fe !important;
  --chat-bubble-border-color-user:#0f62fe !important;
  --chat-bubble-color-font-user:#ffffff !important;
  --input-background-default:#262626 !important;
  --select-trigger-color-value:#f4f4f4 !important;
  --select-trigger-color-placeholder:#8d8d8d !important;
  --web-chat-header-background:#000000 !important;
  --web-chat-header-text-color:#f4f4f4 !important;
  --web-chat-launcher-background:#0f62fe !important;
  --font-family-sans:"IBM Plex Sans", sans-serif !important;
  /* ALIAS tokens: also :root, !important */
  --background:#161616 !important;
  --foreground:#f4f4f4 !important;
  --muted-foreground:#c6c6c6 !important;
}

/* COMPONENT tokens with selector :root: plain */
:root {
  --button-color-primary-default:#0f62fe;
  --button-color-primary-hover:#0353e9;
  --button-color-primary-active:#002d9c;
  --button-color-primary-disabled:#393939;
  --calendar-day-radius:0;
  --calendar-nav-radius:0;
  --calendar-day-bg-hover:#393939;
  --calendar-day-bg-today:#393939;
  --calendar-day-bg-selected:#0f62fe;
  --calendar-day-color-outside:#6f6f6f;
  --calendar-day-color-disabled:#525252;
  --select-trigger-radius:0;
  --select-content-radius:0;
  --select-content-background:#262626;
  --select-item-radius:0;
  --select-item-background-default:#262626;
  --select-item-background-hover:#393939;
  --select-item-background-selected:#393939;
  --select-item-color-selected:#4589ff;
}

/* COMPONENT tokens with selector input-field: on input-field, plain. The box is input-field alone. */
[data-lb-part="input-field"] {
  --input-group-radius:0;
  --input-group-radius-coarse:0;
  --input-group-ring-width:0px;                       /* Carbon: no ring, the bottom line turns blue */
  --input-group-background-default:#262626;           /* once typed; the empty box is --input-background-default */
  --input-group-background-hover:#262626;
  --input-group-background-focus:#262626;
  --input-group-border-color-disabled:#6f6f6f;        /* the empty box, the one seen most */
  --input-group-border-color-default:#6f6f6f;
  --input-group-border-color-hover:#8d8d8d;
  --input-group-border-color-focus:#4589ff;
  --input-group-border-color-error:#fa4d56;
  --input-group-color-text-default:#f4f4f4;
  --input-group-color-text-disabled:#f4f4f4;          /* the caret of the empty box */
  --input-group-color-text-placeholder:#8d8d8d;
  --input-group-color-text-error:#fa4d56;
  border-width:0 0 1px;                               /* bottom line only; its colour comes from the tokens */
  box-shadow:none;
}
[data-lb-part="input-field"]:focus-within { border-bottom-width:2px; }
[data-lb-part="text-input"][data-lb-state="error"] [data-lb-part="input-field"] { border-bottom-width:2px; }
/* The <input> and the agent's <textarea> are controls: transparent, no border, no shadow, text only */
[data-lb-part="input-control"],[data-lb-part="free-text"] { background:transparent; border:none; box-shadow:none; font-family:"IBM Plex Sans",sans-serif; }

/* ANCHORS (plain) */
[data-lb-part="message-text"] { font-family:"IBM Plex Sans",sans-serif; line-height:1.5; }
[data-lb-part="message"][data-lb-author="bot"] [data-lb-part="message-bubble"] {
  background:#262626; color:#f4f4f4; border:1px solid #393939; border-left:3px solid #4589ff; padding:12px 16px;
}
[data-lb-part="message-bubble"],[data-lb-part="option-button"],[data-lb-part="input-submit"],
[data-lb-part="date-picker"],[data-lb-part="takeover"],[data-lb-part="calendly-cta"],
[data-lb-part="proactive-message-bubble"] { border-radius:0; }
[data-lb-part="date-picker"],[data-lb-part="takeover"] { background:#262626; border:1px solid #393939; }
[data-lb-part="takeover"] { padding:16px; border-left:3px solid #4589ff; }
[data-lb-part="input-error"] { color:#fa4d56; }
[data-lb-part="options-prompt"] { color:#f4f4f4; font-weight:600; }
[data-lb-part="options-prompt"]::before { content:""; display:inline-block; width:8px; height:8px; margin-right:8px; background:#4589ff; }
[data-lb-part="option-button"] {
  background:#0f62fe; color:#fff; border:1px solid #0f62fe; font-weight:400; letter-spacing:0.16px; margin-bottom:8px; padding:12px 16px;
}
[data-lb-part="option-button"]:hover { background:#0353e9; color:#fff; }
[data-lb-part="option-checkbox"][data-lb-state="selected"] { accent-color:#4589ff; color:#4589ff; }
[data-lb-part="selection-counter"] { color:#c6c6c6; }
[data-lb-part="media-caption"] { color:#c6c6c6; }
[data-lb-part="media-download"] { color:#4589ff; }
[data-lb-part="calendly-prompt"] { color:#f4f4f4; }
[data-lb-part="calendly-skip"] { color:#c6c6c6; }
[data-lb-part="takeover-title"] { color:#f4f4f4; font-weight:600; }
[data-lb-part="takeover-subtitle"] { color:#c6c6c6; }
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
The theme tokens set the base (background, text and primary, with the tokens derived from each, plus header, user bubble, input, launcher and typography) with `!important` because the config sets them inline. The component tokens square the calendar and its dropdowns and colour the input box per state, set where the catalog says, without `!important`. The plain anchors add what the tokens don't reach: the bot card, the Carbon bottom line, takeover accents, the chrome (window frame, header, timestamp, branding), and the scrollbars. The box is `input-field` alone; the `<input>` and the AI Agent's `<textarea>` stay transparent. Out of scope: per-instance, forcing the options list height, and the avatars (bot image).
