#!/usr/bin/env bash
# Read-only smoke against the environment the token points at. Run weekly on a TEST brand.
# Exits non-zero when /blocks is not 200, or when the contract or the catalog changed since last run.
set -uo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LB="$HERE/../plugins/landbot/skills/landbot-flows/scripts/lb"
STATE="${SMOKE_STATE_DIR:-$HERE/.state}"; mkdir -p "$STATE"
rc=0
spec="$("$LB" GET /openapi.yml 2>/dev/null)" || { echo "FAIL openapi.yml"; rc=1; }
blocks="$("$LB" GET /blocks 2>/dev/null)" || { echo "FAIL /blocks (gate 1 closed, token wrong, or permission missing)"; rc=1; }
[ "$rc" = 0 ] || exit "$rc"
n="$(printf '%s' "$blocks" | jq '.data | length')"
names="$(printf '%s' "$blocks" | jq -r '.data[].name' | sort | tr '\n' ' ')"
h_spec="$(printf '%s' "$spec" | shasum -a 256 | cut -c1-12)"
h_cat="$(printf '%s' "$names" | shasum -a 256 | cut -c1-12)"
echo "$(date -u +%FT%TZ) blocks=$n spec=$h_spec catalog=$h_cat"
for k in spec cat; do
  f="$STATE/$k.sha"; v="$(eval echo \$h_$k)"
  if [ -f "$f" ] && [ "$(cat "$f")" != "$v" ]; then echo "CHANGED: $k ($(cat "$f") → $v). Re-read the contract before the next build."; rc=3; fi
  echo "$v" > "$f"
done
exit "$rc"
