#!/bin/bash

# Wave Orchestration Cancel Script
# Cleanly cancels an active wave and optionally cleans up outputs

set -euo pipefail

WAVE_STATE_FILE=".claude/wave-state.local.md"
WAVE_OUTPUTS_DIR=".claude/wave-outputs"

# Parse arguments
CLEAN_OUTPUTS=false
QUIET=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --clean)
      CLEAN_OUTPUTS=true
      shift
      ;;
    --quiet|-q)
      QUIET=true
      shift
      ;;
    --help|-h)
      cat << 'EOF'
Cancel Wave Orchestration

USAGE:
  /cancel-wave [options]

OPTIONS:
  --clean    Also remove wave output files
  --quiet    Suppress output
  --help     Show this help

EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Check if wave is active
if [[ ! -f "$WAVE_STATE_FILE" ]]; then
  if [[ "$QUIET" != true ]]; then
    echo "No active wave to cancel."
    echo ""
    if [[ -d "$WAVE_OUTPUTS_DIR" ]] && [[ -n "$(ls -A "$WAVE_OUTPUTS_DIR" 2>/dev/null)" ]]; then
      echo "Previous wave outputs exist in $WAVE_OUTPUTS_DIR"
      echo "Run /cancel-wave --clean to remove them."
    fi
  fi
  exit 0
fi

# Get wave info before cancelling
ITERATION=$(grep '^iteration:' "$WAVE_STATE_FILE" 2>/dev/null | sed 's/iteration: *//' || echo "unknown")
MAX_ITERATIONS=$(grep '^max_iterations:' "$WAVE_STATE_FILE" 2>/dev/null | sed 's/max_iterations: *//' || echo "unknown")

# Remove state file
rm -f "$WAVE_STATE_FILE"

# Optionally clean outputs
if [[ "$CLEAN_OUTPUTS" == true ]] && [[ -d "$WAVE_OUTPUTS_DIR" ]]; then
  OUTPUT_COUNT=$(find "$WAVE_OUTPUTS_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')
  rm -rf "$WAVE_OUTPUTS_DIR"
  if [[ "$QUIET" != true ]]; then
    echo "Removed $OUTPUT_COUNT output file(s)."
  fi
fi

# Report
if [[ "$QUIET" != true ]]; then
  echo ""
  echo "Wave Orchestration Cancelled"
  echo "============================"
  echo ""
  echo "  Stopped at: iteration $ITERATION of $MAX_ITERATIONS"
  echo ""
  if [[ "$CLEAN_OUTPUTS" != true ]] && [[ -d "$WAVE_OUTPUTS_DIR" ]]; then
    echo "  Output files preserved in: $WAVE_OUTPUTS_DIR"
    echo "  Run /cancel-wave --clean to remove them."
  fi
  echo ""
fi
