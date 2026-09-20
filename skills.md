# Landbot AI skills: setup instructions for coding agents

You are a coding agent (Claude Code, the Claude desktop app, Codex or Cursor) and a person asked you to set up the Landbot skills. Follow these steps in order. Steps marked **HUMAN** are done by the person: say what you need, then stop and wait.

Rules that hold for the whole session:
- Never ask for the Landbot API token, never print it, never write it into a file or a command. It cannot be rotated.
- If the person pastes a token into the chat, stop, tell them it is now in the conversation history, and continue only with a token stored through the script below.
- Before the first write, say which Landbot account you are acting on. For a bot you create in this session, ask once before building (step 5); that yes covers its publish, its web-chat switch and, only if they described a look, its CSS push. A no means build nothing. For a bot the person already had, say which bot and get a yes before the first write, and ask again before a test deploy and before a publish; never switch its web chat. For a bot the person already had, ask before every write.

## 0. Prerequisites
`bash`, `curl`, `jq`. macOS, Linux or WSL. If you run inside the Claude desktop app (Cowork), you have a shell; use it for the commands below.

## 1. HUMAN: create a Landbot account
https://app.landbot.io/signup_intent/?utm_source=skills_md — free; the 14-day trial includes the API token. Email verification is theirs to do.

## 2. Install the `landbot` plugin (both skills)
Run these yourself through your shell; no restart is needed (see the note at the end of this step).

Claude Code:
```bash
claude plugin marketplace add landbot-org/landbot-ai-skills
claude plugin install landbot@landbot-skills
```
If your shell cannot run `claude`, the person types these inside Claude Code instead: `/plugin marketplace add landbot-org/landbot-ai-skills` then `/plugin install landbot@landbot-skills`.

Codex:
```bash
codex plugin marketplace add landbot-org/landbot-ai-skills
codex plugin add landbot@landbot-skills
```
Or, on any Codex version: `git clone https://github.com/landbot-org/landbot-ai-skills && landbot-skills/scripts/install.sh codex`

Cursor (from the project root; add `--global` for all projects):
```bash
git clone https://github.com/landbot-org/landbot-ai-skills && landbot-skills/scripts/install.sh cursor
```

**No terminal (Claude desktop app, Cowork):** the person opens **Customize › Plugins › Add marketplace**, pastes `landbot-org/landbot-ai-skills`, installs **landbot**, then starts a new session. The rest of these steps are the same, with one difference in step 4.

After installing, check the skill answers with `landbot-flows 0.3.1` as its first line. An older number means a stale copy is also installed; remove it before going on. A new session sees the plugin at once; if you installed it inside a running Claude Code session, run `/reload-plugins` (Claude Code prints "Run /reload-plugins to activate" when that is needed).

## 3. HUMAN: copy the API token
Ask them to open https://app.landbot.io/gui/settings/account and copy the read-only **API token** field, then tell you "done". Do not ask them to show or confirm it. On macOS only (`uname` prints `Darwin`) you may run `open https://app.landbot.io/gui/settings/account` so the page is one click away; the copy stays theirs.

## 4. Store and verify the token
macOS: run `scripts/setup-token` from the `landbot-flows` skill (the skill tells you the exact path). It reads the clipboard, checks the token against the API, stores it in the keychain and clears the clipboard.
Linux, Windows, CI: **HUMAN** runs `export LANDBOT_API_TOKEN='…'` in their own shell; then you run `scripts/setup-token --check`.
Claude desktop app (Cowork): same as macOS, the skill runs `setup-token` in its shell and reads the clipboard. Not yet verified inside Cowork; if the clipboard read fails there, use Claude Code in a terminal for this one step, or book the setup call.
Then run `scripts/setup-token --whoami` and report the account verbatim.

If the check answers 401 or 403, say all three causes and stop; do not loop on re-copying the token:
1. The account is not enabled for the Bots API yet (Landbot switches it on per account; nothing the person can fix). Tell them to open an issue at https://github.com/landbot-org/landbot-ai-skills with their account email, or ask the assistant on the skills page.
2. The token was not copied whole.
3. The user lacks the "view chatbot" permission.

## 5. Build the first bot
Use the `landbot-flows` skill with the person's description. **If they asked for a bot but gave no description, or said "show me", do not interview them:** build the skill's default lead-qualification bot (greet, ask name, email and company size, tell companies over 50 people a person will follow up, thank the rest), publish it on the v4 web chat with Landbot's default look, and offer styling as the next step. Do not push a style nobody described. They can change anything afterwards.

Ask **once, before building**: "I will build it, publish it, switch its web chat to the current version and apply the look you described; live at once on your share URL. Go?" (drop the last clause when they described no look). That yes covers the publish, the web-chat switch (step 6) and, when the clause was in it, the CSS push (step 6), for the one bot you create right after it; do not ask three more times. **A no means build nothing.** An answer that names only part of it covers only that part. If the request already says "publish it", that is the yes for the publish only. A second bot needs its own yes. End with the builder link, a plain-language description of the conversation, and the `LANDBOT_HANDOFF` line the skill prints.

## 6. Style it
Read `version` in the handoff line.
- `3.1.0`: use the `landbot-style` skill: "make it look like <their site>". For a bot you created in this session the skill pushes the CSS to the channel (live at once; covered by the step-5 yes); otherwise **HUMAN** pastes it in Design › Custom code › Add CSS, clicks Apply, then Publish. Verify with `scripts/verify-share <share-url>`; only the share URL counts, the builder preview never shows Custom CSS.
- `3.0.0` on a bot you created in this session: run the flows skill's `channel v4` step (it switches that channel to the current web chat; live at once, covered by the step-5 yes), re-read the handoff line, then style.
- `3.0.0` on a bot the person already had: do not flip it. Say Custom CSS needs the v4 web chat and that Landbot switches it per account.

## 7. Embed
Offer to add the embed snippet (builder › Share › Embed) to their site's code. **HUMAN** deploys.

## Limits
Bots API preview: 24 block types; on the v4 web chat use `buttons` for yes/no and do not rely on `code` blocks. Custom CSS and JS need the trial or a paid plan. Chat apps (claude.ai, ChatGPT) are not supported yet.

Help: open an issue at https://github.com/landbot-org/landbot-ai-skills (bot id and step; never a token) or use the assistant on the skills page.
