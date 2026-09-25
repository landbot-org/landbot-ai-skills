---
name: landbot-style
description: Style a Landbot v4 web chat. Turn a brief (brand colours, a reference site, "make it look like IBM / dark / our site") into ONE Custom CSS block — theme tokens in :root, data-lb-* anchors, scrollbars — that the user pastes into Design › Custom code › Add CSS, then verify it on the published share URL. Use when asked to style, theme, restyle or brand a Landbot chat, or right after landbot-flows hands back a LANDBOT_HANDOFF line.
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/scripts/verify-share" *) Bash("${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows/scripts/handoff" *) Bash("${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows/scripts/channel" get *) Bash(jq *)
metadata:
  short-description: Style a Landbot v4 web chat with one Custom CSS block
  version: 0.4.0
---

**First line of your first reply when this skill activates: `landbot-style 0.4.0`.** Then carry on. A different version shown elsewhere means two copies are installed; the one printed is the one running.

Read [REFERENCE.md](REFERENCE.md) first (the v4 gate, apply and verify mechanics, what CSS cannot reach). The token and anchor catalog with a full worked example is in [references/style-catalog.md](references/style-catalog.md). Build the flow with `landbot-flows`; this skill only styles.

## Where the scripts are

This skill ships `scripts/verify-share` (no token needed) and `modules/` (two ready-made behaviours: `messaging` and `steps`, each a `.js` and a companion `.css`). Pushing CSS or Custom JS to a channel uses `scripts/channel` from the sibling `landbot-flows` skill (same plugin, same install), which reads the person's token the same way `lb` does.

- **Claude Code** replaces `${CLAUDE_SKILL_DIR}` (this folder) and `${CLAUDE_PLUGIN_ROOT}` (the plugin folder; the flows skill is `${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows`) before you read this file.
- **Codex, Cursor, other agents:** `scripts/install.sh` writes the absolute folders into this file. If the commands here still show placeholders in braces (`CLAUDE_SKILL_DIR`, `CLAUDE_PLUGIN_ROOT`) instead of folders, replace them with the folder this SKILL.md lives in and the folder that holds both skills. Look at where this file is; do not guess.

`scripts/verify-share` reads the channel's **published** config from the public share URL.

## Step 0 — Preflight: is this channel v4?

The anchors and tokens only exist when the channel renders the **v4 web chat**, and that is fixed at channel creation by the channel's `version`:

- `3.1.0` → v4 → this skill works.
- `3.0.0` → legacy renderer → the CSS saves, publishes, and **changes nothing**. Zero `data-lb-part` elements on the page. This is the failure to avoid, and nothing in the builder warns you.

How to know:

1. **From the handoff line.** `landbot-flows` ends with `LANDBOT_HANDOFF bot=… builder=… share=… channel=… version=…`. Read `version` and `share` from it.
2. **From a share URL** the user gives you: `"${CLAUDE_SKILL_DIR}/scripts/verify-share" <share-url>` prints the version and whether Custom CSS is present in the published config.

If the version is `3.0.0` and the bot was **created in this session by `landbot-flows`**: do not stop. Run that skill's Step 5a (`channel v4 --bot <bot_id>`; the channel write is live at once, no republish; covered by the one yes the person gave `landbot-flows` before building if a look was part of that sentence, otherwise ask) and re-read the handoff line. If the bot is one the person already had: say the channel is on the legacy renderer and Custom CSS will not render there, and offer `channel v4 --bot <bot_id>`: it goes to the bot's draft (never live), needs its own yes, and they switch by pressing Publish in the builder (see `landbot-flows` Step 5a, including the `ask_yes_no`/`code` warning). Do not generate CSS "just in case".

Also say, once: before Publish, the builder's **Preview** button shows the draft, Custom CSS included (verified 2026-09-25 on a `3.1.0` channel); after Publish, the share URL is what visitors get and the only thing to verify.

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

## Step 3 — Apply

Two ways. Use the first for any bot; the second when the person prefers to paste it or `channel` refuses.

**A. Push it through the API.** Write the block to a file and push it to the channel. Where it lands is the script's decision: for a bot this plugin created on this machine in the last 6 hours the push is **live for visitors the moment it answers** (the channels API regenerates the published config; no publish step); for any other bot it goes to the bot's **draft**, and the person makes it live by pressing Publish in the builder. If the person gave `landbot-flows` the one yes before building this bot in this session **and that sentence included applying the look they described**, that yes covers this push: say you are pushing, and push. A yes given without the styling clause ("just show me", or "build and publish it"), or for a different bot, does not; say what you are about to push and get a yes, exactly as for a publish:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows/scripts/channel" css /path/to/style.css --bot <bot_id>   # WRITE: live for a bot created here, draft otherwise; the channel is found from the bot
```

`channel` finds the channel from the bot (never type a channel id). There is no age limit. A push to a bot the person already had needs its own yes (name the bot, say it goes to the draft); after it, give the builder link and say: reload the tab if it was open, press **Preview**, then **Publish**. When the channel holds unpublished changes the person made, `channel` refuses (exit 75); ask them to publish or discard those first, or use path B. Say before the push that the channel's Custom CSS field is replaced whole. Every push first saves what the field held and prints the backup's path; `channel css <backup> --bot <bot_id>` puts it back.

**In the live build (the in-app browser is open), push the look in steps** so the person sees it change: first the theme tokens (palette, background, text), then font and shapes, then the anchors and details. Each push is the whole file so far (the field is replaced whole). After each one, reload the pane with a new query string and answer one question so a button and a reply are on screen. Three pushes, not thirty: each one should be a visible step.

**B. The person pastes it in the app (any bot).** Give them exactly this, no more:

1. Open the bot in the builder → **Design** → **Custom code** → **Add CSS**.
2. Select everything in the field, delete it, paste the block. A duplicated bot inherits old CSS, so replace, never append.
3. Click **Apply** (writes the test channel), then **Publish** (writes the live channel and regenerates the published config).

If you are driving their browser yourself (Claude in Chrome, Playwright): the field is a CodeMirror 6 editor. Do not type 150 lines; set the document through the editor view, then click Apply. Never touch session cookies.

## Step 3b — Behaviour (Custom JS), only when asked for

CSS cannot move reply buttons into the bubble that asked, stamp times on messages, draw a progress bar or add letter keys. A short script on the page can. Two ready-made behaviours ship in `${CLAUDE_SKILL_DIR}/modules/`, taken from verified demos:

| Module | What the visitor gets | CONFIG |
|---|---|---|
| `messaging` | a messaging-app chat: reply buttons inside the bubble that asked, times on messages, a "Today" chip, "typing…" under the header name, a composer bar on button turns | `placeholder`, `dayLabel` |
| `steps` | a form: a progress bar that fills as they answer, "2 of 5", letter keys A, B, C for the buttons | `total` (questions on the longest path), `counter`, `counterText`, `keys` |

How to add one, on a bot `landbot-flows` created in this session:

1. **It must be part of the yes.** The one yes before building covers the Custom JS push only when its sentence named the behaviour ("and add the messaging behaviour"). Otherwise say what the script does and get a yes, as for a publish.
2. Copy the module's `.js` to a working file and **change only the values in its `CONFIG` block** (strings, numbers, true/false). `channel` checks that everything else is exactly the plugin's copy and refuses anything else. Append the module's `.css` to the end of the look's CSS and set its colour variables (`--lbm-*`, `--lbs-*`) from the brief in `:root`. Push the CSS first.
3. Push the script: `"${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows/scripts/channel" js /path/to/behaviour.js --bot <bot_id>`. It is live at once. It saves the channel's previous Custom JS first and prints the backup's path; `channel js --clear --bot <bot_id>` removes the script.
4. Read the answer. `served` means the published config carries exactly this script. Exit `5` means it carries a different one (the previous script may still be live: check again, never call it live); exit `4` means it could not be checked. **`NOT SERVED` (exit 3) means this account's published config does not carry Custom JS**: Landbot serves it only to accounts with the Custom Code feature. Do not guess which plans have it; say what the check found. The chat works without it, because every module rule in the CSS styles only what the script adds. Say that plainly; changing the plan is theirs to decide, not something to work around.
5. **Walk it** in the in-app browser (`landbot-flows` Step 6), then `read_console_messages` with errors only. A script error, a button that does not answer, or a page that stops responding is a failure: `channel js --clear` at once, say what happened, and hand back without the behaviour.

**A custom script, when neither module fits** and the person asked for a behaviour: say in plain words what it will do on their page and get their yes to "a custom script"; then push it with `--custom`. Keep it short and page-only. `channel js --custom` refuses a script over 60,000 characters, one without an `lb-js: <name>` marker, one containing `#{` (Landbot's firewall answers it with a 403), and the common ways a page script sends data out, reads cookies, loads or builds code, adds media or forms that fetch, or navigates. **That check is a lint, not a security boundary**: it catches mistakes, not a script written to get past it, so never describe a custom script as safe because it passed. Also: wrap everything in `try`; add only attributes, classes and your own elements, never move Landbot's nodes; read `textContent`, never `innerText`, inside anything that runs on page changes (it can loop); guard a `MutationObserver` so its own changes do not trigger it again; and write the CSS so the chat looks complete when the script does not run. Walk it exactly as above.

A bot the person already had: never push a script. Give them the file and these steps: open the bot in the builder → **Design** → **Custom code** → **Add JS**, paste, **Apply**, then **Publish**.

## Step 4 — Verify on the share URL (the only checks that prove anything)

```bash
"${CLAUDE_SKILL_DIR}/scripts/verify-share" <share-url> "lb-style: acme-dark"
```

Exit 0 means: v4 renderer, Custom CSS present in the **published** config, and your marker is in it. Anything else is a real failure. `FAIL: no Custom CSS in the published config` after a Publish means the plan is Sandbox: Custom CSS is dropped there. Say that plainly; the upgrade is the user's decision, not a bug to work around.

Then in the browser, on the share URL (`https://landbot.pro/v3/H-<channel>-<code>/index.html`), after answering one option so a user pill and the next question are visible:

```js
document.querySelectorAll('[data-lb-part]').length            // > 0 (about 16 on load, ~29 after two turns)
document.fonts.check('18px "<Font>"')                          // true when the @import loaded
getComputedStyle(document.querySelector('[data-lb-part="option-button"]')).backgroundColor
```

Take a screenshot if you can. Report what you checked and what you did not: a full-page share URL check does not verify the embedded bubble on a customer site.

### Look at it yourself in the in-app browser, when there is one

`verify-share` proves the CSS is in the published config, not that the chat looks right. **If this session has Claude's in-app browser** (the Claude desktop app's Code tab: tools named `mcp__Claude_Browser__*`), look at the chat there after the push. The person watches the look change in the side pane:

1. Open the share URL (`preview_start` with `url`, or `navigate` when the pane is open). Answer the first question with fake data so a user reply and the next question are on screen.
2. Run the three console checks above with `javascript_tool`, and take a screenshot at desktop width.
3. `resize_window` with preset `mobile`, reload the share URL with a new query string (`?look=2`), answer once, and take a second screenshot. Then `resize_window` with preset `desktop` to put the pane back.
4. Check these four things on both screenshots, against the brief:
   (a) every bot message is readable against its background;
   (b) the brand colours are on the bot bubble and the buttons;
   (c) the brand font is used (`document.fonts.check` is true);
   (d) every button and the input can be reached, and nothing is covered.
5. If one fails, fix the CSS, push again (same bot, still inside the yes), and repeat from step 1. Stop after three rounds and report what is still wrong.
6. With a behaviour module on, also check it did its job at both widths (reply buttons inside the bubble, or the bar filling), and that `read_console_messages` shows no error from it.

In the hand-back, say "looked at by me in the in-app browser at desktop and phone width", plus the result of each of the four checks.

**No in-app browser** (terminal, Codex, Cursor): give the share URL and the four checks above, and ask the person to open it on a computer and a phone. Until they answer, say "the CSS is live", never "styled".

## Step 5 — Hand back

- The CSS block (once, complete).
- How it was applied: the push, or the three paste steps; the backup path of what the push replaced.
- Any behaviour module, its CONFIG, and whether it is served (a plan without Custom JS stores it and does not serve it).
- The verify result, with the config URL.
- What the CSS could not reach (see REFERENCE.md §3) and any selector outside the catalog you used, marked fragile.
- One question, optional: "Which part or state could you not style?" Pass the answer on with the bot id as an issue on the skills repo (never the token).
