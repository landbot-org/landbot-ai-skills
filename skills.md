# Landbot AI skills: setup instructions for coding agents

You are a coding agent (Claude Code, the Claude desktop app, Codex or Cursor) and a person asked you to set up the Landbot skills. Follow these steps in order. Steps marked **HUMAN** are done by the person: say what you need, then stop and wait.

**Best place to run this: the Claude desktop app, Code tab.** There you can show the chat in a browser pane beside the conversation, and walk every branch of the published bot yourself. In a terminal, Codex or Cursor everything works the same, except that the person walks the finished chat instead.

Rules that hold for the whole session:
- Everything goes through the Landbot MCP server, `https://mcp.landbot.io/mcp`. Never ask for a Landbot API token and never call Landbot's HTTP API yourself.
- Build and style a bot you create before anything is live, then ask once before publishing it. For a bot the person already had, say which bot and get a yes before every change.

## 1. HUMAN: create a Landbot account
https://app.landbot.io/signup_intent/?utm_source=skills_md (free). Email verification is theirs to do.

## 2. Install the `landbot` plugin
Run these yourself through your shell; no restart is needed (see the note at the end of this step).

Claude Code:
```bash
claude plugin marketplace add landbot-org/landbot-ai-skills
claude plugin install landbot@landbot-skills
```
If your shell cannot run `claude` (`claude --version` not found; common in the desktop app when Claude Code was never installed separately), the person types these in the chat box instead: `/plugin marketplace add landbot-org/landbot-ai-skills` then `/plugin install landbot@landbot-skills`, or uses the no-terminal path below. The plugin connects the Landbot MCP server itself.

Codex:
```bash
codex plugin marketplace add landbot-org/landbot-ai-skills
codex plugin add landbot@landbot-skills
codex mcp add landbot --url https://mcp.landbot.io/mcp
```
Or, on any Codex version: `git clone https://github.com/landbot-org/landbot-ai-skills && landbot-ai-skills/scripts/install.sh codex`, then the `codex mcp add` line above.

Cursor (from the project root; add `--global` for all projects):
```bash
git clone https://github.com/landbot-org/landbot-ai-skills && landbot-ai-skills/scripts/install.sh cursor
```
Then **HUMAN** adds `https://mcp.landbot.io/mcp` as a remote MCP server in Cursor's MCP settings.

**No terminal (Claude desktop app):** the person opens **Customize › Plugins › Add marketplace**, pastes `landbot-org/landbot-ai-skills`, installs **landbot**, then starts a new session **in the Code tab** (Cowork runs the plugin too, but not tested end to end, and it has no browser pane).

After installing, check the skill answers with `landbot 0.10.1` as its first line. An older number, or `landbot-flows`, means a stale copy is also installed; remove it before going on. **The skill loads in a new session.** If you installed it inside this running session, you cannot load it yourself: ask the person to type `/reload-plugins` in the chat box, or to start a new session. **If they start a new session, give them the rest of their request to paste there** (for example the "Then build: …" line of the prompt they gave you), because a new session does not see this one.

## 3. HUMAN: sign in
The first Landbot tool call opens Landbot's sign-in in the browser (Codex: `codex mcp login landbot`). The person signs in and allows access. If they are asked again later for more access, that is a new kind of change the server needs their permission for; let them answer it.

## 4. Build the first bot
Use the `landbot` skill with the person's description, and read the server's build guide (`get_guide` with topic `build`) before the first write. **If they asked for a bot but gave no description, or said "show me", do not interview them:** the build guide says which bot to build.

When they described a look, it goes on before the first publish, as the style guide says (`get_guide` with topic `style`). Then hand the bot back and ask once to publish it, as the hand-back guide says (`get_guide` with topic `hand-back`): the builder link and the note that goes with it (the builder is for looking; changes go through you), the share URL, and a plain-language description of the conversation. With the in-app browser, walk every branch after the publish. On a Sandbox or Trial plan the share URL first shows Landbot's safety notice ("You’re about to open a chat with …"): it is not an error. Click "Continue to chat", never "Report this bot".

## 5. Embed
Offer to add the embed snippet (builder › Share › Embed) to their site's code. **HUMAN** deploys.

## Limits
On the v4 web chat use `buttons` for yes/no. Custom CSS and Custom JS (the messaging and step-form behaviours) work on every plan; on Sandbox and Trial, Custom JS needs the v4 web chat, and the chat works without it. On Sandbox and Trial, visitors, and you when you try the bot, first see a Landbot safety notice on the share URL: "Continue to chat" passes it, and upgrading the plan removes it.

Help: open an issue at https://github.com/landbot-org/landbot-ai-skills (bot id and step) or use the assistant on the skills page.
