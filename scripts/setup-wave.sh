#!/bin/bash

# Wave Orchestration Setup Script
# Initializes wave state and directories with comprehensive validation

set -euo pipefail

#######################################
# Configuration
#######################################
WAVE_STATE_FILE=".claude/wave-state.local.md"
WAVE_OUTPUTS_DIR=".claude/wave-outputs"
DEFAULT_MAX_ITERATIONS=20
DEFAULT_COMPLETION_PROMISE="DONE"

#######################################
# Error handling
#######################################
error() {
  echo "Error: $1" >&2
  exit 1
}

warn() {
  echo "Warning: $1" >&2
}

#######################################
# Dependency checks
#######################################
check_dependencies() {
  if ! command -v jq &> /dev/null; then
    error "jq is required but not installed. Install with: brew install jq (macOS) or apt install jq (Linux)"
  fi

  if ! command -v perl &> /dev/null; then
    error "perl is required but not installed."
  fi
}

#######################################
# State validation
#######################################
check_no_active_wave() {
  if [[ -f "$WAVE_STATE_FILE" ]]; then
    local iteration
    iteration=$(grep '^iteration:' "$WAVE_STATE_FILE" 2>/dev/null | sed 's/iteration: *//' || echo "unknown")
    error "A wave is already active (iteration $iteration). Run /cancel-wave first, or check status with /wave-status"
  fi
}

#######################################
# Argument parsing
#######################################
parse_arguments() {
  GOAL=""
  MAX_ITERATIONS="$DEFAULT_MAX_ITERATIONS"
  COMPLETION_PROMISE="$DEFAULT_COMPLETION_PROMISE"
  CLEAN_OUTPUTS=false

  while [[ $# -gt 0 ]]; do
    case $1 in
      --max-iterations)
        if [[ -z "${2:-}" ]]; then
          error "--max-iterations requires a number"
        fi
        if ! [[ "$2" =~ ^[0-9]+$ ]]; then
          error "--max-iterations must be a positive integer, got: $2"
        fi
        if [[ "$2" -lt 1 ]]; then
          error "--max-iterations must be at least 1"
        fi
        if [[ "$2" -gt 100 ]]; then
          warn "max-iterations is very high ($2). Consider a lower limit."
        fi
        MAX_ITERATIONS="$2"
        shift 2
        ;;
      --completion-promise)
        if [[ -z "${2:-}" ]]; then
          error "--completion-promise requires a value"
        fi
        COMPLETION_PROMISE="$2"
        shift 2
        ;;
      --clean)
        CLEAN_OUTPUTS=true
        shift
        ;;
      --help|-h)
        show_usage
        exit 0
        ;;
      -*)
        error "Unknown option: $1. Use --help for usage."
        ;;
      *)
        if [[ -z "$GOAL" ]]; then
          GOAL="$1"
        else
          GOAL="$GOAL $1"
        fi
        shift
        ;;
    esac
  done

  # Validate goal
  if [[ -z "$GOAL" ]]; then
    error "No goal provided. Usage: /wave \"Your goal here\" [options]"
  fi

  if [[ ${#GOAL} -lt 10 ]]; then
    error "Goal is too short. Please provide a more detailed description."
  fi
}

show_usage() {
  cat << 'EOF'
Wave Orchestration Setup

USAGE:
  /wave "Your goal" [options]

OPTIONS:
  --max-iterations N      Stop after N iterations (default: 20)
  --completion-promise T  Phrase that signals completion (default: DONE)
  --clean                 Clear previous wave outputs before starting
  --help                  Show this help

EXAMPLES:
  /wave "Build a REST API with auth and tests"
  /wave "Refactor to async/await" --max-iterations 30
  /wave "Fix all type errors" --completion-promise "NO_ERRORS" --clean

EOF
}

#######################################
# Directory setup
#######################################
setup_directories() {
  # Create .claude directory if needed
  if ! mkdir -p .claude 2>/dev/null; then
    error "Cannot create .claude directory. Check permissions."
  fi

  # Handle outputs directory
  if [[ "$CLEAN_OUTPUTS" == true ]] && [[ -d "$WAVE_OUTPUTS_DIR" ]]; then
    rm -rf "$WAVE_OUTPUTS_DIR"
    echo "Cleaned previous wave outputs."
  fi

  if ! mkdir -p "$WAVE_OUTPUTS_DIR" 2>/dev/null; then
    error "Cannot create $WAVE_OUTPUTS_DIR directory. Check permissions."
  fi
}

#######################################
# State file creation
#######################################
create_state_file() {
  local started_at
  started_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat > "$WAVE_STATE_FILE" << STATEEOF
---
iteration: 1
max_iterations: $MAX_ITERATIONS
completion_promise: "$COMPLETION_PROMISE"
started_at: $started_at
goal_hash: $(echo "$GOAL" | md5sum 2>/dev/null | cut -d' ' -f1 || echo "none")
---

# Wave Orchestration Cycle

## Your Goal
$GOAL

## This Iteration
You are the ORCHESTRATOR. Each wave cycle you must:

### 1. ASSESS STATE
- Read .claude/wave-state.local.md for current iteration number
- Check .claude/wave-outputs/ for results from previous agents
- Review any files agents have created or modified
- Identify: what's complete, what's pending, what failed

### 2. DECOMPOSE REMAINING WORK
- What still needs to be done to achieve the goal?
- What tasks can be done in PARALLEL right now?
- What's blocked and waiting on dependencies?
- What's the critical path to completion?

### 3. SPAWN WAVE OF AGENTS
Launch background agents using the Task tool for ALL unblocked work.
Use this exact pattern for each agent:

\`\`\`
Task(
  subagent_type="general-purpose",
  description="Brief 3-5 word description",
  prompt="""CONTEXT: You are a WORKER agent, not an orchestrator.

RULES:
- Complete ONLY the task described below
- Use tools directly (Read, Write, Edit, Bash, etc.)
- Do NOT spawn sub-agents
- Do NOT call TaskCreate or TaskUpdate
- Write your results to .claude/wave-outputs/[descriptive-name].md
- If you encounter errors, document them clearly in your output
- Report your results with absolute file paths

TASK:
[Specific, detailed task description with clear success criteria]
""",
  model="sonnet",
  run_in_background=True
)
\`\`\`

**Model selection:**
- haiku: Simple file searches, quick lookups
- sonnet: Implementation, clear requirements
- opus: Architecture decisions, complex debugging

**Spawn multiple agents in a SINGLE message for parallelism.**

### 4. SYNTHESIZE & CHECK COMPLETION
- Wait for agent completion notifications
- Read agent output files from .claude/wave-outputs/
- Combine results into coherent understanding
- Update any shared state if needed
- Check if ALL completion criteria are met

### Error Handling
If agents fail or produce errors:
- Read their output files to understand what happened
- Retry with clearer instructions or simpler scope
- If permission errors occur, inform the user they need to approve tools first
- If stuck after 3 attempts on the same issue, ask the user for guidance

## Completion Criteria
When the goal "$GOAL" is FULLY achieved:
- All required work is complete
- All tests pass (if applicable)
- No blocking issues remain

**To complete, output exactly:**
\`\`\`
<wave-complete>$COMPLETION_PROMISE</wave-complete>
\`\`\`

**CRITICAL:** Only output this when the goal is genuinely complete. Do not lie to escape the loop.

## Anti-Patterns (AVOID)
- Do NOT spawn agents for trivial one-line tasks
- Do NOT spawn more than 5-7 agents per wave
- Do NOT spawn agents that duplicate work
- Do NOT ignore agent failures — address them

## Current State
- **Iteration:** Check the frontmatter above
- **Previous outputs:** Check .claude/wave-outputs/
- **Max iterations:** $MAX_ITERATIONS

## Begin
Start by reading any existing wave outputs, then assess what work remains.
STATEEOF

  if [[ ! -f "$WAVE_STATE_FILE" ]]; then
    error "Failed to create state file"
  fi
}

#######################################
# Main
#######################################
main() {
  check_dependencies
  parse_arguments "$@"
  check_no_active_wave
  setup_directories
  create_state_file

  echo ""
  echo "Wave Orchestration Initialized"
  echo "=============================="
  echo ""
  echo "  Goal: $GOAL"
  echo "  Max iterations: $MAX_ITERATIONS"
  echo "  Completion signal: <wave-complete>$COMPLETION_PROMISE</wave-complete>"
  echo ""
  echo "  State file: $WAVE_STATE_FILE"
  echo "  Agent outputs: $WAVE_OUTPUTS_DIR/"
  echo ""
  echo "NOTE: If background agents fail with permission errors,"
  echo "approve Write/Edit/Bash tools first or use --dangerously-skip-permissions"
  echo ""
}

main "$@"
