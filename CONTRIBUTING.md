# Contributing

One plugin, `plugins/landbot/`, holds every skill: one folder each under `plugins/landbot/skills/<name>/` with a `SKILL.md`, an optional `REFERENCE.md`, `scripts/` (bash, `curl` and `jq` only) and `agents/openai.yaml` for Codex. The plugin manifest is `plugins/landbot/.claude-plugin/plugin.json`; the marketplace index is `.claude-plugin/marketplace.json` (Codex reads the same file). How the version is set and bumped is under [Versions](#versions).

Rules:

- **No token, ever.** No fixture, test, log line or example may contain a real or partial Landbot token. `scripts/lb` is the only thing that reads it, and it passes it to `curl` over stdin.
- **No bundled schema.** The skills read `GET /openapi.yml` and `GET /blocks` at run time. Do not paste the contract into a skill.
- **Every claim in a REFERENCE.md says when and where it was observed.** Anything observed on production gets a date. Stale is fine; unlabelled is not.
- **Scripts never print more than they must**, exit non-zero from HTTP 400 up, and write `HTTP <code>` to stderr so a failure cannot be read as a success.
- Keep `SKILL.md` under about 400 lines. Move long learnings to `REFERENCE.md`.
- Paths in a `SKILL.md` are written as `${CLAUDE_SKILL_DIR}/scripts/…` (and `${CLAUDE_PLUGIN_ROOT}/skills/…` across skills). Claude Code substitutes them; `scripts/install.sh` writes absolute folders for Codex and Cursor. Never hard-code a home folder.
- `allowed-tools` pre-approves reads only (`lb GET`, `setup-token --whoami|--check`, `handoff`, `channel get`, `verify-share`). Anything that writes to a bot or channel must keep prompting.
- Test on a brand that is not a customer's before opening a pull request, and say in the PR which environment you tested against.
- CI runs `claude plugin validate --strict` on both manifests, then `smoke/versions.sh` and `smoke/guards.sh`, on every pull request and on `main`. On every pull request it also runs `smoke/pr-title.sh` on the title and `smoke/version-bump.sh` against `main`. All of it must be green before merge. `smoke/weekly.sh` needs a token and stays out of CI. To run the same checks locally: `claude plugin validate --strict . && claude plugin validate --strict plugins/landbot && smoke/versions.sh && smoke/guards.sh`.

## Versions

The plugin is the unit that Claude Code and Codex install and update, so it carries one version for both skills. `plugins/landbot/.claude-plugin/plugin.json` is the only place that declares it; the entry in `marketplace.json` has no `version`. Both agents give a person who already installed the plugin a new copy only when that version changes, so a change under `plugins/` that people should receive needs a bump.

The same value is repeated, and must match, in:

- each `SKILL.md`: `metadata.version` and the "First line" it tells the agent to print;
- `VERSION` in `plugins/landbot/skills/landbot-flows/scripts/lb`, sent in the user agent;
- the header comment of each file in `plugins/landbot/skills/landbot-style/modules/`;
- the version quoted in `README.md`, `skills.md` and `SECURITY.md`.

`smoke/versions.sh` checks all of them.

The plugin stays on `0.x`. Moving to `1.0` is a decision of its own, not the result of a change type. While on `0.x`:

| Change | Bump | Example |
|---|---|---|
| New behaviour (`feat`) | minor | `0.3.4` → `0.4.0` |
| Fix (`fix`) | patch | `0.3.4` → `0.3.5` |
| Incompatible change (`!` after the type) | minor | `0.3.4` → `0.4.0` |
| Any other type (`refactor`, `chore`, `build`, `docs`, `test`) that changes a file under `plugins/` | patch | `0.3.4` → `0.3.5` |

Changes outside `plugins/`, such as docs or CI, do not bump the version. `smoke/version-bump.sh` fails a pull request that changes `plugins/` without raising the version.

Pull request titles follow [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>)!: <summary>`, with `(<scope>)` and `!` optional. Types: `feat`, `fix`, `docs`, `ci`, `build`, `chore`, `refactor`, `test`. Scopes: `flows` and `style` for a change to one skill, `deps` for dependency updates; no scope when a change touches the whole plugin or the repository. The title becomes the commit on `main`, and `smoke/pr-title.sh` checks it.

When a push to `main` carries a version that has no tag yet, the `release` workflow runs `scripts/release.sh`: it tags `vX.Y.Z` on that commit and publishes its GitHub Release. The notes list the commit titles since the previous release, grouped into breaking changes, features, fixes and other changes; the [Releases](https://github.com/landbot-org/landbot-ai-skills/releases) page is the changelog. Do not create `vX.Y.Z` tags or releases by hand. `scripts/release.sh --dry-run` prints the tag and the notes for `HEAD` without changing anything. `vX.Y.Z-rcN` tags are made by hand for testing a candidate; a person can install one by adding the marketplace at that ref (`landbot-org/landbot-ai-skills#v0.3.5-rc1` in Claude Code).

Tags matching `v*` cannot be deleted or moved to another commit; the `release tags` ruleset refuses both, for admins too. Anyone with write access can create one. A tag that points at the wrong commit is not fixed by moving it: release the next version instead. To remove a tag created by mistake, a repository admin sets the `release tags` ruleset (Settings › Rulesets) to *Disabled*, deletes the tag, and sets the ruleset back to *Active*.

With a second plugin in this repository, each plugin keeps its own version in its own `plugin.json`, tags become `<plugin>--vX.Y.Z`, and the scope is the plugin name.

## Changes to `main`

`main` only changes through a pull request, for everyone including admins:

- One approval from a code owner (`.github/CODEOWNERS`). A new push dismisses earlier approvals, and every review thread must be resolved.
- The `manifests`, `versions and guards`, `title` and `version bump` checks must pass on a branch that is up to date with `main`.
- Squash merge only, linear history, signed commits. No force push and no deleting the branch.

GitHub Actions only runs actions pinned to a full commit SHA, with the version as a comment (`uses: actions/checkout@<sha> # v7.0.1`). Dependabot opens a pull request each week when a newer version is out; review it like any other change.

Security problems go through **Security and quality › Report a vulnerability**, never a public issue; see `SECURITY.md`.
