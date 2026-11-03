#!/usr/bin/env bash
# Copy the skill into a coding agent that reads SKILL.md folders directly.
#
#   scripts/install.sh codex              → ${CODEX_HOME:-$HOME/.codex}/skills/   (Codex also reads this repo as a plugin marketplace; see README)
#   scripts/install.sh cursor             → ./.cursor/skills/   (run from your project root)
#   scripts/install.sh cursor --global    → ~/.cursor/skills/
#   scripts/install.sh claude-user        → ~/.claude/skills/   (Claude Code without the plugin system)
#
# Claude Code users do not need this: use the plugin marketplace (see README.md).
# What it does besides copying: removes landbot-flows and landbot-style, the two skills it copied before 0.10.0.
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
for old in landbot-flows landbot-style; do
  if [ -d "$DEST/$old" ]; then
    rm -rf "$DEST/$old"
    echo "removed $old $DEST/$old (the landbot skill replaces it)"
  fi
done
if [ -d "$DEST/landbot" ]; then
  rm -rf "$DEST/landbot"
  echo "replaced $DEST/landbot (a folder of that name was already there)"
fi
cp -R "$HERE/plugins/landbot/skills/landbot" "$DEST/landbot"
echo "installed landbot $DEST/landbot (version $(grep -m1 -oE 'landbot [0-9]+\.[0-9]+\.[0-9]+' "$DEST/landbot/SKILL.md" | cut -d' ' -f2))"
echo
echo "Next: connect the Landbot MCP server, https://mcp.landbot.io/mcp, in your agent and sign in."
echo "  Codex: codex mcp add landbot --url https://mcp.landbot.io/mcp && codex mcp login landbot"
