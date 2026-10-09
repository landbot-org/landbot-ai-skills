---
name: landbot-style
description: Style a Landbot v4 web chat. Turn a brief (brand colours, a reference site, "make it look like IBM / dark / our site") into ONE Custom CSS block — theme tokens in :root, data-lb-* anchors, scrollbars — apply it through the Landbot MCP server, then verify it on the share URL. Use when asked to style, theme, restyle or brand a Landbot chat, or while landbot-flows builds a bot that should have a look.
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/scripts/verify-share" *) mcp__plugin_landbot_landbot__get_web_chat
metadata:
  short-description: Style a Landbot v4 web chat with one Custom CSS block
  version: 0.5.2
---

**First line of your first reply when this skill activates: `landbot-style 0.5.2`.** Then carry on. A different version shown elsewhere means two copies are installed; the one printed is the one running.

Read [REFERENCE.md](REFERENCE.md) first (the v4 gate, apply and verify mechanics, what CSS cannot reach). The token and anchor catalog with a full worked example is in [references/style-catalog.md](references/style-catalog.md). Build the flow with `landbot-flows`; this skill only styles.

This skill reads and writes the chat through the Landbot MCP server (`get_web_chat`, `update_web_chat`; `landbot-flows` Step 0 says how to connect it). It also ships `scripts/verify-share`, which reads the chat's **published** config from the public share URL and needs no sign-in, and `modules/`, two ready-made behaviours (`messaging` and `steps`, each a `.js` and a companion `.css`).

- **Claude Code** replaces `${CLAUDE_SKILL_DIR}` with this skill's folder before you read this file.
- **Codex, Cursor, other agents:** `scripts/install.sh` writes the absolute folder into this file. If a command here still shows a placeholder in braces (`CLAUDE_SKILL_DIR`) instead of a folder, replace it with the folder this SKILL.md lives in. Look at where this file is; do not guess.

## Step 0 — Preflight: is this chat v4, and where will a change land?

`get_web_chat` answers both:

- **`renders_v4`.** The anchors and tokens only exist on the v4 web chat. On the legacy one the CSS saves and **changes nothing**, and nothing in the builder warns you. If it is false, `update_web_chat` with `use_v4` switches it (there is no switching back): for a bot `landbot-flows` created in this conversation, do it; for a bot the person already had, say Custom CSS needs the v4 web chat and get their yes first, warning that `ask_yes_no` blocks in its flow stop working on v4. Do not generate CSS "just in case".
- **Live or draft.** On a bot never published, whose chat has no unpublished changes, a change is **live at once**. Otherwise it goes to the chat's **draft**: visitors get it when the person publishes the bot from the Landbot builder, and the builder's **Preview** shows it before then. Say which, before the first change.
- **`share_url`**, which Step 4 verifies on.

A bot the person already had is never changed without their yes: name the bot and say the change goes to its draft.

## Step 1 — Get the brief (one or two short rounds, then generate)

Ask only about what the chat's CSS can touch: mode, palette or accent, corner shape, typography, density. Out of scope: logo, avatars (bot images), iconography, motion.

- Open with one question: "In one sentence, what should the chat convey, or which brand should it look like?"
- Warn once about the limits: colours, shape, typography and states; not the logo, the avatars or the fine header.
- Offer concrete choices, not open questions: reference brand or hex palette or a preset (IBM / generic dark / generic light); light or dark; square, soft or rounded; boxed fields or bottom-line only.
- If they give a strong reference ("our site", a URL, "IBM"), infer the whole package and confirm it in one line rather than asking item by item. For a URL, read it and extract background, text, accent, font and corner radius.
- As soon as you have mode + palette/accent + shape, stop asking and produce the first pass. Typography and density are better tuned by looking than by asking.

## Step 2 — Generate ONE CSS block

Three layers, in this order, in one block (details and the full catalog in `references/style-catalog.md`):

1. **Theme tokens** in `:root { --x: … !important }`. The channel config sets these inline on `<html>`, so only `!important` beats them.
2. **Anchors** as plain rules, **no `!important`**: `[data-lb-part="…"]` with `data-lb-author`, `data-lb-state`, `data-lb-variant`. The channel CSS is unlayered and beats web-chat's layered utilities on its own.
3. **Scrollbars** last, global, values from the brief's palette.

Rules: only selectors from the catalog (39 parts, listed in the catalog file); non-system fonts via a Google Fonts `@import` at the top; the bot bubble background has **no token**, it goes through an anchor; never per-instance selectors. Put a comment on the first line with a short unique marker, e.g. `/* lb-style: acme-dark 2026-09-17 */` — verification greps for it.

Say in three or four lines what each layer does and what is left out.

## Step 2b — Keep the visitor's Back button

The v4 web chat has a native **Back** button: it re-asks the previous question, and the new answer replaces the old one (verified on production 2026-09-18 and again on 16 bots on 2026-09-25). Never hide it to make a chat look like a form, a game or a messaging app — a visitor who taps the wrong answer must be able to change it. Three things the CSS has to handle:

- **It is invisible on phones by default.** Its wrapper is hover-only (`opacity-0` until hover), so on a touch screen nobody sees it. Force it: `div:has(> button[data-slot="button"][data-size="sm"][data-variant="ghost"]) { opacity: 1 !important; }` (no `data-lb-part` anchor exists for it; this selector is off-catalog, so say so in the hand-back).
- **Keep it in the page flow.** `position: fixed` traps it inside the scroll area, clipped and untappable. Place it with `order` or margins and style it to fit the look (a small "‹ Back" link is enough).
- **It is switched per chat.** When `back_button_visible` is false it is not on the page at all, and CSS cannot bring it back: `update_web_chat` with `back_button_visible: true` switches it on (a change like any other, same rules as the CSS).

Tell the person two flow facts that come with Back, because they are the flow's to fix, not the CSS's:

- **Back runs the steps after the previous answer again.** A score, a count or a list that is *added to* as the visitor goes (`Sum(@score, 1)`, appending to a list) counts twice after a Back. Store each answer in its own field and compute totals from the stored answers instead (verified 2026-09-25: a quiz showed 7/6 and a game took an extra life until this was changed).
- An `email` or `webhook` step placed between two questions can run twice. Put deliveries after the last question.

## Step 3 — Apply

`update_web_chat` with `custom_css` set to the whole block. **It replaces the chat's Custom CSS whole**: say so before the first push. Its answer carries `previous`, the chat as it was: keep its `custom_css`, because sending it back is the undo.

**While `landbot-flows` builds a bot, style it before the first publish**, in steps the person can see: first the theme tokens (palette, background, text), then font and shapes, then the anchors and details, each push the whole file so far. When a part of the flow brings a component the CSS has not met yet (a text or email field, a date picker, a list of five or more options), style it before the publish. With Claude's in-app browser open on the share URL, reload it with a new query string after each push to look; the flow is not published yet, so look, do not walk.

**The person can also paste it in the app.** Give them exactly this, no more:

1. Open the bot in the builder → **Design** → **Custom code** → **Add CSS**.
2. Select everything in the field, delete it, paste the block. A duplicated bot inherits old CSS, so replace, never append.
3. Click **Apply**, then **Publish**.

## Step 3b — Behaviour (Custom JS), only when asked for

CSS cannot move reply buttons into the bubble that asked, stamp times on messages, draw a progress bar or add letter keys. A short script on the page can. Two ready-made behaviours ship in `${CLAUDE_SKILL_DIR}/modules/`, taken from verified demos:

| Module | What the visitor gets | CONFIG |
|---|---|---|
| `messaging` | a messaging-app chat: reply buttons inside the bubble that asked, times on messages, a "Today" chip, "typing…" under the header name, a composer bar on button turns | `placeholder`, `dayLabel` |
| `steps` | a form: a progress bar that fills as they answer, "2 of 5", letter keys A, B, C for the buttons | `total` (questions on the longest path), `counter`, `counterText`, `keys` |

The MCP server does not write Custom JS: the person adds it in the builder. To prepare one:

1. Copy the module's `.js` to a working file and **change only the values in its `CONFIG` block** (strings, numbers, true/false). Append the module's `.css` to the end of the look's CSS, set its colour variables (`--lbm-*`, `--lbs-*`) from the brief in `:root`, and push the CSS as in Step 3.
2. Give the person the script and these steps: open the bot in the builder → **Design** → **Custom code** → **Add JS**, paste, **Apply**, then **Publish**.
3. Landbot serves Custom JS only to accounts with the Custom Code feature; elsewhere it is stored and not served. The chat works without it, because every module rule in the CSS styles only what the script adds. Do not guess which plans have it.
4. Once they have published, **walk it** in the in-app browser (`landbot-flows` Step 6), then `read_console_messages` with errors only. A script error, a button that does not answer, or a page that stops responding is a failure: say so and ask them to remove the script.

**A custom script, when neither module fits** and the person asked for a behaviour: say in plain words what it will do on their page, and give it to them to paste the same way. Keep it short and page-only, with an `lb-js: <name>` marker comment: no sending data out, no cookies, no loading or building code, no navigation. Wrap everything in `try`; add only attributes, classes and your own elements, never move Landbot's nodes; read `textContent`, never `innerText`, inside anything that runs on page changes (it can loop); guard a `MutationObserver` so its own changes do not trigger it again; and write the CSS so the chat looks complete when the script does not run.

## Step 4 — Verify on the share URL (the only checks that prove anything)

Once the look is live (a bot never published, or after the person published it):

```bash
"${CLAUDE_SKILL_DIR}/scripts/verify-share" <share-url> "lb-style: acme-dark"
```

Exit 0 means: v4 renderer, Custom CSS present in the **published** config, and your marker is in it. Anything else is a real failure. A live change rewrites that config at once, before any publish: so when it shows `3.1.0` but `FAIL: no Custom CSS in the published config`, the CSS reached the chat and the plan does not serve it (Sandbox drops Custom CSS). Say that plainly, as the answer, not as an open question; the upgrade is the person's decision, not a bug to work around.

Then in the browser, on the share URL (its host is `landbot.pro`, `landbot.online` or `landbot.site`), after answering one option so a user pill and the next question are visible:

```js
document.querySelectorAll('[data-lb-part]').length            // > 0 (about 16 on load, ~29 after two turns)
document.fonts.check('18px "<Font>"')                          // true when the @import loaded
getComputedStyle(document.querySelector('[data-lb-part="option-button"]')).backgroundColor
```

Report what you checked and what you did not: a full-page share URL check does not verify the embedded bubble on a customer site.

### Look at it yourself in the in-app browser, when there is one

`verify-share` proves the CSS is in the published config, not that the chat looks right. **If this session has Claude's in-app browser** (the Claude desktop app's Code tab: tools named `mcp__Claude_Browser__*`), look at the chat there once the bot is published. The person watches it in the side pane:

1. Open the share URL (`preview_start` with `url`, or `navigate` when the pane is open). Answer the first question with fake data so a user reply and the next question are on screen.
2. Run the three console checks above with `javascript_tool`, and take a screenshot at desktop width.
3. `resize_window` with preset `mobile`, reload the share URL with a new query string (`?look=2`), answer once, and take a second screenshot. Then `resize_window` with preset `desktop` to put the pane back.
4. Check these four things on both screenshots, against the brief:
   (a) every bot message is readable against its background;
   (b) the brand colours are on the bot bubble and the buttons;
   (c) the brand font is used (`document.fonts.check` is true);
   (d) every button and the input can be reached, and nothing is covered.
5. If one fails, fix the CSS and push again. On a published bot that push goes to the draft: say so, and the fix reaches visitors when the person publishes it. Stop after three rounds and report what is still wrong.
6. With a behaviour module on, also check it did its job at both widths (reply buttons inside the bubble, or the bar filling), and that `read_console_messages` shows no error from it.

In the hand-back, say "looked at by me in the in-app browser at desktop and phone width", plus the result of each of the four checks.

**No in-app browser** (terminal, Codex, Cursor): give the share URL and the four checks above, and ask the person to open it on a computer and a phone. Until they answer, say "the CSS is live", never "styled".

## Step 5 — Hand back

- The CSS block (once, complete).
- How it was applied, live or to the draft, and the Custom CSS it replaced (`previous`), to undo it.
- Any behaviour module and its CONFIG, with the paste steps if the person has not added it yet.
- The verify result, with the config URL.
- What the CSS could not reach (see REFERENCE.md §3) and any selector outside the catalog you used, marked fragile.
- One question, optional: "Which part or state could you not style?" Pass the answer on with the bot id as an issue on the skills repo.
