# Wave Orchestration Patterns

## Pattern 1: Feature Implementation

**Use when:** Building a multi-component feature

```
Wave 1: Research & Plan
├── Agent: Explore existing code patterns
├── Agent: Find related implementations
└── Agent: Check dependencies

Wave 2: Parallel Implementation
├── Agent: Build data models
├── Agent: Build API routes
├── Agent: Build frontend components
└── Agent: Build middleware

Wave 3: Integration & Test
├── Agent: Wire components together
├── Agent: Write integration tests
└── Agent: Fix failures from wave 2

Wave 4: Polish
└── Agent: Final fixes, documentation
```

**Example prompt:**
```
/wave "Build user authentication with JWT tokens, login/signup routes, and React components. All tests must pass." --max-iterations 10 --completion-promise "AUTH_COMPLETE"
```

---

## Pattern 2: Research & Exploration

**Use when:** Need to understand a codebase or problem space

```
Wave 1: Broad Exploration
├── Agent: Map directory structure
├── Agent: Find entry points
├── Agent: Identify key patterns
└── Agent: Check documentation

Wave 2: Deep Dives
├── Agent: Analyze authentication flow
├── Agent: Analyze data layer
├── Agent: Analyze API structure
└── Agent: Analyze frontend architecture

Wave 3: Synthesis
└── Agent: Combine findings into report
```

**Example prompt:**
```
/wave "Create a comprehensive architecture document for this codebase. Include data flow, key patterns, and component relationships." --max-iterations 5 --completion-promise "ANALYSIS_COMPLETE"
```

---

## Pattern 3: Test Generation

**Use when:** Need comprehensive test coverage

```
Wave 1: Discover
├── Agent: Find all testable functions
├── Agent: Check existing test patterns
└── Agent: Identify edge cases

Wave 2: Generate
├── Agent: Generate unit tests batch 1
├── Agent: Generate unit tests batch 2
├── Agent: Generate integration tests
└── Agent: Generate edge case tests

Wave 3: Validate
├── Agent: Run all tests
└── Agent: Fix failing tests

Wave 4+: Iterate until green
```

**Example prompt:**
```
/wave "Generate comprehensive tests for src/api/. Target 80% coverage. All tests must pass." --max-iterations 15 --completion-promise "TESTS_PASSING"
```

---

## Pattern 4: Refactoring

**Use when:** Large-scale code transformation

```
Wave 1: Map
├── Agent: Find all instances of old pattern
├── Agent: Identify dependencies
└── Agent: Check for edge cases

Wave 2: Transform (leaf nodes first)
├── Agent: Refactor module A
├── Agent: Refactor module B
└── Agent: Refactor module C

Wave 3: Integrate
├── Agent: Update imports
├── Agent: Fix type errors
└── Agent: Run tests

Wave 4+: Fix issues
```

**Example prompt:**
```
/wave "Refactor all callback-based code to async/await. Ensure tests pass after each change." --max-iterations 20 --completion-promise "REFACTOR_DONE"
```

---

## Pattern 5: Bug Hunt

**Use when:** Tracking down a complex bug

```
Wave 1: Hypothesize
├── Agent: Search error logs
├── Agent: Find related code
├── Agent: Check recent changes
└── Agent: Reproduce issue

Wave 2: Test Hypotheses
├── Agent: Test hypothesis A (race condition)
├── Agent: Test hypothesis B (state corruption)
└── Agent: Test hypothesis C (edge case)

Wave 3: Fix
└── Agent: Implement fix based on findings

Wave 4: Verify
├── Agent: Add regression test
└── Agent: Verify fix works
```

**Example prompt:**
```
/wave "Find and fix the bug causing intermittent auth failures. Add regression test." --max-iterations 10 --completion-promise "BUG_FIXED"
```

---

## Model Selection Guide

| Wave Type | Recommended Model | Rationale |
|-----------|-------------------|-----------|
| Exploration | haiku | Fast, broad coverage |
| Analysis | sonnet | Good reasoning, efficient |
| Implementation | sonnet | Reliable code generation |
| Architecture decisions | opus | Best judgment |
| Debugging | opus | Complex reasoning needed |
| Test generation | sonnet | Pattern matching |
| Documentation | sonnet | Clear writing |

---

## Anti-Patterns

**DON'T:**
- Spawn sequential agents (use `run_in_background=True`)
- Do execution work yourself (spawn agents)
- Lie to escape the loop
- Skip synthesis between waves
- Ignore failed agents (debug them!)

**DO:**
- Maximize parallelism
- Let agents write to shared state
- Read all agent outputs before next wave
- Use appropriate models for each task
- Set reasonable max_iterations
