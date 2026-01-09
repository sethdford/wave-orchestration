---
description: "Show Wave Orchestration help and usage"
---

# Wave Orchestration Help

## Commands

| Command | Description |
|---------|-------------|
| `/wave "goal"` | Start wave orchestration with a goal |
| `/wave-status` | Check current iteration and progress |
| `/cancel-wave` | Stop the orchestration loop |
| `/cancel-wave --clean` | Stop and clean up output files |
| `/wave-preflight` | Check if environment is ready |
| `/wave-clean` | Remove wave output files |
| `/wave-help` | Show this help |

## Usage

```bash
/wave "Your goal here" [--max-iterations N] [--completion-promise TEXT] [--clean]
```

### Options

- `--max-iterations N` — Stop after N iterations (default: 20)
- `--completion-promise TEXT` — Phrase that signals completion (default: DONE)
- `--clean` — Clear previous wave outputs before starting

### Examples

```bash
# Build a feature
/wave "Build user authentication with JWT, tests must pass" --max-iterations 15

# Research a codebase
/wave "Create architecture documentation for this codebase" --max-iterations 5

# With custom completion signal
/wave "Fix all TypeScript errors" --completion-promise "NO_ERRORS"

# Start fresh, clearing old outputs
/wave "Refactor database layer" --clean
```

## How It Works

1. **You start** with `/wave "goal"`
2. **Orchestrator** decomposes goal into parallel tasks
3. **Agents spawn** in background, work simultaneously
4. **When done**, orchestrator tries to exit
5. **Stop hook** checks completion, feeds prompt back if not done
6. **Repeat** until completion criteria met

## Completion

Output `<wave-complete>PROMISE</wave-complete>` when truly done.

Example:
```
All tests passing, feature complete.

<wave-complete>DONE</wave-complete>
```

## State Files

- `.claude/wave-state.local.md` — Iteration and config
- `.claude/wave-outputs/` — Agent results

## Permission Requirements

Background agents need tool permissions. If agents fail with permission errors:

1. Approve Write, Edit, and Bash tools in your session first
2. Or run Claude Code with: `claude --dangerously-skip-permissions`

Run `/wave-preflight` to check your environment.

## Troubleshooting

**Wave won't start:** Check if one is already running with `/wave-status`

**Agents hitting permission errors:** Run `/wave-preflight` and approve tools

**Stuck in loop:** Use `/cancel-wave` or wait for max iterations

**Want to see progress:** Use `/wave-status` for a visual progress bar
