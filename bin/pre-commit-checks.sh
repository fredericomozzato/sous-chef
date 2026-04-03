#!/usr/bin/env bash

set -e

# Find the merge base with main
BASE_COMMIT=$(git merge-base main HEAD 2>/dev/null || git merge-base origin/main HEAD)

if [ -z "$BASE_COMMIT" ]; then
  echo "Could not find merge base with main. Are you on a branch?"
  exit 1
fi

echo "Checking changes against base commit: $BASE_COMMIT"

# Get changed ruby files (excluding deleted files)
CHANGED_FILES=$(git diff --name-only "$BASE_COMMIT" --diff-filter=d)
changed_specs=$(echo "$CHANGED_FILES" | grep -E '_spec\.rb$' || true)
changed_ruby=$(echo "$CHANGED_FILES" | grep -E '\.rb$' || true)

specs_failed=0
lint_failed=0

# Run specs
if [ -n "$changed_specs" ]; then
  echo "================================================================"
  echo "Running specs for changed files:"
  echo "$changed_specs"
  echo "================================================================"
  
  # Format specs to be space separated
  specs_args=$(echo "$changed_specs" | tr '\n' ' ')
  
  # make test handles passing args to rspec
  if ! make test $specs_args; then
    specs_failed=1
  fi
else
  echo "No spec files changed."
fi

# Run Rubocop
if [ -n "$changed_ruby" ]; then
  echo "================================================================"
  echo "Running Rubocop for changed ruby files:"
  echo "$changed_ruby"
  echo "================================================================"
  
  ruby_args=$(echo "$changed_ruby" | tr '\n' ' ')
  
  if docker compose ps web --status running -q 2>/dev/null | grep -q .; then
    if ! docker compose exec web bin/rubocop $ruby_args; then
      lint_failed=1
    fi
  else
    if ! docker compose run --rm web bin/rubocop $ruby_args; then
      lint_failed=1
    fi
  fi
else
  echo "No Ruby files changed."
fi

echo "================================================================"

# Final status
if [ $specs_failed -ne 0 ]; then
  echo "❌ Specs failed."
fi

if [ $lint_failed -ne 0 ]; then
  echo "❌ Rubocop failed."
fi

if [ $specs_failed -ne 0 ] || [ $lint_failed -ne 0 ]; then
  echo "❌ Pre-commit checks failed. Please fix before committing."
  exit 1
fi

echo "✅ All pre-commit checks passed!"
exit 0
