# Changelog

Every version of the `landbot` plugin, newest first. The version is the one in `plugins/landbot/.claude-plugin/plugin.json`; the release workflow publishes a version's section here as the notes of its GitHub Release, so write each entry for the people who install the plugin.

## [Unreleased]

## [0.3.4] - 2026-09-24

- Live build in the Claude desktop app's in-app browser: the flow is published part by part and walked in the side pane as it grows.
- Every publish is checked first: `lb` refuses to publish a draft with violations, no greeting, a dangling connection, a placeholder question, or a draft that changed since the plugin last wrote it.
- Display-copy guard: a write whose `richText` disagrees with its `text` is refused before it is sent.
- Custom JS modules for `landbot-style`: a messaging-app behaviour and a step-form behaviour, pushed to the channel only as shipped and only with a yes.

## [0.3.3] - 2026-09-22

- Date picker guard: `format` and `pickerFormat` must agree or the write is refused.
- The published bot is walked in the browser; trigger wording of both skills tightened.
- Create once: a second `POST /bots` with the same name within 15 minutes is refused. Bot names capped at 50 characters. The channel is found from the bot, never typed. The 24 h channel-age guard is fixed and cannot be raised.

## [0.3.1] - 2026-09-20

- One yes before building, bound to the bot it creates; a no builds nothing.
- "Just show me" builds the default lead-qualification bot without an interview.
- `setup-token` opens the token page on macOS.

## [0.3.0] - 2026-09-19

- First release: one plugin, two skills (`landbot-flows`, `landbot-style`), for Claude Code, the Claude desktop app, Codex and Cursor.
