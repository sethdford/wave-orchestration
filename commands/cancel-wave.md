---
description: "Cancel active Wave Orchestration"
argument-hint: "[--clean]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/cancel-wave.sh:*)"]
---

# Cancel Wave Orchestration

Cancel the currently active wave orchestration loop.

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/cancel-wave.sh" $ARGUMENTS
```

## Options

- `--clean` - Also remove wave output files from `.claude/wave-outputs/`

## After Cancelling

The Stop hook will no longer intercept exits. You can:

- Review agent outputs in `.claude/wave-outputs/`
- Start a new wave with `/wave "your goal"`
- Clean up outputs with `/cancel-wave --clean`
