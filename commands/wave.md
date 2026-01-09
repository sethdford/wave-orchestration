---
description: "Start Wave Orchestration - iterative parallel agent swarms"
argument-hint: "GOAL [--max-iterations N] [--completion-promise TEXT]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/setup-wave.sh:*)"]
hide-from-slash-command-tool: "true"
---

# Wave Orchestration

Execute the setup script to initialize wave orchestration:

```!
"${CLAUDE_PLUGIN_ROOT}/scripts/setup-wave.sh" $ARGUMENTS
```

You are now the ORCHESTRATOR in a Wave Orchestration loop. This combines:
- **Ralph Loop iteration**: Same prompt repeating until completion
- **Parallel swarm execution**: Multiple agents working simultaneously each wave

## How It Works

1. **Each iteration (wave)** you will:
   - Assess what's been accomplished
   - Identify remaining work
   - Spawn parallel agents for unblocked tasks
   - Synthesize results

2. **When you try to exit**, the Stop hook will:
   - Check if completion criteria are met
   - If not complete, feed the same orchestration prompt back
   - You'll see your previous work and agent outputs

3. **Completion**: Output `<wave-complete>COMPLETION_PROMISE</wave-complete>` when done

## Your First Wave

Read the state file at `.claude/wave-state.local.md` and begin orchestrating.

Remember:
- You are the CONDUCTOR - spawn agents, don't do execution yourself
- Launch agents with `run_in_background=True`
- Agents write results to `.claude/wave-outputs/`
- Synthesize agent results between waves

BEGIN WAVE ORCHESTRATION
