#!/usr/bin/env bash
# Offline tests for the write guards in scripts/channel and the name guard in scripts/lb.
# No network, no token: channel runs against a fake lb + handoff in a temp dir. Exits 1 on any failure.
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$HERE/plugins/landbot/skills/landbot-flows/scripts"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
cp "$SRC/channel" "$T/"; cp "$SRC/lb" "$T/lb.real"
cat > "$T/lb" <<'E'
#!/usr/bin/env bash
M="$1"; P="$2"; B="${3:-}"; D="$(dirname "$0")"
cr=$(( $(date +%s) - ${MOCK_AGE_H:-1}*3600 ))
case "$M $P" in
"GET /bots/"*) echo "{\"data\":{\"id\":\"BOT\",\"channels\":${MOCK_CHANNELS:-[\"cu-1\"]}}}";;
"GET /channels/"*) id="${P#/channels/}"; id="${id%/}"; [ "$id" = "777" ] || exit 1
   ver=$(cat "$D/ver" 2>/dev/null || echo 3.0.0); sty=$(cat "$D/style" 2>/dev/null || true)
   c="$cr"; [ -n "${MOCK_NOCREATED:-}" ] && c=null
   jq -n --arg v "$ver" --arg s "$sty" --argjson c "$c" '{success:true,channel:{id:777,uuid:"cu-1",version:$v,style:$s,created_at:$c}}';;
"PATCH /channels/777/") printf '%s' "$B" | jq -c . >> "$D/patches"
   v=$(printf '%s' "$B" | jq -r '.version // empty'); [ -n "$v" ] && echo "$v" > "$D/ver"
   printf '%s' "$B" | jq -e 'has("style")' >/dev/null && printf '%s' "$B" | jq -j .style > "$D/style"; echo '{}';;
*) exit 1;;
esac
E
printf '#!/usr/bin/env bash\necho "LANDBOT_HANDOFF bot=$1 builder=4069913 share=x channel=${MOCK_RESOLVED:-777} version=3.0.0"\n' > "$T/handoff"
chmod +x "$T/lb" "$T/handoff" "$T/channel"; printf 'a{color:red}' > "$T/s.css"
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; rm -f "$T/patches" "$T/ver" "$T/style"; "$@" >/dev/null 2>&1; local rc=$?
  local np=0; [ -f "$T/patches" ] && np=$(wc -l < "$T/patches" | tr -d ' ')
  if [ "$rc:$np" = "$want" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $name: rc=$rc writes=$np, want $want"; fi; }
C="$T/channel"
t "uuid as channel id"        65:0 "$C" v4 ba59dd6c-uuid --bot BOT
t "write without --bot"       64:0 "$C" v4 777
t "bot with no channel"       70:0 env MOCK_CHANNELS='[]' "$C" v4 --bot BOT
t "bot with two channels"     70:0 env MOCK_CHANNELS='["a","b"]' "$C" css "$T/s.css" --bot BOT
t "bot number as channel id"  70:0 "$C" v4 4069913 --bot BOT
t "old channel, env raised (v4)"  70:0 env MOCK_AGE_H=48 LANDBOT_CHANNEL_MAX_AGE_H=99999 "$C" v4 --bot BOT
t "old channel, env raised (css)" 70:0 env MOCK_AGE_H=48 LANDBOT_CHANNEL_MAX_AGE_H=99999 "$C" css "$T/s.css" --bot BOT
t "exactly 24 h"              70:0 env MOCK_AGE_H=24 "$C" v4 --bot BOT
t "no created_at"             70:0 env MOCK_NOCREATED=1 "$C" v4 --bot BOT
t "channel not resolvable"     1:0 env MOCK_RESOLVED='?' "$C" v4 --bot BOT
t "v4"                         0:1 "$C" v4 --bot BOT
t "css"                        0:1 "$C" css "$T/s.css" --bot BOT
t "v4 <id> --bot (0.3.1 form)" 0:1 "$C" v4 777 --bot BOT
t "css <id> <file> --bot (0.3.1 form)" 0:1 "$C" css 777 "$T/s.css" --bot BOT
t "--id matching"              0:1 "$C" v4 --id 777 --bot BOT
t "get --bot"                  0:0 "$C" get --bot BOT
t "get <id>"                   0:0 "$C" get 777
t "get unknown id"             1:0 "$C" get 555
t "css unreadable file"       66:0 "$C" css /nonexistent.css --bot BOT
L="$T/lb.real"; export LANDBOT_API_TOKEN=dummy LANDBOT_API_URL=http://127.0.0.1:9
n50=$(printf 'x%.0s' $(seq 50)); n51=$(printf 'x%.0s' $(seq 51))
t "name 50 reaches the network" 1:0 "$L" POST /bots "{\"name\":\"$n50\"}"
t "name 51 refused locally"    65:0 "$L" POST /bots "{\"name\":\"$n51\"}"
printf '{"name":"%s"}' "$n51" > "$T/b.json"
t "name 51 in @file refused"   65:0 "$L" POST /bots "@$T/b.json"
t "50 accented chars pass"      1:0 "$L" POST /bots "{\"name\":\"$(printf 'é%.0s' $(seq 50))\"}"
t "rename not guarded"          1:0 "$L" PATCH /bots/x "{\"name\":\"$n51\"}"

# duplicate-create guard: a local server answers GET /bots with a bot of the same name created now
W="$T/www"; mkdir -p "$W"; now=$(date -u +%Y-%m-%dT%H:%M:%S)
printf '{"data":[{"id":"u-dup","name":"Dup test","created_at":"%s"}]}' "$now" > "$W/bots"
PORT=$(( 20000 + RANDOM % 20000 )); (cd "$W" && python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1) & SRV=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null "http://127.0.0.1:$PORT/bots" && break; sleep 0.3; done
export LANDBOT_API_URL="http://127.0.0.1:$PORT"
t "same name within 15 min refused" 65:0 "$L" POST /bots '{"name":"Dup test"}'
t "different name passes the guard" 1:0 "$L" POST /bots '{"name":"Other name"}'
kill "$SRV" 2>/dev/null; wait "$SRV" 2>/dev/null
ua="$(grep -c 'landbot-plugin/' "$SRC/lb")"; [ "$ua" -ge 1 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL user agent missing in lb"; }
echo "guards: $pass passed, $fail failed"
[ "$fail" = 0 ]
