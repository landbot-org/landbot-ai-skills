# Contributing

One plugin, `plugins/landbot/`, holds every skill: one folder each under `plugins/landbot/skills/<name>/` with a `SKILL.md`, an optional `REFERENCE.md`, `scripts/` (bash, `curl` and `jq` only) and `agents/openai.yaml` for Codex. The plugin manifest is `plugins/landbot/.claude-plugin/plugin.json`; the marketplace index is `.claude-plugin/marketplace.json` (Codex reads the same file). Bump the version in three places together: `plugin.json`, `marketplace.json`, and the "First line" of each `SKILL.md`; `smoke/versions.sh` checks they agree.

Rules:

- **No token, ever.** No fixture, test, log line or example may contain a real or partial Landbot token. `scripts/lb` is the only thing that reads it, and it passes it to `curl` over stdin.
- **No bundled schema.** The skills read `GET /openapi.yml` and `GET /blocks` at run time. Do not paste the contract into a skill.
- **Every claim in a REFERENCE.md says when and where it was observed.** Anything observed on production gets a date. Stale is fine; unlabelled is not.
- **Scripts never print more than they must**, exit non-zero from HTTP 400 up, and write `HTTP <code>` to stderr so a failure cannot be read as a success.
- Keep `SKILL.md` under about 400 lines. Move long learnings to `REFERENCE.md`.
- Paths in a `SKILL.md` are written as `${CLAUDE_SKILL_DIR}/scripts/…` (and `${CLAUDE_PLUGIN_ROOT}/skills/…` across skills). Claude Code substitutes them; `scripts/install.sh` writes absolute folders for Codex and Cursor. Never hard-code a home folder.
- `allowed-tools` pre-approves reads only (`lb GET`, `setup-token --whoami|--check`, `handoff`, `channel get`, `verify-share`). Anything that writes to a bot or channel must keep prompting.
- Test on a brand that is not a customer's before opening a pull request, and say in the PR which environment you tested against.
