# Landbot skills for coding agents

Describe a conversation to Claude, Codex or Cursor; get a published Landbot bot with your own look, on a URL you can share or embed. The agent builds the flow through Landbot's Bots API, publishes when you say so, styles the web chat and checks the result on the live share URL.

What people build with it: lead-qualification bots, one-question-at-a-time forms, product configurators that end in a quote request, step-by-step lessons, AI assistants that answer from your docs and hand over to a human. Every one of them keeps Landbot's builder, inbox, integrations and WhatsApp channel underneath.

One plugin, `landbot`, with two skills:

| Skill | What it does |
|---|---|
| `landbot-flows` | Reads the live block catalog, creates the bot, places and wires blocks, sets up an AI agent block, publishes when you say so, puts the web chat on the current renderer, and hands back the builder link plus a one-line handoff. |
| `landbot-style` | Turns "make it look like our site / dark / like a form" into one Custom CSS block, pushes it to the channel (or tells you where to paste it) and verifies it on the published share URL. Two ready-made behaviours go beyond CSS: a messaging-app chat (reply buttons inside the bubble, times, "typing…") and a step form (progress bar, "2 of 5", letter keys). They are Custom JS, which Landbot serves to accounts with the Custom Code feature (the trial has it); the chat works without them. |

Requirements: a Landbot account (free to create; the 14-day trial includes the API token), `bash`, `curl`, `jq`. macOS, Linux or WSL.

## Install

Pick your agent. Each install gives you both skills.

**Claude desktop app, Code tab (recommended), no terminal.** Open **Customize › Plugins**, choose **Add marketplace**, paste `landbot-org/landbot-ai-skills`, then install **landbot**. Say "set up my Landbot token" in a new session in the Code tab. There the agent builds your chat live in the app's built-in browser, beside the conversation: you watch each question appear and the look change step by step, and it talks to the bot on every branch and checks it at desktop and phone width. (Cowork runs the skills too; it has no browser pane, and it is not tested end to end yet.)

**Claude Code (terminal).** Your agent can run these itself; you can also type them:

```bash
claude plugin marketplace add landbot-org/landbot-ai-skills
```

```bash
claude plugin install landbot@landbot-skills
```

Slash-command form, if you prefer typing inside Claude Code: `/plugin marketplace add landbot-org/landbot-ai-skills` then `/plugin install landbot@landbot-skills`.

**Codex (CLI or app).** Codex reads this repo as a plugin marketplace:

```bash
codex plugin marketplace add landbot-org/landbot-ai-skills
```

```bash
codex plugin add landbot@landbot-skills
```

Or copy the skill folders directly (works on every Codex version):

```bash
git clone https://github.com/landbot-org/landbot-ai-skills && landbot-ai-skills/scripts/install.sh codex
```

**Cursor.** From your project root (`--global` puts them in `~/.cursor/skills/` for every project):

```bash
git clone https://github.com/landbot-org/landbot-ai-skills && landbot-ai-skills/scripts/install.sh cursor
```

Each skill prints its version (`landbot-flows 0.3.4`) the first time it runs. If you see an older number, an earlier copy is still installed; remove it (`claude plugin uninstall`, or delete the folder `install.sh` printed) so only one is left.

## Your token

1. Open https://app.landbot.io/gui/settings/account and copy the read-only **API token** field.
2. In your agent, say: `set up my Landbot token`. On macOS the skill reads it from the clipboard, checks it against the API, stores it in your keychain and clears the clipboard. On Linux and Windows it asks you to `export LANDBOT_API_TOKEN='…'` in your own shell, then checks it.
3. **Never paste the token into the chat.** The skills refuse a token that arrived that way, because a Landbot token cannot be rotated. Nothing in this repo stores your token anywhere but your own keychain or shell.

## First bot

> Build a lead-qualification bot for `<your site>`: greet, ask name, email and company size, tell companies over 50 people a person will follow up, thank the rest. Publish it and give me the builder link and the share URL.

The skill names the account it is about to write to, asks once before building (that yes covers the publish, the switch to the current web chat and, if you described a look, the CSS it pushes) or before every write on a bot you already had, and ends with one line:

```
LANDBOT_HANDOFF bot=<uuid> builder=<id> share=https://landbot.pro/v3/H-<channel>-<code>/index.html channel=<id> version=3.1.0
```

Then: "make it look like `<your site>`". The style skill asks, writes the CSS to the channel (live at once) and verifies the share URL. If it tells you to paste instead, it gives the three clicks (Design › Custom code › Add CSS, Apply, Publish).

## Embed

Share → Embed in the builder gives you the snippet. Paste it on any page.

## 401 or 403 on the first call

The token check answers `401` or `403` for three different reasons, and the API does not say which:

1. **Your account is not enabled for the Bots API yet.** The API is in preview and Landbot switches it on per account. Ask the assistant on https://landbot.io/skills or book the 15-minute setup call there, and give your account email in that private channel (never in a public issue, and never the token); we enable it. Nothing to fix on your side.
2. The token was not copied whole. Copy the field again and run `set up my Landbot token` once more.
3. Your user lacks the "view chatbot" or "edit chatbot" permission in the workspace.

Do not paste the token into the chat to "check it".

## Updates

Claude Code and Codex fetch updates from this repo: `claude plugin update landbot@landbot-skills` or `codex plugin marketplace upgrade`. `install.sh` users run it again. If you installed it from one of Anthropic's marketplaces instead, a new version reaches that marketplace a day or more after it is released here. The skills read the live API contract at run time, so a new block type on Landbot's side needs no update here.

## What this is not

Not a hosted MCP server, no OAuth, no server that holds your token. Everything runs on your machine with your credentials. Chat apps (claude.ai, ChatGPT) cannot run these skills yet.

## Feedback

Open an issue here with the bot id and the step that failed; never the token.

## License

MIT, see `LICENSE`.
