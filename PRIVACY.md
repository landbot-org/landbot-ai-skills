# Privacy

This is the privacy policy of the **landbot** plugin for coding agents (the `landbot-flows` and `landbot-style` skills in this repository). It describes what the plugin reads on your machine, what it stores, what it sends and to whom. It applies to the plugin only. What Landbot does with the data that reaches its services is covered by Landbot's [Privacy Policy](https://landbot.io/privacy-policy), which applies to your Landbot account whether or not you use this plugin.

Last updated: 2026-09-29. The policy is versioned with the repository; its history is the file's Git history.

## The short version

The plugin is a set of bash scripts that run on your machine, inside your coding agent, with your own Landbot API token. It sends what you ask it to build to Landbot's API and nothing anywhere else. It has no server of its own, no analytics, no telemetry beyond a user agent string, and it never prints your token.

## What the plugin reads on your machine

- **Your Landbot API token**, from one of two places: the macOS login keychain entry it created (`landbot-api-token`), or the `LANDBOT_API_TOKEN` environment variable you set in your own shell. When you run `setup-token` on macOS it also reads the clipboard once, to take the token you just copied, and clears the clipboard afterwards.
- **Files you name**, such as a CSS or JS file you ask it to push to a channel.
- **Its own state folder**, `~/.landbot` by default (`LANDBOT_STATE_DIR` to move it). See "What it stores" below.
- **A few environment variables** that say which coding agent is running (`CLAUDECODE`, `CODEX_*`, `CURSOR_*`), only to name that agent in the user agent string. Apart from those and its own `LANDBOT_*` settings (API base URLs, the state folder, the keychain entry name), it reads no other environment variables, files, browser data or credentials.

## What it stores on your machine

- **The token**, in the macOS login keychain, if you chose `setup-token`. On Linux and Windows it stores nothing: the token lives in your shell. `setup-token --forget` removes the keychain entry.
- **Working state under `~/.landbot`**: snapshots of the bot drafts this plugin last wrote (so it can tell when someone else changed a draft), a record of the bots it created on this machine, a copy of a channel's CSS and JS taken before each write (so a change can be undone), and the local preview pages it builds. These hold bot definitions and styling, never your token and never visitor data. Delete the folder at any time; the plugin recreates what it needs.

## What it sends, and to whom

- **api.landbot.io**, Landbot's own API, the same server the Landbot app talks to. Every request carries your API token in the `Authorization` header and the content you asked the plugin to write: the flow and its texts, AI agent block settings, channel settings, Custom CSS and Custom JS. Each request also carries a user agent such as `landbot-plugin/<version> (landbot-flows; agent=claude-code)`, naming the plugin version and the coding agent, so Landbot can count plugin use and failures per version. No user identifier, machine identifier or other content is added. What you create stays in your Landbot account until you delete it there, under Landbot's Privacy Policy. This is the only place the token is ever sent.
- **storage.googleapis.com/landbot.pro**, **/landbot.online** and **/landbot.site**, the public buckets that serve published channel configs (Landbot serves each account on one of the three), the same files the share URL loads in a visitor's browser. The plugin reads a config by its public share code (`H-<id>-<code>`) to verify a share URL and to build a local preview. No token is sent.
- **cdn.landbot.io**, the web chat library, loaded by the local preview page when you open it in your browser. No token is sent.

Nothing is sent to Anthropic, OpenAI, Cursor, or to Landbot beyond the requests above. The plugin has no server, no analytics and no crash reporting.

## Personal data

- **Your own name and email.** To tell you which Landbot account it is about to write to, the plugin asks the API whose token it holds (`setup-token --whoami`) and shows the account's name and email in the chat. It does not store them.
- **Visitor data.** The bots you build may collect names, emails or other data from the people who talk to them once published. That data is collected by Landbot and lives in your Landbot account. It never passes through the plugin, which only reads and writes bot definitions, channel settings and styling.
- **Other people's channels.** To find the share URL of a bot, the plugin lists the channels of your account through the API. It keeps only the one channel it was asked about and prints only that channel's public share code.

## What your coding agent sees

Everything the scripts print, such as bot definitions, share URLs, block names and the account's name and email, becomes part of your conversation with your coding agent (Claude, Codex or Cursor) and is handled under that provider's terms. The token is never printed, never passed as a command-line argument and never written to a file by the plugin, so it does not enter that conversation. If you paste it into the chat yourself, the skills refuse it and tell you it is now in your conversation history.

## Children

The plugin is not intended for people under 18.

## Contact

Questions about this policy, or about how Landbot handles your data: legal@landbot.io, the same contact as Landbot's [Privacy Policy](https://landbot.io/privacy-policy). A security problem in the plugin: the repository's private vulnerability reporting or security@landbot.io, never a public issue and never with a token in it.
