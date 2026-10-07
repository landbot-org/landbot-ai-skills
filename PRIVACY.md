# Privacy

This is the privacy policy of the **landbot** plugin for coding agents (the `landbot-flows` and `landbot-style` skills in this repository). It describes what the plugin reads on your machine, what it stores, what it sends and to whom. It applies to the plugin only. What Landbot does with the data that reaches its services is covered by Landbot's [Privacy Policy](https://landbot.io/privacy-policy), which applies to your Landbot account whether or not you use this plugin.

Last updated: 2026-10-07. The policy is versioned with the repository; its history is the file's Git history.

## The short version

The plugin is a set of instructions and one script that run inside your coding agent. The agent reaches Landbot through the Landbot MCP server, `mcp.landbot.io`, with the access you allowed when you signed in to Landbot. The plugin has no server of its own, no analytics and no telemetry, and it holds no Landbot credential.

## What the plugin reads on your machine

- **Files you name**, such as a CSS file you ask it to apply to a web chat.
- Nothing else: no environment variables, browser data or credentials.

## What it stores on your machine

Nothing. Your coding agent keeps the access you allowed at sign-in, under that agent's own terms, until you sign out.

## What it sends, and to whom

- **mcp.landbot.io**, Landbot's MCP server, which acts on your Landbot account. It receives what you asked the agent to build or change: the flow and its texts, AI agent settings and web chat settings such as Custom CSS. What you create stays in your Landbot account until you delete it there, under Landbot's Privacy Policy.
- **storage.googleapis.com/landbot.pro**, **/landbot.online** and **/landbot.site**, the public buckets that serve published chat configs, the same files the share URL loads in a visitor's browser. `verify-share` reads a config by its public share code (`H-<id>-<code>`) to verify a share URL. Nothing else is sent.

Nothing is sent to Anthropic, OpenAI, Cursor, or to Landbot beyond the requests above.

## Personal data

- **Visitor data.** The bots you build may collect names, emails or other data from the people who talk to them once published. That data is collected by Landbot and lives in your Landbot account. The plugin only reads and writes bot definitions, AI agents and web chat settings.

## What your coding agent sees

Everything the Landbot tools answer, such as bot definitions, share URLs and block names, becomes part of your conversation with your coding agent (Claude, Codex or Cursor) and is handled under that provider's terms.

## Children

The plugin is not intended for people under 18.

## Contact

Questions about this policy, or about how Landbot handles your data: legal@landbot.io, the same contact as Landbot's [Privacy Policy](https://landbot.io/privacy-policy). A security problem in the plugin: the repository's private vulnerability reporting or security@landbot.io, never a public issue.
