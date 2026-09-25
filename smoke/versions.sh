#!/usr/bin/env bash
# plugin.json holds the plugin version; marketplace.json must not declare one (Claude Code and Codex
# both read it from plugin.json). Every other place the repo states it must carry the same value:
# each SKILL.md (metadata and the first line it tells the user to print), the VERSION that
# scripts/lb sends in its user agent, the header of each ready-made module, and the docs that quote
# it. Exits 1 when any of them disagrees or is missing.
set -uo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
P="$HERE/plugins/landbot"
p="$(jq -r .version "$P/.claude-plugin/plugin.json")"
V='[0-9]+\.[0-9]+\.[0-9]+'
rc=0
# check <file> <extended regex with one ($V) group>: the first match must carry $p
check() {
  local file="$1" re="$2" v
  v="$(grep -m1 -oE "$re" "$HERE/$file" | grep -oE "$V" | tail -1)"
  if [ -z "$v" ]; then echo "$file: no version found for /$re/"; rc=1
  elif [ "$v" != "$p" ]; then echo "$file says $v, plugin.json says $p"; rc=1; fi
}
jq -e '[.plugins[] | has("version")] | any | not' "$HERE/.claude-plugin/marketplace.json" >/dev/null \
  || { echo ".claude-plugin/marketplace.json declares a version; plugin.json is the only place for it"; rc=1; }
for s in landbot-flows landbot-style; do
  check "plugins/landbot/skills/$s/SKILL.md" "^  version: $V"
  check "plugins/landbot/skills/$s/SKILL.md" "\`$s $V\`"
done
check plugins/landbot/skills/landbot-flows/scripts/lb "^VERSION=\"$V\""
for f in "$P"/skills/landbot-style/modules/*.js "$P"/skills/landbot-style/modules/*.css; do
  n="$(basename "$f")"; n="${n%.*}"
  check "${f#"$HERE/"}" "lb-js( companion)?: $n $V"
done
check README.md "\`landbot-flows $V\`"
check skills.md "\`landbot-flows $V\`"
check SECURITY.md "landbot-plugin/$V"
[ "$rc" = 0 ] && echo "versions agree: $p"
exit "$rc"
