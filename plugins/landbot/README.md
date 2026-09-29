# Landbot

Build, style and publish Landbot bots from your coding agent. Describe the conversation you want; the agent builds the flow through Landbot's Bots API, publishes when you say so, styles the web chat and checks the result on the live share URL.

Two skills:

- **landbot-flows** reads the live block catalog, creates the bot, places and wires blocks, sets up an AI agent block, publishes on your say-so, and hands back the builder link plus a one-line handoff.
- **landbot-style** turns a brief ("like our site", "dark", "like a form") into one Custom CSS block for the v4 web chat, pushes it to the channel or tells you where to paste it, and verifies it on the published share URL. Two ready-made Custom JS behaviours come with it: a messaging-app chat and a step form.

Requirements: a Landbot account with the Bots API enabled (Landbot switches it on per account; the 14-day trial includes the API token), `bash`, `curl` and `jq`. macOS, Linux or WSL.

## Your token

Copy the read-only API token from Settings › Account in the Landbot app, then tell the agent "set up my Landbot token". On macOS the token goes from the clipboard to your login keychain, verified against the API on the way, and the clipboard is cleared. On Linux and Windows you export `LANDBOT_API_TOKEN` in your own shell. The skills never print the token, never write it to a file, and refuse one pasted into the chat, because a Landbot token cannot be rotated.

## What it runs and where data goes

Everything runs on your machine as plain bash scripts with `curl` and `jq`. There is no MCP server, no OAuth and no hosted component.

- **api.landbot.io**, Landbot's own API: every request carries your token and a user agent naming the plugin version and the coding agent. This is the only place the token is ever sent.
- **storage.googleapis.com/landbot.pro**, the public bucket that serves published channel configs: read, without a token, to verify a share URL and to build a local preview of a draft.
- **cdn.landbot.io**, the web chat library: loaded, without a token, by the local preview page.

Writes go only to bots the token's account can edit, and every write asks you first. The full account of what is written where is in SECURITY.md in the repository.

## Docs and support

Install steps for Claude Code, the Claude desktop app, Codex and Cursor, the first bot, troubleshooting and updates: https://github.com/landbot-org/landbot-ai-skills. Open an issue there with the bot id and the step that failed, never the token. Report a security problem through the repository's private vulnerability reporting or to security@landbot.io.

License: MIT.
