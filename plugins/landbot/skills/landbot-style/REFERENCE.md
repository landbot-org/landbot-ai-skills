# landbot-style — operating reference

Facts observed on production Landbot during September 2026. Verify on the target channel before relying on any of them; a web-chat release can change the internals.

## 1. The v4 gate (the false-green trap)

- The channel `version` decides the renderer: `3.0.0` legacy, `3.1.0` v4. It is set when the channel is created, from a per-brand switch. It is not migrated afterwards, and **a duplicated bot takes the brand default, not the source bot's version.**
- On `3.0.0` the Custom CSS is injected as `<style id="custom-styles">` and reaches nothing: the legacy renderer has no `data-lb-*` anchors and its tokens are not the ones in the catalog.
- The published config for a channel is public: `https://storage.googleapis.com/landbot.pro/v3/H-<channel>-<code>/index.json`. It carries `version`, `use_surrogate_interaction` (true on v4) and `style` (the Custom CSS, **only on non-Sandbox plans**). `scripts/verify-share` reads it.
- The builder's Design preview never renders Custom CSS. Only the share URL does.

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

- On `3.1.0`, `ask_yes_no` never renders and `code` blocks are skipped silently. Build Yes/No as `buttons`. This belongs to the flow, but a styling request is often where it is first noticed.
- Enter submits short text inputs on `3.1.0`.
- Input-row trap: the submit wrapper inside `input-field` is full width. Any rule that turns the row into a flex container lets it swallow the width and the `<input>` collapses to about 23 px. Pair it with `> input { flex:1 1 0%; width:auto; min-width:0 }` and `> div { flex:0 0 auto; width:auto }`, then type real text and measure `input.getBoundingClientRect().width`.
- Channel Custom JS (Design › Custom code › Add JS, the channel's `foot`) runs on the share page on `3.1.0`. It is a separate surface from flow `code` blocks. Landbot serves it only on plans with the Custom Code add-on: Starter, Professional and Business carry it; Sandbox and the free trial do not (read in Landbot's code 2026-09-23: the trial's feature groups leave the add-on out). On those, the script is stored and not served, so a look must never need its script to work.
- Use it for behaviour only, when asked and authorised, and never for data: `scripts/channel js` refuses a script that sends data, reads cookies, loads code from elsewhere or evaluates strings. Start from `modules/` (messaging, steps).
- A dark look also needs the channel's `design` colours, or the page shows a white loader before the chat draws. This plugin does not write `design`; say so when a dark look is asked for.

## 5. Welcome screens on form-style replicas

Three screen types exist (welcome, question, thank-you) and the catalog does not distinguish them. Style the welcome explicitly or it inherits the question look: the greeting text is the first bot message, the welcome CTA is `[data-lb-part="option-button"]:only-child` (the only single-button list). Keep the bot's text free of emoji if the source has none; the text is data, not CSS.
