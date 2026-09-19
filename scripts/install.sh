#!/usr/bin/env bash
# Copy the two skills into a coding agent that reads SKILL.md folders directly.
#
#   scripts/install.sh codex              → ${CODEX_HOME:-$HOME/.codex}/skills/   (Codex also reads this repo as a plugin marketplace; see README)
#   scripts/install.sh cursor             → ./.cursor/skills/   (run from your project root)
#   scripts/install.sh cursor --global    → ~/.cursor/skills/
#   scripts/install.sh claude-user        → ~/.claude/skills/   (Claude Code without the plugin system)
#
# Claude Code users do not need this: use the plugin marketplace (see README.md).
# What it does besides copying: writes the absolute install folder into each SKILL.md where Claude Code
# would have substituted ${CLAUDE_SKILL_DIR} / ${CLAUDE_PLUGIN_ROOT}, so the commands run as written.
set -euo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-}"; FLAG="${2:-}"
case "$TARGET" in
codex) DEST="${CODEX_HOME:-$HOME/.codex}/skills" ;;
cursor) if [ "$FLAG" = "--global" ]; then DEST="$HOME/.cursor/skills"; else DEST="$PWD/.cursor/skills"; fi ;;
claude-user) DEST="$HOME/.claude/skills" ;;
*) echo "usage: scripts/install.sh codex | cursor [--global] | claude-user" >&2; exit 64 ;;
esac
mkdir -p "$DEST"
for s in landbot-flows landbot-style; do
  rm -rf "$DEST/$s"
  cp -R "$HERE/plugins/landbot/skills/$s" "$DEST/$s"
  chmod +x "$DEST/$s"/scripts/* 2>/dev/null || true
  # Claude Code substitutes these two placeholders itself; other agents get the absolute folders.
  # ${CLAUDE_PLUGIN_ROOT}/skills/<x> becomes <DEST>/<x>, because the two skills are siblings there too.
  python3 - "$DEST/$s/SKILL.md" "$DEST/$s" "$DEST" <<'PY' 2>/dev/null || sed -i.bak -e "s|\${CLAUDE_SKILL_DIR}|$DEST/$s|g" -e "s|\${CLAUDE_PLUGIN_ROOT}/skills|$DEST|g" "$DEST/$s/SKILL.md"
import sys, pathlib
f, skill, root = pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3]
t = f.read_text()
t = t.replace('${CLAUDE_SKILL_DIR}', skill).replace('${CLAUDE_PLUGIN_ROOT}/skills', root)
f.write_text(t)
PY
  rm -f "$DEST/$s/SKILL.md.bak"
  echo "installed $s $DEST/$s (version $(grep -m1 -oE 'landbot-[a-z]+ [0-9]+\.[0-9]+\.[0-9]+' "$DEST/$s/SKILL.md"))"
done
echo
echo "Next: copy your API token from https://app.landbot.io/gui/settings/account, then in your agent say:"
echo "  set up my Landbot token"
