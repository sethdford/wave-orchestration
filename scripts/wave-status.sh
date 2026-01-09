#!/bin/bash

# Wave Orchestration Status Script
# Shows current wave state in a clear, visual format

set -euo pipefail

WAVE_STATE_FILE=".claude/wave-state.local.md"
WAVE_OUTPUTS_DIR=".claude/wave-outputs"

#######################################
# Helper: Extract frontmatter value
#######################################
get_frontmatter() {
  local file="$1"
  local key="$2"

  sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file" | \
    grep "^${key}:" | \
    sed "s/^${key}: *//" | \
    sed 's/^"\(.*\)"$/\1/'
}

#######################################
# Main
#######################################
main() {
  echo ""
  echo "Wave Orchestration Status"
  echo "========================="
  echo ""

  # Check if wave is active
  if [[ ! -f "$WAVE_STATE_FILE" ]]; then
    echo "  Status: NO ACTIVE WAVE"
    echo ""

    # Check for leftover outputs
    if [[ -d "$WAVE_OUTPUTS_DIR" ]] && [[ -n "$(ls -A "$WAVE_OUTPUTS_DIR" 2>/dev/null)" ]]; then
      OUTPUT_COUNT=$(find "$WAVE_OUTPUTS_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
      echo "  Previous wave outputs: $OUTPUT_COUNT file(s) in $WAVE_OUTPUTS_DIR"
      echo "  Run /cancel-wave --clean to remove them."
      echo ""
    fi

    echo "  Start a wave with: /wave \"your goal\""
    echo ""
    exit 0
  fi

  # Parse state
  ITERATION=$(get_frontmatter "$WAVE_STATE_FILE" "iteration")
  MAX_ITERATIONS=$(get_frontmatter "$WAVE_STATE_FILE" "max_iterations")
  COMPLETION_PROMISE=$(get_frontmatter "$WAVE_STATE_FILE" "completion_promise")
  STARTED_AT=$(get_frontmatter "$WAVE_STATE_FILE" "started_at")

  # Extract goal from content
  GOAL=$(sed -n '/^## Your Goal$/,/^##/{/^## Your Goal$/d;/^##/d;p;}' "$WAVE_STATE_FILE" | head -1 | sed 's/^ *//')

  # Calculate progress
  if [[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] && [[ "$ITERATION" =~ ^[0-9]+$ ]]; then
    PROGRESS=$((ITERATION * 100 / MAX_ITERATIONS))
    REMAINING=$((MAX_ITERATIONS - ITERATION))
  else
    PROGRESS="?"
    REMAINING="?"
  fi

  # Display status
  echo "  Status: WAVE ACTIVE"
  echo ""
  echo "  Goal: $GOAL"
  echo ""

  # Progress bar
  echo -n "  Progress: ["
  BAR_WIDTH=20
  FILLED=$((PROGRESS * BAR_WIDTH / 100))
  for ((i=0; i<FILLED; i++)); do echo -n "#"; done
  for ((i=FILLED; i<BAR_WIDTH; i++)); do echo -n "-"; done
  echo "] ${PROGRESS}%"
  echo ""

  echo "  Iteration: $ITERATION of $MAX_ITERATIONS"
  echo "  Remaining: $REMAINING iteration(s)"
  echo "  Started: $STARTED_AT"
  echo ""
  echo "  Completion signal: <wave-complete>$COMPLETION_PROMISE</wave-complete>"
  echo ""

  # Show agent outputs
  if [[ -d "$WAVE_OUTPUTS_DIR" ]] && [[ -n "$(ls -A "$WAVE_OUTPUTS_DIR" 2>/dev/null)" ]]; then
    echo "  Agent Outputs:"
    for file in "$WAVE_OUTPUTS_DIR"/*; do
      if [[ -f "$file" ]]; then
        FILENAME=$(basename "$file")
        SIZE=$(wc -c < "$file" | tr -d ' ')
        LINES=$(wc -l < "$file" | tr -d ' ')
        echo "    - $FILENAME ($LINES lines, $SIZE bytes)"
      fi
    done
    echo ""
  else
    echo "  Agent Outputs: None yet"
    echo ""
  fi

  echo "  Commands:"
  echo "    /cancel-wave      - Stop the current wave"
  echo "    /cancel-wave --clean - Stop and clean up outputs"
  echo ""
}

main "$@"
