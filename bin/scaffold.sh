#!/usr/bin/env bash
set -euo pipefail

# Creates the sous-chef project structure with empty placeholder files.
# Safe to run on an existing project — skips files that already exist.

if [ -d "$(pwd)/.sous-chef" ]; then
  ROOT="$(pwd)/.sous-chef"
else
  ROOT="$(pwd)/sous-chef"
fi

mkdir -p "$ROOT/milestones"
mkdir -p "$ROOT/issues"
mkdir -p "$ROOT/reviews"

touch_if_missing() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    touch "$path"
    echo "  created  $path"
  else
    echo "  exists   $path"
  fi
}

touch_if_missing "$ROOT/PRD.md"
touch_if_missing "$ROOT/ARCHITECTURE.md"
touch_if_missing "$ROOT/CHECKPOINT"

echo ""
echo "$(basename "$ROOT")/ structure ready."
