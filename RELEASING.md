# Releasing

How a version of the `landbot` plugin gets from this repo to the people who install it, and what each marketplace does with it once it is here. The rules for *when* to bump and by how much are in `CONTRIBUTING.md`, under Versions; this is the mechanics.

## One version, one place

`plugins/landbot/.claude-plugin/plugin.json` declares the version; the marketplace entry does not. Twelve other places repeat it (the first line each skill prints, the user agent, the Custom JS module markers, the docs). `smoke/versions.sh` checks every copy on every pull request, and `scripts/version` rewrites them:

```bash
scripts/version              # print it
scripts/version check        # what CI runs
scripts/version bump 0.3.5   # rewrite every copy, then check
```

## Cut a release

1. On a branch: `scripts/version bump X.Y.Z` (the size of the bump follows the table in `CONTRIBUTING.md`), then move the `[Unreleased]` entries of `CHANGELOG.md` under a new `## [X.Y.Z] - YYYY-MM-DD` heading, written for the people who install the plugin: it becomes the release notes verbatim.
2. Open the pull request with a Conventional Commits title, get the review, squash-merge. `main` only moves this way: signed commits, one code-owner approval, the `manifests`, `versions and guards`, `title` and `version bump` checks green.
3. Publish, either way:
   - **Actions › release › Run workflow** on `main`. It tags the head of `main` as `vX.Y.Z`, where `X.Y.Z` is what `plugin.json` says, and carries on.
   - Or tag it yourself: `git tag -a vX.Y.Z -m "landbot X.Y.Z" <merge commit> && git push origin vX.Y.Z`.

The `release` workflow then, in order: runs the same checks as a pull request; refuses a tag whose version is not the one in `plugin.json`, or whose commit is not on `main`; takes the release notes from `CHANGELOG.md` and fails when the section is missing; installs the plugin from the tagged tree with `claude plugin install` and checks the version, the scripts' executable bits and `lb --version`; publishes the GitHub Release. Re-running it is safe: a tag or release that already exists is left alone.

A release candidate is a `vX.Y.Z-rcN` tag pushed by hand on the commit that carries `X.Y.Z`; people test it by adding the marketplace at that ref (`landbot-org/landbot-ai-skills#v0.3.5-rc1`). The `release` workflow ignores those tags. `landbot--vX.Y.Z` tags only appear if this repo ever holds a second plugin.

## Where it goes from here

| Marketplace | How it follows this repo | When a user sees a new version |
|---|---|---|
| **This repo as a marketplace** (`claude plugin marketplace add landbot-org/landbot-ai-skills`) | Reads `main` directly. | `claude plugin update landbot@landbot-skills` installs it as soon as the version in `plugin.json` changed on `main`. Auto-update is off by default for third-party marketplaces. |
| **Anthropic community catalog** (`anthropics/claude-plugins-community`, installed as `landbot@claude-community`, shown on claude.com/plugins as *Community*) | The entry pins one commit. A nightly job (07:23 UTC) moves the pin to the head of `main`, after validating the tree at the new commit with `claude plugin validate`, and opens one pull request per plugin that an Anthropic maintainer merges. Pull requests against the catalog are closed automatically. An entry that fails validation at head goes into the catalog's `.github/freeze-shas.txt` and stops moving. | One to a few days after the commit reaches `main`. |
| **Anthropic official catalog** (`anthropics/claude-plugins-official`, *Anthropic verified*, partner listing only) | Same nightly bump, plus a Claude policy review at the new commit; a failing review reverts that entry's bump. Plugins named in the catalog's `.github/bump-tracking.json` under `releases-only` move to the commit of the **latest published GitHub Release** instead of the head of `main`. | Same as above; under `releases-only`, only a release moves it, which is why the `release` workflow publishes one. |
| **Codex** | Reads `.claude-plugin/marketplace.json` from this repo as a legacy marketplace (`codex plugin marketplace add landbot-org/landbot-ai-skills`, then `codex plugin marketplace upgrade`). The ChatGPT/Codex plugin directory is separate: submissions at platform.openai.com/plugins, and each change is a new version, review and publication. | On `upgrade`; in the directory, after each review. |
| **Cursor** | `cursor.com/marketplace/publish` takes a public repo with a root `plugin.json` (the portable Agent Plugins manifest, which Codex prefers too) and a README; `.cursor-plugin/marketplace.json` lists a multi-plugin repo. Neither file exists here yet: adding them is a change under `plugins/`, so it is its own pull request with its own version bump. How Cursor refreshes a listing afterwards is not documented. | Not documented. |

Two consequences for how we work:

- **`main` is what the catalogs ship.** Do not merge a version bump you are not ready to see installed; anything experimental stays on a branch or a release-candidate tag, which only this repo's own marketplace serves.
- **Ask the Anthropic partner contact to put `landbot` under `releases-only`** in the official catalog's `bump-tracking.json` once it is listed. Then the GitHub Release is the publish act, and a commit on `main` is not.

## Watching the catalogs

`catalog-watch` runs daily after Anthropic's bump and writes a summary: for each catalog, whether `landbot` is listed, the pinned commit, what it tracks (`main` or the latest release), and how many days it is behind. When a catalog is behind by more than three days or frozen, it opens the issue *Catalog pin needs attention* and comments on it until the pin is current, then closes it. The same report by hand:

```bash
scripts/catalog-status          # exit 3 when a catalog is behind
scripts/catalog-status --json
```

If a catalog stays behind: check that `claude plugin validate --strict plugins/landbot` passes at the head of `main` (a failure there is what freezes an entry), then open an issue in the catalog repo titled *Manual bump request: landbot*, as other maintainers do. For the official catalog, the bump pull request's comments carry the policy verdict when a bump was reverted.

## Passing Anthropic's policy review

The review reads the whole repo, not only the loaded skills, and fails a plugin for any of: reading a credential of one service and sending it to another; an outbound call to a host other than the plugin's own service that the plugin description or README does not disclose together with an opt-out; hooks that observe every session; a description that would surprise a user given what the plugin actually accesses. The prompt is public, in the official catalog's `.github/policy/prompt.md`.

`policy-preflight` runs that prompt on this tree with a headless Claude and fails when the verdict does not pass. It runs on pull requests that touch the plugin and by hand from Actions, and needs the `ANTHROPIC_API_KEY` repository secret; without it the job says so and does nothing. Run it by hand before the first submission and before any release that changes what the scripts read or send.

## What the pipeline relies on

- The `main` ruleset: pull requests only, one code-owner approval, signed commits, squash merges, the four required checks. Tags are not covered by it, so the `release` workflow can push `vX.Y.Z` with the default token.
- GitHub Actions is not allowed to open pull requests in this repo, so the version bump is a pull request a person opens; everything after the merge is the workflow's.
- `@anthropic-ai/claude-code` is pinned in each workflow (`CLAUDE_CODE_VERSION`); bump it deliberately, the catalogs validate with the latest.
- Actions are pinned to commit SHAs and Dependabot proposes updates weekly.
