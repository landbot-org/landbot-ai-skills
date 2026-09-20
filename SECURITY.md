# Security

**The Landbot API token cannot be rotated from the app.** Treat it like a password you cannot change.

How these skills handle it:

- macOS: `scripts/setup-token` reads it from the clipboard, verifies it with one `GET /blocks`, stores it in the login keychain under `landbot-api-token`, clears the clipboard. `scripts/lb` reads it back and hands it to `curl` over stdin, so it never appears in a process list, a shell history line or a transcript.
- Linux, Windows, CI: you export `LANDBOT_API_TOKEN` in your own shell. The skills never write it to a file.
- The skills are instructed to refuse a token pasted into the chat and to tell you it is now in the conversation history.
- No server of ours ever sees it. There is no hosted component in this repo.

- `scripts/channel` can change a channel's web-chat version and Custom CSS with your token. It refuses any channel that is not the named bot's, and any channel older than 24 hours, with no override flag. It cannot tell who created a bot, so the skill's own rule, only bots it created in this session, is what keeps it off your existing bots. What it writes is live for visitors at once, so the skill includes it in the one yes it asks before building a bot for you, and never runs it on a bot you already had.

To report a security issue in this repo, open a GitHub issue titled "security" without details, or write to security@landbot.io. Please do not include a token in the report.
