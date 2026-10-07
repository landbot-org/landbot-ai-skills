# Security

The plugin holds no Landbot credential. The agent reaches Landbot through the Landbot MCP server, `mcp.landbot.io`, after you sign in to Landbot in your browser and allow access. Your coding agent keeps the access it is given and you can sign out from it at any time (`/mcp` in Claude Code, `codex mcp logout landbot` in Codex).

- The access covers what you allowed at sign-in: reading and changing your bots, AI agents and web chats on your brand. A new kind of change asks you again.
- On a web chat, the plugin changes only its version, Custom CSS and Back button. It never writes Custom JS: you paste that in the builder yourself.
- `landbot-style/scripts/verify-share` reads `storage.googleapis.com/landbot.pro`, `/landbot.online` and `/landbot.site`, the public buckets that serve published chat configs (the share URL itself loads the config from there). Nothing is sent beyond the share code that is already in the public share URL.

To report a security issue in this repo, use **Security and quality › Report a vulnerability** on GitHub (https://github.com/landbot-org/landbot-ai-skills/security/advisories/new): the report is private and only the maintainers see it. You can also write to security@landbot.io. Do not open a public issue for a security problem.
