#!/usr/bin/env bash
# Offline tests for the marker and host checks in landbot-style/scripts/verify-share, and for the ready-made
# behaviour modules. No network, no sign-in. Exits 1 on any failure.
set -u
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
pass=0; fail=0

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

echo "guards: $pass passed, $fail failed"
[ "$fail" = 0 ]
