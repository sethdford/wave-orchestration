#!/bin/bash

# Wave Orchestration Test Suite
# Comprehensive tests for all components

#######################################
# Test configuration
#######################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_DIR=$(mktemp -d)
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

#######################################
# Test utilities
#######################################
setup() {
  cd "$TEST_DIR" || exit 1
  mkdir -p .claude
}

teardown() {
  cd /
  rm -rf "$TEST_DIR"
}

pass() {
  echo "  PASS: $1"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo "  FAIL: $1"
  if [[ -n "${2:-}" ]]; then
    echo "        $2"
  fi
  TESTS_FAILED=$((TESTS_FAILED + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

section() {
  echo ""
  echo "=== $1 ==="
  echo ""
}

#######################################
# File structure tests
#######################################
test_structure() {
  section "Plugin Structure Tests"

  echo -n "Testing plugin.json exists... "
  if [[ -f "$PLUGIN_ROOT/.claude-plugin/plugin.json" ]]; then
    pass "plugin.json exists"
  else
    fail "plugin.json missing"
  fi

  echo -n "Testing plugin.json valid... "
  if jq empty "$PLUGIN_ROOT/.claude-plugin/plugin.json" 2>/dev/null; then
    pass "plugin.json is valid JSON"
  else
    fail "plugin.json invalid"
  fi

  echo -n "Testing hooks.json exists... "
  if [[ -f "$PLUGIN_ROOT/hooks/hooks.json" ]]; then
    pass "hooks.json exists"
  else
    fail "hooks.json missing"
  fi

  echo -n "Testing hooks.json valid... "
  if jq empty "$PLUGIN_ROOT/hooks/hooks.json" 2>/dev/null; then
    pass "hooks.json is valid JSON"
  else
    fail "hooks.json invalid"
  fi

  echo -n "Testing commands exist... "
  CMDS=$(find "$PLUGIN_ROOT/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$CMDS" -ge 4 ]]; then
    pass "Commands exist ($CMDS found)"
  else
    fail "Commands missing" "Found $CMDS, expected >= 4"
  fi

  echo -n "Testing scripts executable... "
  if [[ -x "$PLUGIN_ROOT/scripts/setup-wave.sh" ]] && \
     [[ -x "$PLUGIN_ROOT/hooks/scripts/stop-hook.sh" ]]; then
    pass "Scripts are executable"
  else
    fail "Scripts not executable"
  fi
}

#######################################
# Setup script tests
#######################################
test_setup_script() {
  section "Setup Script Tests"
  cd "$TEST_DIR" || return

  # Test: No arguments
  echo -n "Testing no arguments... "
  if bash "$PLUGIN_ROOT/scripts/setup-wave.sh" 2>&1 | grep -q "No goal provided"; then
    pass "Rejects missing goal"
  else
    fail "Should reject missing goal"
  fi

  # Test: Goal too short
  echo -n "Testing short goal... "
  if bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Hi" 2>&1 | grep -q "too short"; then
    pass "Rejects short goal"
  else
    fail "Should reject short goal"
  fi

  # Test: Invalid max-iterations
  echo -n "Testing invalid max-iterations... "
  if bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Valid goal here" --max-iterations abc 2>&1 | grep -q "positive integer"; then
    pass "Rejects non-numeric max-iterations"
  else
    fail "Should reject non-numeric max-iterations"
  fi

  # Test: Valid setup
  echo -n "Testing valid setup... "
  rm -f .claude/wave-state.local.md
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Build a test feature" --max-iterations 5 >/dev/null 2>&1
  if [[ -f ".claude/wave-state.local.md" ]]; then
    pass "Creates state file"
  else
    fail "Should create state file"
  fi

  # Test: State file content
  echo -n "Testing state file content... "
  if grep -q "iteration: 1" .claude/wave-state.local.md 2>/dev/null && \
     grep -q "max_iterations: 5" .claude/wave-state.local.md 2>/dev/null; then
    pass "State file has correct content"
  else
    fail "State file content incorrect"
  fi

  # Test: Duplicate wave detection
  echo -n "Testing duplicate wave detection... "
  if bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Another goal here" 2>&1 | grep -q "already active"; then
    pass "Detects existing wave"
  else
    fail "Should detect existing wave"
  fi

  # Clean up for next tests
  rm -f .claude/wave-state.local.md

  # Test: Help flag
  echo -n "Testing help flag... "
  if bash "$PLUGIN_ROOT/scripts/setup-wave.sh" --help 2>&1 | grep -q "USAGE"; then
    pass "Shows help"
  else
    fail "Should show help"
  fi
}

#######################################
# Stop hook tests
#######################################
test_stop_hook() {
  section "Stop Hook Tests"
  cd "$TEST_DIR" || return

  # Test: No state file - allows exit
  echo -n "Testing no state file... "
  rm -f .claude/wave-state.local.md
  OUTPUT=$(echo '{}' | bash "$PLUGIN_ROOT/hooks/scripts/stop-hook.sh" 2>&1)
  if [[ -z "$OUTPUT" ]] || ! echo "$OUTPUT" | grep -q '"decision"'; then
    pass "Allows exit when no wave"
  else
    fail "Should allow exit silently"
  fi

  # Create state file
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Test goal for hooks" --max-iterations 3 >/dev/null 2>&1

  # Create mock transcript
  TRANSCRIPT_FILE="$TEST_DIR/transcript.jsonl"
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Working on it..."}]}}' > "$TRANSCRIPT_FILE"

  # Test: Continues wave when not complete
  echo -n "Testing wave continuation... "
  OUTPUT=$(echo "{\"transcript_path\": \"$TRANSCRIPT_FILE\"}" | bash "$PLUGIN_ROOT/hooks/scripts/stop-hook.sh" 2>&1)
  if echo "$OUTPUT" | grep -q '"decision": "block"'; then
    pass "Blocks exit and continues"
  else
    fail "Should block exit" "$OUTPUT"
  fi

  # Test: Iteration incremented
  echo -n "Testing iteration increment... "
  if grep -q "iteration: 2" .claude/wave-state.local.md 2>/dev/null; then
    pass "Incremented iteration"
  else
    fail "Should increment iteration"
  fi

  # Test: Completion detection
  echo -n "Testing completion detection... "
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Done! <wave-complete>DONE</wave-complete>"}]}}' > "$TRANSCRIPT_FILE"
  rm -f .claude/wave-state.local.md
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Test completion" --max-iterations 5 --completion-promise "DONE" >/dev/null 2>&1
  OUTPUT=$(echo "{\"transcript_path\": \"$TRANSCRIPT_FILE\"}" | bash "$PLUGIN_ROOT/hooks/scripts/stop-hook.sh" 2>&1)
  if echo "$OUTPUT" | grep -q "Completion detected"; then
    pass "Detects completion"
  else
    fail "Should detect completion" "$OUTPUT"
  fi
  rm -f .claude/wave-state.local.md
}

#######################################
# Preflight check tests
#######################################
test_preflight() {
  section "Preflight Check Tests"
  cd "$TEST_DIR" || return

  # Test: Passes in clean environment
  echo -n "Testing clean environment... "
  rm -f .claude/wave-state.local.md
  if bash "$PLUGIN_ROOT/scripts/preflight-check.sh" 2>&1 | grep -q "PASSED"; then
    pass "Passes preflight"
  else
    fail "Should pass preflight"
  fi

  # Test: Detects active wave
  echo -n "Testing active wave detection... "
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Preflight test" >/dev/null 2>&1
  if bash "$PLUGIN_ROOT/scripts/preflight-check.sh" 2>&1 | grep -q "ACTIVE"; then
    pass "Detects active wave"
  else
    fail "Should detect active wave"
  fi
  rm -f .claude/wave-state.local.md
}

#######################################
# Cancel wave tests
#######################################
test_cancel_wave() {
  section "Cancel Wave Tests"
  cd "$TEST_DIR" || return

  # Test: Cancel with no active wave
  echo -n "Testing cancel with no wave... "
  rm -f .claude/wave-state.local.md
  if bash "$PLUGIN_ROOT/scripts/cancel-wave.sh" 2>&1 | grep -q "No active wave"; then
    pass "Handles no active wave"
  else
    fail "Should report no active wave"
  fi

  # Test: Cancel active wave
  echo -n "Testing cancel active wave... "
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Cancel test" >/dev/null 2>&1
  if bash "$PLUGIN_ROOT/scripts/cancel-wave.sh" 2>&1 | grep -q "Cancelled"; then
    pass "Cancels wave"
  else
    fail "Should cancel wave"
  fi

  # Test: Cancel with --clean
  echo -n "Testing cancel with --clean... "
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Clean test" >/dev/null 2>&1
  mkdir -p .claude/wave-outputs
  echo "test" > .claude/wave-outputs/test.md
  bash "$PLUGIN_ROOT/scripts/cancel-wave.sh" --clean >/dev/null 2>&1
  if [[ ! -d ".claude/wave-outputs" ]] || [[ -z "$(ls -A .claude/wave-outputs 2>/dev/null)" ]]; then
    pass "Cleans outputs"
  else
    fail "Should clean outputs"
  fi
}

#######################################
# Status tests
#######################################
test_status() {
  section "Status Tests"
  cd "$TEST_DIR" || return

  # Test: Status with no wave
  echo -n "Testing status no wave... "
  rm -f .claude/wave-state.local.md
  if bash "$PLUGIN_ROOT/scripts/wave-status.sh" 2>&1 | grep -q "NO ACTIVE WAVE"; then
    pass "Reports no wave"
  else
    fail "Should report no wave"
  fi

  # Test: Status with active wave
  echo -n "Testing status active wave... "
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Status test" --max-iterations 10 >/dev/null 2>&1
  if bash "$PLUGIN_ROOT/scripts/wave-status.sh" 2>&1 | grep -q "WAVE ACTIVE"; then
    pass "Reports active wave"
  else
    fail "Should report active wave"
  fi

  # Test: Progress display
  echo -n "Testing progress display... "
  if bash "$PLUGIN_ROOT/scripts/wave-status.sh" 2>&1 | grep -q "Progress:"; then
    pass "Shows progress"
  else
    fail "Should show progress"
  fi
  rm -f .claude/wave-state.local.md
}

#######################################
# Max iterations tests
#######################################
test_max_iterations() {
  section "Max Iterations Tests"
  cd "$TEST_DIR" || return

  # Test: Max iterations reached
  echo -n "Testing max iterations... "
  bash "$PLUGIN_ROOT/scripts/setup-wave.sh" "Max iter test" --max-iterations 2 >/dev/null 2>&1
  sed -i '' 's/iteration: 1/iteration: 2/' .claude/wave-state.local.md 2>/dev/null || \
    sed -i 's/iteration: 1/iteration: 2/' .claude/wave-state.local.md

  TRANSCRIPT_FILE=$(mktemp)
  cat > "$TRANSCRIPT_FILE" <<'EOF'
{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Working..."}]}}
EOF
  OUTPUT=$(echo "{\"transcript_path\": \"$TRANSCRIPT_FILE\"}" | bash "$PLUGIN_ROOT/hooks/scripts/stop-hook.sh" 2>&1)
  rm -f "$TRANSCRIPT_FILE"

  if echo "$OUTPUT" | grep -q "Max iterations.*reached"; then
    pass "Stops at max iterations"
  else
    fail "Should stop at max iterations" "$OUTPUT"
  fi

  # Test: State file cleaned after max
  echo -n "Testing cleanup after max... "
  if [[ ! -f ".claude/wave-state.local.md" ]]; then
    pass "Cleans up after max"
  else
    fail "Should clean state file"
    rm -f .claude/wave-state.local.md
  fi
}

#######################################
# Main
#######################################
main() {
  echo ""
  echo "Wave Orchestration Test Suite"
  echo "=============================="

  trap teardown EXIT

  setup
  test_structure
  test_setup_script
  test_stop_hook
  test_preflight
  test_cancel_wave
  test_status
  test_max_iterations

  echo ""
  echo "=============================="
  echo "Results: $TESTS_PASSED/$TESTS_RUN passed"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "FAILED: $TESTS_FAILED tests"
    exit 1
  else
    echo "ALL TESTS PASSED"
    exit 0
  fi
}

main "$@"
