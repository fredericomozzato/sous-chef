#!/usr/bin/env bash

set -e

MINIMUM_SCORE_FILE=".rubycritic_minimum_score"

if [ ! -f "$MINIMUM_SCORE_FILE" ]; then
  echo "ERROR: $MINIMUM_SCORE_FILE not found. Cannot compare score."
  exit 1
fi

MINIMUM_SCORE=$(cat "$MINIMUM_SCORE_FILE" | tr -d '[:space:]')

echo "Running RubyCritic on app/..."
echo "Minimum acceptable score: $MINIMUM_SCORE"
echo "================================================================"

if docker compose ps web --status running -q 2>/dev/null | grep -q .; then
  OUTPUT=$(docker compose exec -T web bundle exec rubycritic app --no-browser 2>&1)
else
  OUTPUT=$(docker compose run --rm -T web bundle exec rubycritic app --no-browser 2>&1)
fi

echo "$OUTPUT"
echo "================================================================"

CURRENT_SCORE=$(echo "$OUTPUT" | grep -E '^Score:' | awk '{print $2}')

if [ -z "$CURRENT_SCORE" ]; then
  echo "ERROR: Could not parse RubyCritic score from output."
  exit 1
fi

echo "Current score : $CURRENT_SCORE"
echo "Minimum score : $MINIMUM_SCORE"

RESULT=$(awk "BEGIN { print ($CURRENT_SCORE >= $MINIMUM_SCORE) ? \"pass\" : \"fail\" }")

if [ "$RESULT" = "fail" ]; then
  DIFF=$(awk "BEGIN { printf \"%.2f\", $MINIMUM_SCORE - $CURRENT_SCORE }")
  echo ""
  echo "FAIL: Score decreased by $DIFF points ($MINIMUM_SCORE -> $CURRENT_SCORE)."
  exit 1
fi

IMPROVED=$(awk "BEGIN { print ($CURRENT_SCORE > $MINIMUM_SCORE) ? \"yes\" : \"no\" }")
if [ "$IMPROVED" = "yes" ]; then
  DIFF=$(awk "BEGIN { printf \"%.2f\", $CURRENT_SCORE - $MINIMUM_SCORE }")
  echo ""
  echo "IMPROVED: Score increased by $DIFF points ($MINIMUM_SCORE -> $CURRENT_SCORE)."
  echo "$CURRENT_SCORE" > "$MINIMUM_SCORE_FILE"
  echo "Updated $MINIMUM_SCORE_FILE. Commit this file with your changes."
else
  echo ""
  echo "PASS: Score maintained at $CURRENT_SCORE."
fi

exit 0
