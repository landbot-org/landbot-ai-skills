# Landbot skills for coding agents

Describe a conversation to Claude, Codex or Cursor; get a published Landbot bot with your own look, on a URL you can share or embed. The agent builds the flow through the Landbot MCP server, publishes when you say so, styles the web chat and checks the result on the live share URL.

What people build with it: lead-qualification bots, one-question-at-a-time forms, product configurators that end in a quote request, step-by-step lessons, AI assistants that answer from your docs and hand over to a human. Every one of them keeps Landbot's builder, inbox, integrations and WhatsApp channel underneath.

One plugin, `landbot`, with two skills:

| Skill | What it does |
|---|---|
| `landbot-flows` | Reads the live block catalog, creates the bot, places and wires blocks, sets up an AI agent block, puts the web chat on the current renderer, publishes when you say so, and hands back the builder link and the share URL. |
| `landbot-style` | Turns "make it look like our site / dark / like a form" into one Custom CSS block, applies it to the web chat (or tells you where to paste it) and verifies it on the published share URL. Two ready-made behaviours go beyond CSS: a messaging-app chat (reply buttons inside the bubble, times, "typing…") and a step form (progress bar, "2 of 5", letter keys). They are Custom JS, which you paste in the builder and Landbot serves to accounts with the Custom Code feature (the trial has it); the chat works without them. |

Requirements: a Landbot account (free to create) and a coding agent that connects to remote MCP servers.

## Install

Pick your agent. Each install gives you both skills.

**Claude desktop app, Code tab (recommended), no terminal.** Open **Customize › Plugins**, choose **Add marketplace**, paste `landbot-org/landbot-ai-skills`, then install **landbot**, and describe your bot in a new session in the Code tab. There the agent builds your chat live in the app's built-in browser, beside the conversation: you watch each question appear and the look change step by step, and it talks to the bot on every branch and checks it at desktop and phone width. (Cowork runs the skills too; it has no browser pane, and it is not tested end to end yet.)

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

Then connect the Landbot MCP server:

```bash
codex mcp add landbot --url https://mcp.landbot.io/mcp && codex mcp login landbot
```

Or copy the skill folders directly (works on every Codex version), and connect the server the same way:

```bash
git clone https://github.com/landbot-org/landbot-ai-skills && landbot-ai-skills/scripts/install.sh codex
```

**Cursor.** From your project root (`--global` puts them in `~/.cursor/skills/` for every project):

```bash
git clone https://github.com/landbot-org/landbot-ai-skills && landbot-ai-skills/scripts/install.sh cursor
```

Then add `https://mcp.landbot.io/mcp` as a remote MCP server in Cursor's MCP settings.

Each skill prints its version (`landbot-flows 0.5.0`) the first time it runs. If you see an older number, an earlier copy is still installed; remove it (`claude plugin uninstall`, or delete the folder `install.sh` printed) so only one is left.

## Signing in

The first time the agent uses Landbot, your browser opens Landbot's sign-in and asks you to allow access. There is no token to copy: the agent acts as you, on your brand, with the access you allowed, and you can sign out from the agent (`/mcp` in Claude Code) at any time.

## First bot

> Build a lead-qualification bot for `<your site>`: greet, ask name, email and company size, tell companies over 50 people a person will follow up, thank the rest. Publish it and give me the builder link and the share URL.

The skill builds the bot and styles it before anything is live, then asks once before publishing it. On a bot you already had, it asks before every change. It ends with the builder link, the share URL and a plain description of the conversation.

Then: "make it look like `<your site>`". On a bot that was never published the look applies at once; on a published one it goes to the bot's draft, which you publish from the builder.

## Embed

Share → Embed in the builder gives you the snippet. Paste it on any page.

## Updates

Claude Code and Codex fetch updates from this repo: `claude plugin update landbot@landbot-skills` or `codex plugin marketplace upgrade`. `install.sh` users run it again. The skills read the live block catalog at run time, so a new block type on Landbot's side needs no update here. What changed in each version is on the [Releases](https://github.com/landbot-org/landbot-ai-skills/releases) page.

## Upgrading from 0.4

0.5.0 no longer uses the API token or the local state of earlier versions, and cannot remove them for you. The token cannot be rotated, so remove it:

```bash
security delete-generic-password -a "$USER" -s landbot-api-token   # macOS keychain
rm -rf ~/.landbot                                                  # drafts, backups and previews of 0.4
```

On Linux and WSL, also remove the `export LANDBOT_API_TOKEN=…` line from your shell profile.

## Where data goes

The agent talks to one Landbot host, `mcp.landbot.io`, which acts on your Landbot account with the access you allowed at sign-in. The only other hosts the skills read are `storage.googleapis.com/landbot.pro`, `/landbot.online` and `/landbot.site`, the public buckets that serve published chat configs, to verify a share URL.

## Privacy

What the plugin reads on your machine, stores and sends, and to whom, is set out in [PRIVACY.md](PRIVACY.md). What Landbot does with the data that reaches its services is covered by Landbot's [Privacy Policy](https://landbot.io/privacy-policy).

## Feedback

Open an issue here with the bot id and the step that failed.

## License

MIT, see `LICENSE`.
