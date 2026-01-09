#!/bin/bash

# Wave Orchestration Stop Hook
# Prevents session exit when a wave loop is active
# Feeds the orchestration prompt back to continue iteration

set -euo pipefail

#######################################
# Configuration
#######################################
WAVE_STATE_FILE=".claude/wave-state.local.md"
COMPLETION_TAG="wave-complete"

#######################################
# Logging (to stderr so it appears in debug)
#######################################
log_debug() {
  if [[ "${WAVE_DEBUG:-}" == "true" ]]; then
    echo "[wave-hook] $1" >&2
  fi
}

log_info() {
  echo "[Wave] $1" >&2
}

log_warn() {
  echo "[Wave Warning] $1" >&2
}

#######################################
# Cleanup and exit allowing stop
#######################################
allow_exit() {
  log_debug "Allowing exit"
  exit 0
}

#######################################
# Exit blocking stop with new prompt
#######################################
block_exit() {
  local prompt="$1"
  local message="$2"

  log_debug "Blocking exit, feeding prompt back"

  jq -n \
    --arg prompt "$prompt" \
    --arg msg "$message" \
    '{
      "decision": "block",
      "reason": $prompt,
      "systemMessage": $msg
    }'

  exit 0
}

#######################################
# Parse frontmatter from state file
#######################################
parse_frontmatter() {
  local file="$1"
  local key="$2"

  # Extract value between --- markers
  sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$file" | \
    grep "^${key}:" | \
    sed "s/^${key}: *//" | \
    sed 's/^"\(.*\)"$/\1/'  # Strip surrounding quotes
}

#######################################
# Extract prompt content (after frontmatter)
#######################################
extract_prompt() {
  local file="$1"

  # Skip frontmatter, print everything after second ---
  awk '/^---$/{i++; next} i>=2' "$file"
}

#######################################
# Check for completion promise in text
#######################################
check_completion() {
  local text="$1"
  local promise="$2"

  if [[ -z "$promise" ]] || [[ "$promise" == "null" ]]; then
    return 1
  fi

  # Extract content from <wave-complete>...</wave-complete> tags
  local found
  found=$(echo "$text" | perl -0777 -pe "s/.*?<${COMPLETION_TAG}>(.*?)<\/${COMPLETION_TAG}>.*/\$1/s; s/^\\s+|\\s+\$//g; s/\\s+/ /g" 2>/dev/null || echo "")

  if [[ -n "$found" ]] && [[ "$found" == "$promise" ]]; then
    return 0
  fi

  return 1
}

#######################################
# Get last assistant message from transcript
#######################################
get_last_assistant_message() {
  local transcript="$1"

  if [[ ! -f "$transcript" ]]; then
    echo ""
    return
  fi

  # Find last assistant message and extract text content
  local last_line
  last_line=$(grep '"role":"assistant"' "$transcript" 2>/dev/null | tail -1 || echo "")

  if [[ -z "$last_line" ]]; then
    echo ""
    return
  fi

  # Parse JSON and extract text
  echo "$last_line" | jq -r '
    .message.content |
    if type == "array" then
      map(select(.type == "text")) | map(.text) | join("\n")
    else
      .
    end
  ' 2>/dev/null || echo ""
}

#######################################
# Main
#######################################
main() {
  # Read hook input from stdin
  local hook_input
  hook_input=$(cat)

  log_debug "Hook triggered"

  # Check if wave is active
  if [[ ! -f "$WAVE_STATE_FILE" ]]; then
    log_debug "No wave state file, allowing exit"
    allow_exit
  fi

  # Parse state file
  local iteration max_iterations completion_promise
  iteration=$(parse_frontmatter "$WAVE_STATE_FILE" "iteration")
  max_iterations=$(parse_frontmatter "$WAVE_STATE_FILE" "max_iterations")
  completion_promise=$(parse_frontmatter "$WAVE_STATE_FILE" "completion_promise")

  log_debug "State: iteration=$iteration, max=$max_iterations, promise=$completion_promise"

  # Validate iteration is numeric
  if ! [[ "$iteration" =~ ^[0-9]+$ ]]; then
    log_warn "State file corrupted (invalid iteration: $iteration). Stopping wave."
    rm -f "$WAVE_STATE_FILE"
    allow_exit
  fi

  # Validate max_iterations is numeric
  if ! [[ "$max_iterations" =~ ^[0-9]+$ ]]; then
    log_warn "State file corrupted (invalid max_iterations: $max_iterations). Stopping wave."
    rm -f "$WAVE_STATE_FILE"
    allow_exit
  fi

  # Check max iterations
  if [[ $max_iterations -gt 0 ]] && [[ $iteration -ge $max_iterations ]]; then
    log_info "Max iterations ($max_iterations) reached. Wave complete."
    rm -f "$WAVE_STATE_FILE"
    allow_exit
  fi

  # Get transcript path
  local transcript_path
  transcript_path=$(echo "$hook_input" | jq -r '.transcript_path // ""')

  if [[ -z "$transcript_path" ]] || [[ ! -f "$transcript_path" ]]; then
    log_warn "Transcript not found. Stopping wave."
    rm -f "$WAVE_STATE_FILE"
    allow_exit
  fi

  # Get last assistant message
  local last_output
  last_output=$(get_last_assistant_message "$transcript_path")

  if [[ -z "$last_output" ]]; then
    log_warn "No assistant message found. Stopping wave."
    rm -f "$WAVE_STATE_FILE"
    allow_exit
  fi

  # Check for completion promise
  if check_completion "$last_output" "$completion_promise"; then
    log_info "Completion detected: <$COMPLETION_TAG>$completion_promise</$COMPLETION_TAG>"
    rm -f "$WAVE_STATE_FILE"
    allow_exit
  fi

  # Continue to next iteration
  local next_iteration=$((iteration + 1))

  # Extract prompt from state file
  local prompt_text
  prompt_text=$(extract_prompt "$WAVE_STATE_FILE")

  if [[ -z "$prompt_text" ]]; then
    log_warn "No prompt found in state file. Stopping wave."
    rm -f "$WAVE_STATE_FILE"
    allow_exit
  fi

  # Update iteration in state file
  local temp_file="${WAVE_STATE_FILE}.tmp.$$"
  sed "s/^iteration: .*/iteration: $next_iteration/" "$WAVE_STATE_FILE" > "$temp_file"
  mv "$temp_file" "$WAVE_STATE_FILE"

  # Build system message
  local system_msg
  if [[ -n "$completion_promise" ]] && [[ "$completion_promise" != "null" ]]; then
    system_msg="WAVE $next_iteration/$max_iterations | Complete: <$COMPLETION_TAG>$completion_promise</$COMPLETION_TAG>"
  else
    system_msg="WAVE $next_iteration/$max_iterations | Use /cancel-wave to stop"
  fi

  log_info "$system_msg"

  # Block exit and feed prompt back
  block_exit "$prompt_text" "$system_msg"
}

main "$@"
