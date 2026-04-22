# Godot QA Integration Runtime Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a committed `godot-qa` scenario layer to the repo and use it to investigate and reduce runtime noise without regressing the existing playable prototype.

**Architecture:** Keep the existing `scripts/tests/test_runner.gd` suite as the main gameplay regression harness. Add a small `qa/scenarios/` source-of-truth for scene-level smoke coverage, then use targeted reproduction and the repo’s existing tests to isolate any runtime warning source before changing production code.

**Tech Stack:** Godot 4.6, GDScript, local `godot-qa` CLI, existing headless test suite under `scripts/tests`

---

### Task 1: Add Repo-Level Godot QA Scaffold

**Files:**
- Create: `qa/scenarios/`
- Create: `qa/scenarios/main_smoke.json`
- Modify: `docs/README.md`

- [ ] **Step 1: Add the scenario directory and a minimal failing or not-yet-proven scenario document**

```json
{
  "name": "main_smoke",
  "scene": "res://scenes/main/main.tscn",
  "viewport": {
    "width": 1280,
    "height": 720
  },
  "steps": [
    { "wait_frames": 5 },
    { "snapshot": "boot" }
  ],
  "assert": [
    { "no_errors": true }
  ]
}
```

- [ ] **Step 2: Run doctor/list/run to verify the new scaffold works**

Run: `godot-qa --project . doctor && godot-qa --project . scenario list && godot-qa --project . scenario run main_smoke`
Expected: `doctor` no longer complains about `qa/scenarios`; `scenario list` shows `main_smoke`; `scenario run` either passes cleanly or fails with actionable runtime evidence.

- [ ] **Step 3: Refine the scenario only as much as needed to make it a stable smoke contract**

```json
{
  "name": "main_smoke",
  "scene": "res://scenes/main/main.tscn",
  "viewport": {
    "width": 1280,
    "height": 720
  },
  "steps": [
    { "wait_frames": 10 },
    { "snapshot": "boot" }
  ],
  "assert": [
    { "no_errors": true }
  ]
}
```

- [ ] **Step 4: Document the repo’s intended `godot-qa` role**

```md
- `qa/scenarios/`: committed `godot-qa` smoke scenarios that complement, not replace, `scripts/tests/test_runner.gd`.
```

### Task 2: Reproduce Runtime Noise With Focused Evidence

**Files:**
- Inspect: `qa/artifacts/`
- Inspect: `scripts/tests/edge_utility_pickup_test.gd`
- Inspect: `scripts/tests/ffa_lab_scene_test.gd`
- Inspect: related runtime scene/script files only if evidence points there

- [ ] **Step 1: Reproduce the observed warning with the smallest focused command**

Run: `godot --headless --path . -s res://scripts/tests/edge_utility_pickup_test.gd`
Expected: either reproduce the Jolt error directly or rule this test out.

- [ ] **Step 2: Check the neighboring test if the first one is clean**

Run: `godot --headless --path . -s res://scripts/tests/ffa_lab_scene_test.gd`
Expected: either reproduce the warning or narrow the search window further.

- [ ] **Step 3: Use a live `godot-qa` session when helpful to capture scene state and logs**

Run: `godot-qa --project . session start --scene res://scenes/main/main.tscn`
Expected: a live session starts, produces `qa/tmp/session.json`, and enables `godot-qa tree`, `ui`, `errors`, `logs`, and `snapshot`.

- [ ] **Step 4: State a single root-cause hypothesis before changing code**

```text
Hypothesis: a scene object tied to an Area3D lifecycle is being freed while Jolt still has queued overlap events, so cleanup ordering is producing engine noise during teardown rather than gameplay failure.
```

### Task 3: Fix the Root Cause With TDD

**Files:**
- Test: one existing focused test under `scripts/tests/` that best matches the reproduced issue
- Modify: the smallest production file implicated by evidence

- [ ] **Step 1: Write or extend a focused failing test that proves the noisy lifecycle is not acceptable**

```gdscript
func test_runtime_cleanup_does_not_emit_engine_errors() -> void:
    # Arrange a minimal scene lifecycle that previously emitted teardown noise.
    # Run enough frames to trigger cleanup.
    # Assert the affected nodes are cleaned up through the intended path.
```

- [ ] **Step 2: Run the focused test and confirm it fails for the expected reason**

Run: `godot --headless --path . -s res://scripts/tests/<focused_test>.gd`
Expected: FAIL with evidence tied to the reproduced cleanup issue, not a typo or unrelated regression.

- [ ] **Step 3: Implement the smallest production fix**

```gdscript
# Example shape only; final code must follow the root-cause evidence.
# Guard duplicate teardown, disable monitoring first, then queue_free.
if is_inside_tree():
    set_deferred("monitoring", false)
queue_free()
```

- [ ] **Step 4: Re-run the focused test and the repo smoke layers**

Run: `godot --headless --path . -s res://scripts/tests/<focused_test>.gd && godot-qa --project . scenario run main_smoke`
Expected: focused test passes and the scenario remains green.

### Task 4: Verify the Whole Repo Contract

**Files:**
- Verify only

- [ ] **Step 1: Run the full native suite**

Run: `godot --headless --path . -s res://scripts/tests/test_runner.gd`
Expected: `Suite OK: 86 tests` or the current updated total if new coverage is added.

- [ ] **Step 2: Run the `godot-qa` entry checks**

Run: `godot-qa --project . doctor && godot-qa --project . scenario list && godot-qa --project . scenario run main_smoke`
Expected: all commands succeed with clean artifact output.
