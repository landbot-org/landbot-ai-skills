#!/usr/bin/env bash
# A pull request title must follow Conventional Commits with this repository's types and scopes
# (see CONTRIBUTING.md, Versions): <type>(<scope>)!: <summary>, scope and ! optional.
#
#   smoke/pr-title.sh "feat(flows): ask for the channel once"
#
# Exits 1 when the title does not match.
set -uo pipefail
title="${1-}"
re='^(feat|fix|docs|ci|build|chore|refactor|test)(\((flows|style|deps)\))?!?: [^[:space:]].*$'
if printf '%s' "$title" | grep -qE "$re"; then
  echo "title ok: $title"
else
  echo "title does not follow <type>(<scope>)!: <summary>: $title" >&2
  echo "types: feat fix docs ci build chore refactor test; scopes (optional): flows style deps" >&2
  exit 1
fi
