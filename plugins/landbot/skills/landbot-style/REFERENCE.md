# landbot-style — operating reference

Facts observed on production Landbot during September 2026. Verify on the target channel before relying on any of them; a web-chat release can change the internals.

## 1. The v4 gate (the false-green trap)

- The channel `version` decides the renderer: `3.0.0` legacy, `3.1.0` v4. It is set when the channel is created, from a per-brand switch. It is not migrated afterwards, and **a duplicated bot takes the brand default, not the source bot's version.**
- On `3.0.0` the Custom CSS is injected as `<style id="custom-styles">` and reaches nothing: the legacy renderer has no `data-lb-*` anchors and its tokens are not the ones in the catalog.
- The published config for a channel is public: `https://storage.googleapis.com/<host>/v3/H-<channel>-<code>/index.json`, where `<host>` is the share URL's host: `landbot.pro`, `landbot.online` or `landbot.site`, one per brand (2026-10-03: 87% of web channels created in September were on `landbot.online`; a config is in one bucket only). It carries `version`, `use_surrogate_interaction` (true on v4) and `style` (the Custom CSS, **only on non-Sandbox plans**). `scripts/verify-share` reads it.
- The builder's **Preview** (the button next to Publish) renders the channel's draft, Custom CSS included: verified 2026-09-25 on a `3.1.0` channel, a draft written with `"autosave": true` showed in the preview's chat frame while the published config did not carry it. The share URL shows what visitors get.
- A draft has no public URL: the test channel's own index.json and share page answer 404 (2026-09-26, probe channel 3517949). The builder's Preview is the only place to see a draft before it is published.

## 2. Apply mechanics

- Add CSS is a CodeMirror 6 field. Typing long CSS through a keyboard automation triggers auto-indent and auto-close; set the document through the editor view instead.
- **Apply** writes the test channel. **Publish** merges into the live channel and regenerates `index.json`. Check the JSON to confirm the publish happened.
- Duplicated bots inherit the source's Custom CSS. Replace, never append.

## 3. What CSS reaches, and what it does not

Reaches, with catalog selectors: colours, fonts (with `@import`), radii, borders, bot bubble background, user pill, option tiles including `::before` letter badges via CSS counters, underline fields, focus and error states, submit pill, branding, scrollbars.

Does not reach with catalog selectors, and needs web-chat's internal wrappers (`:has()` on unnamed `div`s, internal utility classes): hiding the header divider, hiding the avatars row, hiding previous turns, vertical centring, the options card border and search box. These are **off-catalog and fragile**. Use them only on demos, label them as fragile in the hand-back, and tell us which anchor you were missing.

Impossible with CSS alone: a real progress bar or step numbers, keyboard shortcuts, going back to change an answer, exit animations, several fields on one screen, exact private fonts.

Avatars are images from the bot configuration, not colours. Multi-select `option-checkbox` and `selection-counter` only appear with a native multi-choice block. Leave the options list height to native scroll.

## 4. Runtime facts that change what you build

- On `3.1.0`, `ask_yes_no` never renders. Build Yes/No as `buttons`. This belongs to the flow, but a styling request is often where it is first noticed.
- Enter submits short text inputs on `3.1.0`.
- The text input, its layouts and its padding are in §6.
- Channel Custom JS (Design › Custom code › Add JS, the channel's `foot`) runs on the share page on `3.1.0`. It is a separate surface from flow `code` blocks. Landbot serves it only to accounts with the Custom Code feature (the trial has it). Where it is missing, the script is stored and not served. A look must never need its script to work.
- Use it for behaviour only, when asked, and never for data. The MCP server does not write it: the person pastes it in the builder.
- A dark look also needs the channel's `design` colours, or the page shows a white loader before the chat draws. The MCP server does not write `design`: the person sets those colours in the builder's Design tab; say so when a dark look is asked for.

## 5. Welcome screens on form-style replicas

Three screen types exist (welcome, question, thank-you) and the catalog does not distinguish them. Style the welcome explicitly or it inherits the question look: the greeting text is the first bot message, the welcome CTA is `[data-lb-part="option-button"]:only-child` (the only single-button list). Keep the bot's text free of emoji if the source has none; the text is data, not CSS.

## 6. The input: one box, two layouts, padding through tokens

Facts from web-chat 2.27.0 (js-packages, 2026-10-19). Production served 2.25.0 that day; the compatibility patch below covers it until 2.27.0 is live.

**One box.** `input-field` is the frame around every text, email, number, phone, date and AI Agent input. Inside it, `input-control` is the `<input>`, `free-text` is the AI Agent's `<textarea>`, and `input-actions` is the row holding the send button, `input-submit`. Background, border, radius and shadow go on `input-field` only. The controls stay transparent, with no border and no shadow; give them only font, colour, caret and placeholder. A background or border on `free-text` as well as on `input-field` draws a box inside a box.

**Two layouts**, in `data-lb-variant` on `input-field`:

- `inline`: touch screens. The send button sits at the end of the text row.
- `stacked`: mouse. The send button sits on its own row, under the text.

So a phone and a desktop show different inputs. Check both (SKILL.md Step 4).

**Padding is set through tokens, not selectors.** Web-chat sets these on `input-field` itself, so set them there too: a value in `:root` loses to the element's own. They apply to the `stacked` layout.

| Token | What it pads | Web-chat value |
|---|---|---|
| `--input-group-control-padding-inline` | left and right of the text | 16px |
| `--input-group-control-padding-block-start` | above the text | 16px |
| `--input-group-control-padding-block-end` | below the text | 8px |
| `--input-group-addon-padding-inline` | left and right of the button row | 16px |
| `--input-group-addon-padding-block` | below the button row | 16px |
| `--input-group-textarea-min-height` | the AI Agent textarea's minimum height | 0px (one line; it grows with the text up to 112px) |

The send button to the right of the text, centred, on desktop too. Measured on web-chat 2.27.0, text and AI Agent inputs: the centres of the text, the button and the field agree within 1px in both layouts.

```css
[data-lb-part="input-field"][data-lb-variant="stacked"] {
  flex-direction: row; align-items: center;
  --input-group-control-padding-block-start: 16px;
  --input-group-control-padding-block-end: 16px;   /* same as above: the text is centred */
  --input-group-addon-padding-block: 0px;          /* the button row adds no height */
}
/* In a row the button row is full width and squeezes the text to ~30px: give the width back */
[data-lb-part="input-field"][data-lb-variant="stacked"] > :is([data-lb-part="input-control"], [data-lb-part="free-text"]) { flex: 1 1 0%; width: auto; min-width: 0; }
[data-lb-part="input-field"][data-lb-variant="stacked"] > [data-lb-part="input-actions"] { flex: 0 0 auto; width: auto; }
```

To change the empty AI Agent box's height, set `--input-group-textarea-min-height` on `input-field`, not `min-height` on `free-text`. To reach only the AI Agent's box: `[data-lb-part="input-field"]:has(> [data-lb-part="free-text"])`.

### Compatibility patch for web-chat before 2.26 (temporary)

Up to 2.25.x, `input-field` has no `data-lb-variant` and the desktop layout's padding is a Tailwind `!important` inside a layer: no Custom CSS can lower the 16px above the text. The patch matches it instead: the same padding below the text, the button row pulled up by the same amount, and no 64px floor on the textarea. It is limited to `:not([data-lb-variant])`, so it does nothing on 2.26 and later. It uses web-chat internals (`data-slot`, `data-align`), so it is off-catalog. Add it after the snippet above while a bot's chat still serves 2.25 (on the share page, `document.querySelector('[data-lb-part="input-field"][data-lb-variant]')` is `null` with an input on screen):

```css
/* TEMPORARY: web-chat < 2.26. Remove once the chat serves 2.26 or later. */
[data-lb-part="input-field"]:not([data-lb-variant]):has(> [data-align="block-end"]) { flex-direction: row; align-items: center; }
[data-lb-part="input-field"]:not([data-lb-variant]):has(> [data-align="block-end"]) > [data-slot="input-group-control"] {
  flex: 1 1 0%; width: auto; min-width: 0; padding-bottom: var(--spacing-inset-4, 16px);
}
[data-lb-part="input-field"]:not([data-lb-variant]) > [data-align="block-end"]:has(> [data-lb-part="input-submit"]) {
  flex: 0 0 auto; width: auto; align-self: center; margin-bottom: calc(-1 * var(--spacing-inset-4, 16px));
}
[data-lb-part="input-field"]:not([data-lb-variant]):has(> [data-align="block-end"]) > textarea[data-slot="input-group-control"] { min-height: 0; }
```

To remove it: once `input-field` carries `data-lb-variant` on the share page, delete the block between its `TEMPORARY` comment and the next blank line and push the CSS again. Delete this subsection from the skill once production serves web-chat 2.26 or later.

### Back button and entrance animations

- **Back** has its own anchor from 2.26.0: `[data-lb-part="back-button"]`. Its wrapper is still hover-only on devices web-chat does not take for a phone or tablet, so keep `div:has(> [data-lb-part="back-button"]) { opacity: 1 !important; }`. Before 2.26 there is no anchor; use the off-catalog `button[data-slot="button"][data-size="sm"][data-variant="ghost"]` instead (SKILL.md Step 2b).
- **Entrance animations** on `[data-lb-part="message"]`: from 2.26.1 the last message stays mounted when Back appears or goes away, so an animation plays once. Before 2.26.1 it was remounted and every question replayed its animation after each answer. For those versions animate only the question that just arrived and the greeting:
  `:is(:first-child > [data-lb-part="message"][data-lb-author="bot"], [data-lb-part="message"][data-lb-author="bot"]:has(+ div)) [data-lb-part="message-bubble"] { animation: … }`. Always add a `prefers-reduced-motion: reduce` rule that turns it off.
