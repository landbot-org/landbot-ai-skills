# Working in this repository

This repository is a plugin marketplace for Claude Code and Codex. It has one plugin, `plugins/landbot/`, with two skills, `landbot-flows` and `landbot-style`. The full rules are in `CONTRIBUTING.md`; this file lists what a coding agent must do to get a change merged, and what the repository refuses.

## Changing `main`

- `main` only changes through a pull request. Create a branch; a direct push to `main` is refused, for admins too.
- A pull request needs one approval from a code owner and these checks green on a branch up to date with `main`: `manifests`, `versions and guards`, `title`, `version bump`.
- Commits on `main` must be signed. Merging is squash only; the pull request title becomes the commit.

## Pull request title

`<type>(<scope>)!: <summary>`, with `(<scope>)` and `!` optional.

- Types: `feat`, `fix`, `docs`, `ci`, `build`, `chore`, `refactor`, `test`.
- Scopes: `flows`, `style`, `deps`. No scope when the change touches the whole plugin or the repository.
- `!` marks an incompatible change.

`smoke/pr-title.sh "<title>"` checks a title locally.

## Version

- A change to any file under `plugins/` must raise the version in `plugins/landbot/.claude-plugin/plugin.json`. Claude Code and Codex only update people who already installed the plugin when that version changes.
- While on `0.x`: `feat` or `!` raises the minor; `fix` and any other type raise the patch. Changes outside `plugins/` do not bump. Moving to `1.0` is not decided by a change type.
- The same version is repeated in each `SKILL.md` (twice), `VERSION` in `plugins/landbot/skills/landbot-flows/scripts/lb`, the header of each file in `plugins/landbot/skills/landbot-style/modules/`, `README.md`, `skills.md` and `SECURITY.md`. Change all of them together. `marketplace.json` must not declare a version.
- `smoke/versions.sh` checks that they agree. `smoke/version-bump.sh origin/main` checks that the version went up.

## Tags

- Tags matching `v*` cannot be deleted or moved; creating one is allowed. Never try to fix a tag by moving it. Release the next version instead.
- `vX.Y.Z-rcN` tags are made by hand to test a release candidate.

## GitHub Actions

- Every `uses:` must be pinned to a full commit SHA, with the version as a comment (`uses: actions/checkout@<sha> # v7.0.1`). A tag reference fails, because the repository requires SHA pinning.
- Dependabot updates the pins weekly.

## Secrets

- Never write a Landbot API token, or any part of one, in code, tests, logs, commits, pull requests or issues. It cannot be rotated.
- Security problems go through GitHub's private vulnerability reporting, never a public issue. See `SECURITY.md`.

## Checks to run before pushing

```bash
claude plugin validate --strict . && claude plugin validate --strict plugins/landbot && smoke/versions.sh && smoke/guards.sh
```
