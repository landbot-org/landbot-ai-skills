# Security

**The Landbot API token cannot be rotated from the app.** Treat it like a password you cannot change.

How these skills handle it:

- macOS: `scripts/setup-token` reads it from the clipboard, verifies it with one `GET /blocks`, stores it in the login keychain under `landbot-api-token`, clears the clipboard. `scripts/lb` reads it back and hands it to `curl` over stdin, so it never appears in a process list, a shell history line or a transcript.
- Linux, Windows, CI: you export `LANDBOT_API_TOKEN` in your own shell. The skills never write it to a file.
- The skills are instructed to refuse a token pasted into the chat and to tell you it is now in the conversation history.
- No server of ours ever sees it. There is no hosted component in this repo.

- Every API request from `lb` carries a user agent such as `landbot-plugin/0.4.0 (landbot-flows; agent=claude-code)`: the plugin version and which coding agent ran it, so Landbot can count plugin use and failures per version. No user, machine or content data is added.
- `scripts/channel` can change a channel's web-chat version, Custom CSS and Custom JS with your token. It finds the channel from the bot you name and writes nothing else. On a bot the plugin created on this machine in the last 6 hours (recorded locally when it was created) a write is live for visitors at once, so the skill includes it in the one yes it asks before building. On any other bot, including every bot you already had and the plugin's own bots after those 6 hours, it writes only the bot's draft: visitors see nothing until you press Publish in the builder, whose Preview shows the draft. No flag or environment variable turns a draft write into a live one. It refuses to write over unpublished changes someone made in the builder. The local record is a convenience, not a security boundary: anything that can write files on your machine can create one, which is why every write still asks for your yes.

To report a security issue in this repo, use **Security and quality › Report a vulnerability** on GitHub (https://github.com/landbot-org/landbot-ai-skills/security/advisories/new): the report is private and only the maintainers see it. You can also write to security@landbot.io. Do not open a public issue for a security problem, and do not include a token in the report.
