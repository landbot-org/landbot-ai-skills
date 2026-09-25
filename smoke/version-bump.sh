#!/usr/bin/env bash
# When a change touches plugins/, the version in plugin.json must be higher than on the base, or
# people who already installed the plugin never receive it (Claude Code and Codex only reinstall
# when that version changes).
#
#   smoke/version-bump.sh origin/main
#
# Compares the working tree's commit (HEAD) with its merge base with <base>. Exits 1 when plugins/
# changed and the version did not go up.
set -uo pipefail
base="${1:?usage: smoke/version-bump.sh <base-ref>}"
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$HERE"
M=plugins/landbot/.claude-plugin/plugin.json
mb="$(git merge-base "$base" HEAD)" || { echo "no merge base between $base and HEAD" >&2; exit 2; }
if git diff --quiet "$mb" HEAD -- plugins/; then
  echo "plugins/ unchanged: no bump needed"; exit 0
fi
old="$(git show "$mb:$M" | jq -r .version)"
new="$(jq -r .version "$M")"
if [ "$old" != "$new" ] && [ "$(printf '%s\n%s\n' "$old" "$new" | sort -V | tail -1)" = "$new" ]; then
  echo "plugins/ changed and the version went up: $old -> $new"
else
  echo "plugins/ changed but plugin.json is still $new (base has $old). Bump it as CONTRIBUTING.md, Versions, says." >&2
  exit 1
fi
