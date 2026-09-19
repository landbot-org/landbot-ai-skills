---
name: landbot-style
description: Style a Landbot v4 web chat. Turn a brief (brand colours, a reference site, "make it look like IBM / dark / our site") into ONE Custom CSS block — theme tokens in :root, data-lb-* anchors, scrollbars — that the user pastes into Design › Custom code › Add CSS, then verify it on the published share URL. Use when asked to style, theme, restyle or brand a Landbot chat, or right after landbot-flows hands back a LANDBOT_HANDOFF line.
allowed-tools: Bash("${CLAUDE_SKILL_DIR}/scripts/verify-share" *) Bash("${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows/scripts/handoff" *) Bash("${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows/scripts/channel" get *) Bash(jq *)
metadata:
  short-description: Style a Landbot v4 web chat with one Custom CSS block
  version: 0.3.0
---

**First line of your first reply when this skill activates: `landbot-style 0.3.0`.** Then carry on. A different version shown elsewhere means two copies are installed; the one printed is the one running.

Read [REFERENCE.md](REFERENCE.md) first (the v4 gate, apply and verify mechanics, what CSS cannot reach). The token and anchor catalog with a full worked example is in [references/style-catalog.md](references/style-catalog.md). Build the flow with `landbot-flows`; this skill only styles.

## Where the scripts are

This skill ships `scripts/verify-share` (no token needed). Pushing CSS to a channel uses `scripts/channel` from the sibling `landbot-flows` skill (same plugin, same install), which reads the person's token the same way `lb` does.

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

If the version is `3.0.0` and the bot was **created in this session by `landbot-flows`**: do not stop. Run that skill's Step 5a (`channel v4 <channel_id> --bot <bot_id>`, then publish again with the person's yes) and re-read the handoff line. If the bot is one the person already had: **stop.** Say the channel is on the legacy renderer, Custom CSS will not render there, and that Landbot switches the web chat version per account; do not flip a channel you did not create and do not generate CSS "just in case".

Also say, once: the builder's Design preview never renders Custom CSS. Only the share URL counts.

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

Two ways. Use the first for a bot `landbot-flows` created in this session; the second for any other bot.

**A. Push it through the API (bots created this session).** Write the block to a file and push it to the channel. **The push is live for visitors the moment it answers** (the channels API regenerates the published config; no publish step), so say that first and get a yes, exactly as for a publish:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/landbot-flows/scripts/channel" css <channel_id> /path/to/style.css --bot <bot_id>   # WRITE, live at once
```

`channel` refuses a channel that is not the bot's or that is older than 24 hours, so it cannot touch a bot the person already had. Say before the push that the channel's Custom CSS field is replaced whole.

**B. The person pastes it in the app (any bot).** Give them exactly this, no more:

1. Open the bot in the builder → **Design** → **Custom code** → **Add CSS**.
2. Select everything in the field, delete it, paste the block. A duplicated bot inherits old CSS, so replace, never append.
3. Click **Apply** (writes the test channel), then **Publish** (writes the live channel and regenerates the published config).

If you are driving their browser yourself (Claude in Chrome, Playwright): the field is a CodeMirror 6 editor. Do not type 150 lines; set the document through the editor view, then click Apply. Never touch session cookies.

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

## Step 5 — Hand back

- The CSS block (once, complete).
- How it was applied: the push, or the three paste steps.
- The verify result, with the config URL.
- What the CSS could not reach (see REFERENCE.md §3) and any selector outside the catalog you used, marked fragile.
- One question, optional: "Which part or state could you not style?" Pass the answer on with the bot id as an issue on the skills repo (never the token).
