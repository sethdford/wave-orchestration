---
description: "Check if environment is ready for Wave Orchestration"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/preflight-check.sh)"]
---

# Wave Orchestration Preflight Check

Run the preflight check to verify your environment is ready:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/preflight-check.sh"
```

This checks:
- Required dependencies (jq, perl)
- No existing wave active
- Directory permissions
- Git availability (optional)

If all checks pass, you're ready to run `/wave "your goal"`.

**Important:** Background agents need tool permissions. If you haven't approved Write, Edit, and Bash tools in this session, agents may fail. Consider approving them first or running with `--dangerously-skip-permissions`.
