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
- CI runs `claude plugin validate --strict` on both manifests, then `smoke/versions.sh` and `smoke/guards.sh`, on every pull request and on `main`. All of it must be green before merge. `smoke/weekly.sh` needs a token and stays out of CI. To run the same checks locally: `claude plugin validate --strict . && claude plugin validate --strict plugins/landbot && smoke/versions.sh && smoke/guards.sh`.

## Changes to `main`

`main` only changes through a pull request, for everyone including admins:

- One approval from a code owner (`.github/CODEOWNERS`). A new push dismisses earlier approvals, and every review thread must be resolved.
- The `manifests` and `versions and guards` checks must pass on a branch that is up to date with `main`.
- Squash merge only, linear history, signed commits. No force push and no deleting the branch.

GitHub Actions only runs actions pinned to a full commit SHA, with the version as a comment (`uses: actions/checkout@<sha> # v7.0.1`). Dependabot opens a pull request each week when a newer version is out; review it like any other change.

Security problems go through **Security and quality › Report a vulnerability**, never a public issue; see `SECURITY.md`.
