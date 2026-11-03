# OpenAI plugin directory

`scripts/build-openai-package` builds the ZIP that OpenAI's plugin directory, shared by ChatGPT and Codex, takes at <https://platform.openai.com/plugins> (**Upload new or existing plugin**). It uses the Agent Plugins layout:

| In the ZIP | From |
| --- | --- |
| `plugin.json` | `openai/plugin.json`, with the version of `plugins/landbot/.claude-plugin/plugin.json` |
| `mcp.json` | `openai/mcp.json` |
| `skills/` | `plugins/landbot/skills/`, tracked files only |
| `assets/icon.svg` | `plugins/landbot/.claude-plugin/icon.svg` |

`openai/plugin.json` holds the directory listing (`extensions["com.openai"].interface`), the review test cases and the release notes. `openai/mcp.json` declares the Landbot MCP server with OAuth through a Client ID Metadata Document: ChatGPT registers itself, so there is no client id or secret. OpenAI's pages put that `auth` object inside the server entry, which the Agent Plugins 1.0.0 schema does not allow; the portal reads it there.

Entered in the dashboard, not in the ZIP:

- **The reviewer account.** A Landbot account that signs in with email and password, with no MFA, on a plan that serves Custom CSS, and that does not expire. It needs a web bot named `Demo lead form`, on the current builder and the v4 web chat: three of the positive test cases use it.
- **The demo video** (`review.demo_recording_url`), unless it is added to `openai/plugin.json` before building.
- **Domain verification.** The portal gives a token to serve as plain text at `https://mcp.landbot.io/.well-known/openai-apps-challenge`.

Each upload needs a higher version than the last one, so build from a released version of the plugin. Once the plugin is published, OpenAI rescans the MCP server daily and tool changes go live without a new upload. A change to the listing, the icon or the skills needs a new ZIP and another review.
