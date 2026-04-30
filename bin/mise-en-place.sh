#!/usr/bin/env bash
# Initialize the sous-chef project structure.
# Safe to run multiple times — never overwrites existing files.

set -e

BASE="${1:-sous-chef}"

mkdir -p "$BASE/milestones" "$BASE/issues" "$BASE/reviews"

if [ ! -f "$BASE/PRD.md" ]; then
  cat > "$BASE/PRD.md" << 'EOF'
# PRD

## Summary

<!-- App name and one-line description -->

## Users

<!-- Who uses this app, their technical level and goals -->

## Features

<!-- One section per planned feature. Each becomes a roadmap slice. -->

## UI / UX

<!-- Key screens, interactions, layout constraints, responsive requirements -->

## Data Model

<!-- Key entities, relationships, important columns -->
EOF
  echo "  created $BASE/PRD.md"
else
  echo "  skipped $BASE/PRD.md (already exists)"
fi

if [ ! -f "$BASE/ARCHITECTURE.md" ]; then
  cat > "$BASE/ARCHITECTURE.md" << 'EOF'
# Architecture

## Stack

- Auth: <!-- e.g., Devise -->
- Tests: <!-- e.g., RSpec + FactoryBot -->
- Background jobs: <!-- e.g., Sidekiq / GoodJob / none -->
- Frontend: <!-- e.g., Hotwire (Turbo + Stimulus) -->
- CSS: <!-- e.g., Tailwind / plain CSS -->
- DB: <!-- e.g., PostgreSQL -->

## Non-obvious decisions

<!-- Document conventions that deviate from Rails defaults or require explanation.
     Standard Rails MVC, ActiveRecord, RESTful routes are assumed and NOT repeated here. -->
EOF
  echo "  created $BASE/ARCHITECTURE.md"
else
  echo "  skipped $BASE/ARCHITECTURE.md (already exists)"
fi

echo ""
echo "$BASE/ ready. Next step: run /chef:interview to plan your features."
