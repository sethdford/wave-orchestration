---
name: Wave Orchestration
description: |
  This skill should be used when the user asks to "orchestrate tasks", "run parallel agents", "wave orchestration", "iterative agent loops", "swarm agents", "coordinate multiple agents", or needs guidance on decomposing complex tasks into parallel workstreams with iterative refinement.
version: 1.0.0
auto-trigger:
  - pattern: "wave"
  - pattern: "orchestrat"
  - pattern: "parallel agents"
  - pattern: "swarm"
  - pattern: "ralph loop"
---

# Wave Orchestration Skill

## Overview

Wave Orchestration combines two powerful patterns:
- **Ralph Loop**: Iterative self-improvement through repeated prompts
- **Swarm Orchestration**: Parallel agent execution for speed

The result: **Iterative waves of parallel work** that compound until completion.

## Core Concept

```
        TIME -->

    +-----------------------------------------------------------+
    |  Wave 1           Wave 2           Wave 3                 |
    |                                                           |
    |  +---+ +---+      +---+ +---+      +---+                  |
    |  | A | | B |      | D | | E |      | G |                  |
    |  +---+ +---+      +---+ +---+      +---+                  |
    |  +---+            +---+                                   |
    |  | C |            | F |            COMPLETE               |
    |  +---+            +---+                                   |
    |                                                           |
    +-----------------------------------------------------------+
```

Each wave spawns multiple agents in parallel. Each wave builds on prior results.

## When to Use Wave Orchestration

**Good for:**
- Complex multi-component features
- Tasks requiring both parallelism AND iteration
- Work where you can "walk away" and let it run
- Tasks with clear completion criteria
- Research spanning multiple areas simultaneously

**Not good for:**
- Simple single-file changes
- Tasks requiring constant human judgment
- One-shot operations
- Unclear requirements (clarify first!)

## The Wave Cycle

### 1. ASSESS
Read state and agent outputs from previous wave:
- `.claude/wave-state.local.md` - Iteration counter
- `.claude/wave-outputs/` - Agent results

### 2. DECOMPOSE
Identify remaining work and parallelization opportunities:
- What's done?
- What failed?
- What can run in parallel NOW?
- What's blocked?

### 3. SPAWN
Launch background agents for ALL unblocked work:
```python
Task(
    subagent_type="general-purpose",
    prompt="WORKER preamble + task",
    run_in_background=True
)
```

### 4. SYNTHESIZE
Combine agent results:
- Read output files
- Update shared state
- Check completion criteria
- Prepare for next wave or complete

## Key Commands

- `/wave "goal"` - Start wave orchestration
- `/wave-status` - Check current progress
- `/cancel-wave` - Stop the loop

## State Files

```
.claude/
├── wave-state.local.md     # Iteration, config, prompt
└── wave-outputs/           # Agent results
    ├── explore-auth.md
    ├── implement-jwt.md
    └── test-results.md
```

## Completion

Output `<wave-complete>PROMISE</wave-complete>` when:
- All required work is done
- Tests pass (if applicable)
- No blocking issues remain

**Never lie to escape** - the loop exists to ensure quality.

## Patterns

See `references/patterns.md` for:
- Feature implementation pattern
- Research/exploration pattern
- Test generation pattern
- Refactoring pattern

## Philosophy

1. **Iteration beats perfection** - Let waves refine the work
2. **Parallel beats sequential** - Spawn many agents
3. **Failures inform** - Each failure teaches the next wave
4. **State persists** - Agents see prior work in files
5. **Completion is earned** - Only exit when truly done
