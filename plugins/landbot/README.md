# Landbot

Describe a conversation to your coding agent and get a published Landbot bot with your own look, on a URL you can share or embed. The agent builds the flow through Landbot's Bots API, publishes when you say so, styles the web chat and checks the result on the live share URL. Underneath it is a normal Landbot bot: you keep the builder, the inbox, the integrations and the WhatsApp channel.

## What people build with it

- Lead-qualification bots that greet, ask a few questions and route the promising ones to a person.
- One-question-at-a-time forms, with a progress bar if you want one.
- Product configurators that end in a quote request.
- Step-by-step lessons and onboarding walkthroughs.
- AI assistants that answer from your docs and hand over to a human.

## How it works

1. Install the plugin and copy the read-only API token from Settings › Account in the Landbot app.
2. In a new session, say "set up my Landbot token". On macOS the skill takes it from the clipboard, checks it against the API, stores it in your keychain and clears the clipboard. On Linux and Windows it asks you to export it in your own shell.
3. Describe the bot. For example:

> Build a lead-qualification bot for our site: greet, ask name, email and company size, tell companies over 50 people that a person will follow up, thank the rest. Publish it and give me the builder link and the share URL.

The agent names the account it is about to write to, asks once before building, and ends with the builder link and the share URL. Then say "make it look like our site" and watch the look change.

In the Claude desktop app's Code tab, the agent opens the chat in the app's built-in browser beside the conversation: you watch each question appear and the look change step by step, and it tries the bot on every branch, at desktop and phone width.

## The two skills

**landbot-flows** reads Landbot's live block catalog, creates the bot, places and wires the blocks, sets up an AI agent block when the brief calls for one, and publishes on your say-so. It hands back the builder link and a one-line handoff for the style skill. Because it reads the catalog at run time, a new block type on Landbot's side needs no update here.

**landbot-style** turns a brief ("like our site", "dark", "like a form") into one Custom CSS block for the v4 web chat, pushes it to the channel or tells you where to paste it, and verifies it on the published share URL. Two ready-made behaviours go beyond CSS: a messaging-app chat (reply buttons inside the bubble, times, "typing…") and a step form (progress bar, "2 of 5", letter keys). They are Custom JS, which Landbot serves to accounts with the Custom Code feature; the trial has it, and the chat works without them.

## Where it runs

The skills are bash scripts, so they need an agent with a terminal: Claude Code, or the Claude desktop app's Code tab, which is the recommended way. Cowork runs them too, without the browser pane; it is not tested end to end yet. Claude.ai chat cannot run them. Codex and Cursor are covered from the repository.

Requirements: a Landbot account with the Bots API enabled, `bash`, `curl` and `jq`, on macOS, Linux or WSL. The 14-day trial includes the API token. Landbot switches the Bots API on per account; see the last section if the first call is refused.

## What the agent will and will not do

- It asks before it builds. That one yes covers the publish, the switch to the current web chat and the look you described. On a bot you already had, it asks before every write.
- On a bot you already had, changes to the web chat's look go to the bot's draft, which it shows you as a local preview, and are published only when you say yes or when you press Publish in the builder.
- It refuses to write over unpublished changes someone made in the builder.
- It never prints your token, never writes it to a file, and refuses a token pasted into the chat, because a Landbot token cannot be rotated from the app.

## Your token, and where data goes

The token is sent to one place: **api.landbot.io**, Landbot's own API, the same server the Landbot app talks to. There is no MCP server, no OAuth and no hosted component. Nothing sits between your machine and that API. Each request carries a user agent naming the plugin version and the coding agent, so Landbot can count plugin use per version; no user, machine or content data is added.

Two hosts are read without the token: **storage.googleapis.com/landbot.pro**, the public bucket that serves published channel configs, to verify a share URL and to preview a draft; and **cdn.landbot.io**, the web chat library that the local preview page loads. The full account of what is written where is in SECURITY.md in the repository.

Privacy: what the plugin reads on your machine, stores and sends is set out in the plugin's [Privacy policy](https://github.com/landbot-org/landbot-ai-skills/blob/main/PRIVACY.md). What Landbot does with the data that reaches its services is covered by Landbot's [Privacy Policy](https://landbot.io/privacy-policy).

## If the first call answers 401 or 403

There is no Bots API switch to enable on an account any more, so a refusal is never about enabling it. `401` is the token (not copied whole, or the user deactivated): copy the "API token" field again. `403` is the user or the workspace (missing "view chatbot" or "edit chatbot" permission, or a disabled or locked workspace): the workspace admin fixes it. A `403` on a write when reads work is a trial that has ended. A `FIREWALL:` line (an answer that is not Landbot's JSON, often with a Ray ID) is the firewall in front of the API or a proxy, not Landbot. Never paste the token into the chat; the assistant on https://landbot.io/skills can help.

## Docs and support

Install steps for Claude Code, the Claude desktop app, Codex and Cursor, updates and the changelog: https://github.com/landbot-org/landbot-ai-skills. Open an issue there with the bot id and the step that failed, never the token. Security reports go through the repository's private vulnerability reporting or to security@landbot.io.

License: MIT.
