# Wave Orchestration Plugin

**Iterative parallel orchestration for Claude Code**

Combines Ralph Loop (persistent iteration) with swarm parallelism (multiple agents) to create **waves of parallel work that compound until completion**.

## What It Does

```
        TIME -->

    Wave 1           Wave 2           Wave 3

    [A] [B]          [D] [E]          [G]
    [C]              [F]              DONE!

    Each wave spawns parallel agents.
    Each wave builds on prior results.
    Iterate until complete.
```

## Installation

```bash
# From marketplace (when published)
/plugin install wave-orchestration@claude-plugins-official

# Or install locally
/plugin install ~/wave-orchestration
```

## Quick Start

```bash
# Check environment is ready
/wave-preflight

# Start wave orchestration with a goal
/wave "Build a REST API with user auth, CRUD endpoints, and tests" --max-iterations 15

# Check status
/wave-status

# Cancel if needed
/cancel-wave
```

## Commands

| Command | Description |
|---------|-------------|
| `/wave "goal"` | Start wave orchestration |
| `/wave-status` | Check current iteration and progress |
| `/cancel-wave` | Stop the orchestration loop |
| `/cancel-wave --clean` | Stop and clean up output files |
| `/wave-preflight` | Verify environment is ready |
| `/wave-clean` | Remove wave output files |
| `/wave-help` | Show help and usage |

### /wave Options

```bash
/wave "goal" [--max-iterations N] [--completion-promise TEXT] [--clean]
```

- `--max-iterations N` — Stop after N iterations (default: 20)
- `--completion-promise TEXT` — Phrase that signals completion (default: DONE)
- `--clean` — Clear previous wave outputs before starting

## How It Works

1. **You invoke `/wave`** with a goal
2. **Setup script** creates state file and output directory
3. **Orchestrator** decomposes goal into parallel tasks
4. **Agents spawn** in background, work simultaneously
5. **When you try to exit**, Stop hook intercepts
6. **Hook feeds prompt back** for next iteration
7. **Orchestrator sees** previous agent outputs, continues
8. **Loop repeats** until completion criteria met

## State Files

```
.claude/
├── wave-state.local.md     # Iteration counter, config, prompt
└── wave-outputs/           # Agent results
    ├── explore-codebase.md
    ├── implement-feature.md
    └── test-results.md
```

## Completion

Output `<wave-complete>PROMISE</wave-complete>` when done:

```
All tests passing, implementation complete.

<wave-complete>DONE</wave-complete>
```

**Don't lie to escape** — the loop ensures quality.

## Permission Requirements

**Important:** Background agents need tool permissions. If agents fail with permission errors:

1. Approve Write, Edit, and Bash tools in your session first
2. Or run Claude Code with: `claude --dangerously-skip-permissions`

Run `/wave-preflight` to check your environment before starting.

## Patterns

See `skills/wave-orchestration/references/patterns.md` for:

- **Feature Implementation** — Multi-component builds
- **Research & Exploration** — Codebase analysis
- **Test Generation** — Comprehensive coverage
- **Refactoring** — Large-scale transformations
- **Bug Hunt** — Complex debugging

## Philosophy

| Principle | Meaning |
|-----------|---------|
| Iteration > Perfection | Let waves refine the work |
| Parallel > Sequential | Spawn many agents at once |
| Failures inform | Each failure teaches next wave |
| State persists | Agents see prior work in files |
| Completion is earned | Only exit when truly done |

## Components

```
wave-orchestration/
├── .claude-plugin/
│   └── plugin.json           # Plugin manifest
├── commands/
│   ├── wave.md               # /wave command
│   ├── wave-status.md        # /wave-status command
│   ├── cancel-wave.md        # /cancel-wave command
│   ├── wave-preflight.md     # /wave-preflight command
│   ├── wave-clean.md         # /wave-clean command
│   └── wave-help.md          # /wave-help command
├── agents/
│   └── wave-orchestrator.md  # Orchestrator agent
├── skills/
│   └── wave-orchestration/
│       ├── SKILL.md          # Skill definition
│       └── references/
│           └── patterns.md   # Orchestration patterns
├── hooks/
│   ├── hooks.json            # Hook configuration
│   └── scripts/
│       └── stop-hook.sh      # Iteration loop hook
└── scripts/
    ├── setup-wave.sh         # Initialization script
    ├── cancel-wave.sh        # Cancellation script
    ├── wave-status.sh        # Status display script
    ├── preflight-check.sh    # Environment validation
    └── test-suite.sh         # Comprehensive test suite
```

## Testing

Run the test suite to verify all components work correctly:

```bash
./scripts/test-suite.sh
```

The test suite validates:
- Plugin structure (6 tests)
- Setup script (7 tests)
- Stop hook (4 tests)
- Preflight check (2 tests)
- Cancel wave (3 tests)
- Status display (3 tests)
- Max iterations (2 tests)

**Total: 27 tests**

## Credits

Inspired by:
- [Ralph Wiggum Technique](https://ghuntley.com/ralph/) by Geoffrey Huntley
- Claude Code's orchestration patterns
- The trading floor energy of parallel execution

---

**Wave Orchestration** — *Iteration meets parallelism*
