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
# Step 1: Add the marketplace
/plugin marketplace add sethdford/wave-orchestration

# Step 2: Install the plugin
/plugin install wave-orchestration@wave-orchestration
```

### Alternative: Local Installation

```bash
git clone https://github.com/sethdford/wave-orchestration.git ~/wave-orchestration
/plugin install ~/wave-orchestration
```

## Quick Start

```bash
# Check environment is ready
/wave-orchestration:wave-preflight

# Start wave orchestration with a goal
/wave-orchestration:wave "Build a REST API with user auth, CRUD endpoints, and tests" --max-iterations 15

# Check status
/wave-orchestration:wave-status

# Cancel if needed
/wave-orchestration:cancel-wave
```

## Commands

| Command | Description |
|---------|-------------|
| `/wave-orchestration:wave "goal"` | Start wave orchestration |
| `/wave-orchestration:wave-status` | Check current iteration and progress |
| `/wave-orchestration:cancel-wave` | Stop the orchestration loop |
| `/wave-orchestration:cancel-wave --clean` | Stop and clean up output files |
| `/wave-orchestration:wave-preflight` | Verify environment is ready |
| `/wave-orchestration:wave-clean` | Remove wave output files |
| `/wave-orchestration:wave-help` | Show help and usage |

### Options

```bash
/wave-orchestration:wave "goal" [--max-iterations N] [--completion-promise TEXT] [--clean]
```

- `--max-iterations N` — Stop after N iterations (default: 20)
- `--completion-promise TEXT` — Phrase that signals completion (default: DONE)
- `--clean` — Clear previous wave outputs before starting

## How It Works

### The Complete Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  /wave-orchestration:wave "Build a REST API"                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  setup-wave.sh                                                  │
│  ├── Creates .claude/wave-state.local.md (iteration: 1)        │
│  └── Creates .claude/wave-outputs/ directory                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Claude becomes the Orchestrator                                │
│  ├── Reads state file                                           │
│  ├── Decomposes goal into parallel tasks                        │
│  └── Spawns background agents via Task tool                     │
│       ├── Agent A: "Explore codebase" → wave-outputs/explore.md │
│       ├── Agent B: "Design schema" → wave-outputs/schema.md     │
│       └── Agent C: "Setup project" → wave-outputs/setup.md      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Claude tries to exit/complete                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  stop-hook.sh intercepts                                        │
│  ├── Checks for <wave-complete>DONE</wave-complete>             │
│  ├── If NOT complete → increment iteration, feed prompt back    │
│  └── If complete → allow exit, cleanup                          │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌──────────────────────────┐    ┌──────────────────────────┐
│  Not Complete            │    │  Complete                │
│  ├── iteration++         │    │  ├── Remove state file   │
│  └── Loop continues...   │    │  └── Exit successfully   │
└──────────────────────────┘    └──────────────────────────┘
```

### Step-by-Step

1. **Preflight Check** (`/wave-orchestration:wave-preflight`)
   - Verifies `jq` and `perl` are installed
   - Checks `.claude/` directory is writable
   - Confirms no active wave is running

2. **Initialization** (`/wave-orchestration:wave "goal"`)
   - `setup-wave.sh` creates state file with iteration=1
   - Creates empty `.claude/wave-outputs/` directory
   - Loads orchestrator prompt

3. **Wave N Execution**
   - Orchestrator reads state and previous outputs
   - Decomposes remaining work into parallel tasks
   - Spawns agents with `run_in_background=True`
   - Agents write results to `.claude/wave-outputs/`

4. **Iteration Loop**
   - Stop hook checks for completion marker
   - If not complete: increments iteration, continues
   - If complete: cleans up and exits

5. **Completion**
   - Orchestrator outputs `<wave-complete>DONE</wave-complete>`
   - Stop hook allows exit
   - Results remain in `.claude/wave-outputs/`

## State Files

```
.claude/
├── wave-state.local.md     # Iteration counter, config, status
└── wave-outputs/           # Agent results (persisted)
    ├── explore-codebase.md
    ├── implement-feature.md
    └── test-results.md
```

### State File Format

```yaml
---
iteration: 3
goal: "Build a REST API with auth"
max_iterations: 20
completion_promise: DONE
status: active
started_at: 2024-01-15T10:30:00
---

## Progress
- Wave 1: Explored codebase, designed schema
- Wave 2: Implemented auth routes, user model
- Wave 3: Writing tests...
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

Run `/wave-orchestration:wave-preflight` to check your environment before starting.

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
│   └── stop-hook.sh          # Iteration loop hook
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
