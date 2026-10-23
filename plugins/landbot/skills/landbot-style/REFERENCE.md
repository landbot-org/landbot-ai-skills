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

Observed on the v4 web chat in October 2026.

**One box.** `input-field` is the frame around every text, email, number, phone, date and AI Agent input. Inside it, `input-control` is the `<input>`, `free-text` is the AI Agent's `<textarea>`, and `input-actions` is the row holding the send button, `input-submit`. Background, border, radius and shadow go on `input-field` only. The controls stay transparent, with no border and no shadow; give them only font, colour, caret and placeholder. A background or border on `free-text` as well as on `input-field` draws a box inside a box.

**Two layouts**, in `data-lb-variant` on `input-field`:

- `inline`: touch screens. The send button sits at the end of the text row.
- `stacked`: mouse. The send button sits on its own row, under the text.

So a phone and a desktop show different inputs. Check both (SKILL.md Step 4).

**Frame, colours and padding are set through tokens, not selectors.** The `--input-group-*` tokens come from `get_web_chat_style_catalog` with `layer: "component"`: put each in its `selector` (`[data-lb-part="input-field"]`), with `!important` only when `important` is true (none was on 2026-10-23), and check `applies_in` for the layout it acts in. Web-chat sets them on `input-field` itself, so a value in `:root` loses to the element's own. Most of the padding tokens act only in `stacked`; the touch layout has its own `-coarse` ones. Where web-chat sets its own value for a layout, the catalog shows it in `web_chat_values`.

The send button to the right of the text, centred, on desktop too. Measured 2026-10-19 on text and AI Agent inputs: the centres of the text, the button and the field agree within 1px in both layouts. Its three tokens are checked against the catalog on 2026-10-23: selector `input-field`, not `important`, acting in `stacked`.

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

### Back button and entrance animations

- **Back** is `[data-lb-part="back-button"]`. Its wrapper is hover-only on devices the web chat does not take for a phone or tablet, so keep `div:has(> [data-lb-part="back-button"]) { opacity: 1 !important; }` (SKILL.md Step 2b).
- **Entrance animations** on `[data-lb-part="message"]` or `[data-lb-part="message-bubble"]` play once per message, including when Back appears or goes away. Always add a `prefers-reduced-motion: reduce` rule that turns them off.
