---
description: "Clean up Wave Orchestration outputs"
allowed-tools: ["Bash(rm:*)", "Bash(ls:*)"]
---

# Clean Wave Outputs

Remove wave orchestration output files.

```!
if [ -d ".claude/wave-outputs" ]; then
  COUNT=$(find .claude/wave-outputs -type f 2>/dev/null | wc -l | tr -d ' ')
  rm -rf .claude/wave-outputs
  echo "Cleaned $COUNT wave output file(s)."
else
  echo "No wave outputs to clean."
fi
```

This removes all agent output files from `.claude/wave-outputs/`.

**Note:** This does not cancel an active wave. Use `/cancel-wave` for that.
