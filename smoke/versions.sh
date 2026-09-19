#!/usr/bin/env bash
# The plugin version must be the same in plugin.json, marketplace.json and the first line each
# SKILL.md tells the user to print. Exits 1 when they disagree.
set -uo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
p="$(jq -r .version "$HERE/plugins/landbot/.claude-plugin/plugin.json")"
m="$(jq -r '.plugins[0].version' "$HERE/.claude-plugin/marketplace.json")"
rc=0
[ "$p" = "$m" ] || { echo "plugin.json $p != marketplace.json $m"; rc=1; }
for s in landbot-flows landbot-style; do
  v="$(grep -m1 -oE "$s [0-9]+\.[0-9]+\.[0-9]+" "$HERE/plugins/landbot/skills/$s/SKILL.md" | awk '{print $2}')"
  [ "$v" = "$p" ] || { echo "$s/SKILL.md says $v, plugin.json says $p"; rc=1; }
done
[ "$rc" = 0 ] && echo "versions agree: $p"
exit "$rc"
