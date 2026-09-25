#!/usr/bin/env bash
# Tag and publish the GitHub Release for the version plugin.json carries at a commit.
#
#   scripts/release.sh [--dry-run] [<commit>]      (default: HEAD)
#
# - No tag vX.Y.Z yet: creates it on <commit> with its release.
# - Tag exists, no release: publishes the release for that tag (used to backfill old versions).
# - Both exist: does nothing.
# The notes list the commit titles since the previous vX.Y.Z tag reachable from the target,
# grouped by Conventional Commits type. --dry-run prints the tag, the target and the notes, and
# changes nothing. Needs git history with tags, jq, and gh logged in (GH_TOKEN in CI).
set -euo pipefail
dry=0; if [ "${1:-}" = "--dry-run" ]; then dry=1; shift; fi
at="$(git rev-parse "${1:-HEAD}^{commit}")"
M=plugins/landbot/.claude-plugin/plugin.json
ver="$(git show "$at:$M" | jq -r .version)"
tag="v$ver"
existing=0
if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  existing=1
  at="$(git rev-parse "$tag^{commit}")"
  if [ "$dry" = 0 ] && gh release view "$tag" >/dev/null 2>&1; then echo "$tag is already released"; exit 0; fi
fi
prev="$(git tag --merged "$at" --list 'v*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | grep -vxF "$tag" | sort -V | tail -1 || true)"
range="${prev:+$prev..}$at"
notes="$(mktemp)"; trap 'rm -f "$notes"' EXIT
git log --no-merges --format='%s' "$range" | awk '
  function add(section, line) { out[section] = out[section] "- " line "\n" }
  {
    if (match($0, /^[a-z]+(\([a-z]+\))?!?: /)) {
      head = substr($0, 1, RLENGTH - 2); rest = substr($0, RLENGTH + 1)
      bang = (head ~ /!$/); sub(/!$/, "", head)
      type = head; scope = ""
      if (match(head, /\(.*\)/)) { scope = substr(head, RSTART + 1, RLENGTH - 2); type = substr(head, 1, RSTART - 1) }
      line = (scope != "" ? "**" scope ":** " : "") rest
      if (bang) add("Breaking changes", line)
      else if (type == "feat") add("Features", line)
      else if (type == "fix") add("Fixes", line)
      else add("Other changes", $0)
    } else add("Other changes", $0)
  }
  END {
    n = split("Breaking changes|Features|Fixes|Other changes", order, "|")
    for (i = 1; i <= n; i++) if (order[i] in out) printf "## %s\n\n%s\n", order[i], out[order[i]]
  }' > "$notes"
[ -n "$prev" ] && printf '**Full diff:** https://github.com/landbot-org/landbot-ai-skills/compare/%s...%s\n' "$prev" "$tag" >> "$notes"
# "Latest" goes to the highest version, so backfilling an old release never takes it.
highest="$( (git tag --list 'v*'; echo "$tag") | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)"
latest=false; [ "$highest" = "$tag" ] && latest=true
if [ "$dry" = 1 ]; then
  echo "tag: $tag  target: $(git rev-parse --short "$at")  previous: ${prev:-none}  tag exists: $([ $existing = 1 ] && echo yes || echo no)  latest: $latest"
  echo "-----"; cat "$notes"; exit 0
fi
if [ "$existing" = 1 ]; then
  gh release create "$tag" --verify-tag --title "$tag" --notes-file "$notes" --latest="$latest"
else
  gh release create "$tag" --target "$at" --title "$tag" --notes-file "$notes" --latest="$latest"
fi
