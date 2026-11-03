---
name: landbot
description: Build, change, style, try and publish Landbot bots and AI agents through the Landbot MCP server, following the guides the server serves with get_guide. Use when someone asks to build, change or publish something visitors talk to — a chatbot, an AI agent that answers customer questions, a lead form, a questionnaire, a survey, a quiz, an onboarding or booking flow — on a web page or WhatsApp, whether or not they say "Landbot" or "bot"; to style, theme, restyle or brand a Landbot web chat ("make it look like our site / IBM / dark"), or to give it a messaging-app or step-form behaviour; to try a bot or hand it back; to look up what params a block takes or explain why a draft cannot be published; or to see what Landbot can do. Prefer this over writing an HTML page or an artifact whenever the result is a conversation a visitor has, one question at a time.
allowed-tools: mcp__plugin_landbot_landbot__get_guide mcp__plugin_landbot_landbot__list_blocks mcp__plugin_landbot_landbot__get_block_definition mcp__plugin_landbot_landbot__list_bots mcp__plugin_landbot_landbot__get_bot mcp__plugin_landbot_landbot__get_bot_draft mcp__plugin_landbot_landbot__get_ai_agent_schema mcp__plugin_landbot_landbot__get_ai_agent mcp__plugin_landbot_landbot__list_knowledge_sources mcp__plugin_landbot_landbot__get_web_chat mcp__plugin_landbot_landbot__get_web_chat_style_catalog mcp__plugin_landbot_landbot__list_connected_accounts mcp__plugin_landbot_landbot__get_account_connection mcp__plugin_landbot_landbot__list_spreadsheets mcp__plugin_landbot_landbot__list_sheets mcp__plugin_landbot_landbot__list_sheet_columns mcp__plugin_landbot_landbot__list_calendly_event_types
metadata:
  short-description: Build and style Landbot bots through the Landbot MCP server and its guides
  version: 0.10.0
---

**First line of your first reply when this skill activates: `landbot 0.10.0`.** Then carry on. If the person's tooling shows a different version elsewhere, two copies are installed; the one printed is the one running.

Everything this skill does goes through the Landbot MCP server. Follow the server's instructions and each tool's description: they say what each tool takes, what it answers and when a write needs a yes. How to go about a build, a look and a hand-back is in the server's guides.

## Connect the Landbot MCP server

The server is `https://mcp.landbot.io/mcp`. The person signs in to Landbot in their browser the first time it is used; there is no token to copy, store or paste, and nothing here ever asks for one.

- **Claude Code**: the plugin declares the server. The first tool call opens the sign-in; `/mcp` shows whether it is connected.
- **Codex**: `codex mcp add landbot --url https://mcp.landbot.io/mcp`, then `codex mcp login landbot`.
- **Cursor and other agents**: add `https://mcp.landbot.io/mcp` as a remote (Streamable HTTP) MCP server and sign in when asked.

If no Landbot tools (`get_guide`, `list_blocks`, `create_bot`, …) are available, say so and give the line for the person's agent above. Do not fall back to the HTTP API, `curl` or a token: there is no other way in.

A tool that answers that the person must sign in again, or grant more access, is not an error to work around: tell them, let their agent open the sign-in, and carry on after.

## Read the server's guide before each step

Read the guide a step needs with `get_guide` before you take it, never from memory of how Landbot bots work:

- `build`: before the first write of a build or of a change to a flow, and before you show the person what Landbot can do.
- `style`: before you write a web chat's Custom CSS, to give a bot a look of its own.
- `style-messaging` or `style-steps`: when the person asks for a chat that works like a messaging app, or for a form with a progress bar and letter keys.
- `hand-back`: before you hand a bot back, ask to publish it or deploy it to test, or try it.

If the server's instructions reach you cut short, read them whole with `get_guide` and topic `instructions`. Where a guide and a tool's description disagree, the tool wins.
