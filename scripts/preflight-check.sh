#!/bin/bash

# Wave Orchestration Preflight Check
# Validates environment before starting a wave

set -euo pipefail

ERRORS=0
WARNINGS=0

echo "Wave Orchestration Preflight Check"
echo "==================================="
echo ""

# Check jq
echo -n "Checking jq... "
if command -v jq &> /dev/null; then
  echo "OK ($(jq --version))"
else
  echo "MISSING"
  echo "  Install with: brew install jq (macOS) or apt install jq (Linux)"
  ((ERRORS++))
fi

# Check perl (for promise detection)
echo -n "Checking perl... "
if command -v perl &> /dev/null; then
  echo "OK"
else
  echo "MISSING"
  echo "  Required for completion promise detection"
  ((ERRORS++))
fi

# Check for existing wave
echo -n "Checking for active wave... "
if [[ -f ".claude/wave-state.local.md" ]]; then
  echo "ACTIVE"
  ITERATION=$(sed -n '/^iteration:/p' .claude/wave-state.local.md | sed 's/iteration: *//')
  echo "  Wave already running (iteration $ITERATION)"
  echo "  Run /cancel-wave first or use /wave-status"
  ((ERRORS++))
else
  echo "CLEAR"
fi

# Check .claude directory is writable
echo -n "Checking .claude directory... "
if [[ -d ".claude" ]]; then
  if [[ -w ".claude" ]]; then
    echo "OK (exists, writable)"
  else
    echo "NOT WRITABLE"
    ((ERRORS++))
  fi
else
  if mkdir -p .claude 2>/dev/null; then
    echo "OK (created)"
    rmdir .claude 2>/dev/null || true
  else
    echo "CANNOT CREATE"
    ((ERRORS++))
  fi
fi

# Check git (optional but recommended)
echo -n "Checking git... "
if command -v git &> /dev/null; then
  if git rev-parse --git-dir &> /dev/null; then
    echo "OK (in git repo)"
  else
    echo "OK (not in git repo - agents won't see git history)"
    ((WARNINGS++))
  fi
else
  echo "NOT FOUND (optional)"
  ((WARNINGS++))
fi

echo ""
echo "==================================="

if [[ $ERRORS -gt 0 ]]; then
  echo "PREFLIGHT FAILED: $ERRORS error(s), $WARNINGS warning(s)"
  echo ""
  echo "Fix the errors above before running /wave"
  exit 1
else
  if [[ $WARNINGS -gt 0 ]]; then
    echo "PREFLIGHT PASSED with $WARNINGS warning(s)"
  else
    echo "PREFLIGHT PASSED"
  fi
  echo ""
  echo "Ready for wave orchestration!"
  echo ""
  echo "IMPORTANT: Background agents need tool permissions."
  echo "If agents fail with permission errors:"
  echo "  1. Approve tools (Write, Edit, Bash) in your session first"
  echo "  2. Or run Claude Code with: claude --dangerously-skip-permissions"
  exit 0
fi
