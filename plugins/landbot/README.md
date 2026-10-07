# Landbot

Describe a conversation to your coding agent and get a published Landbot bot with your own look, on a URL you can share or embed. The agent builds the flow through the Landbot MCP server, publishes when you say so, styles the web chat and checks the result on the live share URL. Underneath it is a normal Landbot bot: you keep the builder, the inbox, the integrations and the WhatsApp channel.

## What people build with it

- Lead-qualification bots that greet, ask a few questions and route the promising ones to a person.
- One-question-at-a-time forms, with a progress bar if you want one.
- Product configurators that end in a quote request.
- Step-by-step lessons and onboarding walkthroughs.
- AI assistants that answer from your docs and hand over to a human.

## How it works

1. Install the plugin.
2. The first time the agent uses Landbot, your browser opens Landbot's sign-in and asks you to allow access. There is no token to copy.
3. Describe the bot. For example:

> Build a lead-qualification bot for our site: greet, ask name, email and company size, tell companies over 50 people that a person will follow up, thank the rest. Publish it and give me the builder link and the share URL.

The agent builds the bot and its look before anything is live, asks once before publishing, and ends with the builder link and the share URL.

In the Claude desktop app's Code tab, the agent opens the chat in the app's built-in browser beside the conversation: you watch the look change step by step, and once it is published the agent tries the bot on every branch, at desktop and phone width.

## The two skills

**landbot-flows** reads Landbot's live block catalog, creates the bot, places and wires the blocks, sets up an AI agent block when the brief calls for one, and publishes on your say-so. It hands back the builder link, the share URL and a plain description of the conversation. Because it reads the catalog at run time, a new block type on Landbot's side needs no update here.

**landbot-style** turns a brief ("like our site", "dark", "like a form") into one Custom CSS block for the v4 web chat, applies it or tells you where to paste it, and verifies it on the published share URL. Two ready-made behaviours go beyond CSS: a messaging-app chat (reply buttons inside the bubble, times, "typing…") and a step form (progress bar, "2 of 5", letter keys). They are Custom JS, which you paste in the builder and Landbot serves to accounts with the Custom Code feature; the trial has it, and the chat works without them.

## Where it runs

Claude Code, or the Claude desktop app's Code tab, which is the recommended way. Cowork runs it too, without the browser pane; it is not tested end to end yet. Codex and Cursor are covered from the repository. Requirements: a Landbot account.

## What the agent will and will not do

- It builds and styles a new bot before anything is live, then asks once before publishing it. On a bot you already had, it asks before every change.
- On a published bot, changes to the web chat's look go to the bot's draft, which you publish from the builder.
- It acts only with the access you allowed at sign-in, and you can sign out at any time.

## Where data goes

The agent talks to one Landbot host, **mcp.landbot.io**, which acts on your Landbot account with the access you allowed. The skills also read **storage.googleapis.com/landbot.pro**, **/landbot.online** and **/landbot.site**, the public buckets that serve published chat configs, to verify a share URL. The full account is in SECURITY.md in the repository.

Privacy: what the plugin reads on your machine, stores and sends is set out in the plugin's [Privacy policy](https://github.com/landbot-org/landbot-ai-skills/blob/main/PRIVACY.md). What Landbot does with the data that reaches its services is covered by Landbot's [Privacy Policy](https://landbot.io/privacy-policy).

## Docs and support

Install steps for Claude Code, the Claude desktop app, Codex and Cursor, updates and the changelog: https://github.com/landbot-org/landbot-ai-skills. Open an issue there with the bot id and the step that failed. Security reports go through the repository's private vulnerability reporting or to security@landbot.io.

License: MIT.
