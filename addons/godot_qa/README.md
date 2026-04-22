# Godot QA Addon

This folder contains the Godot-side bootstrap layer for `godot-qa`.

## Install into a project

1. Copy `addons/godot_qa` into the target project's `addons/` directory.
2. Enable the `Godot QA` plugin in Godot. This registers the `GodotQaBridge` autoload singleton.
3. Activate QA mode only for test runs:
   - pass `--qa`
   - or pass one or more `--qa-*` flags such as `--qa-session-token=abc123`
   - or set the project setting `godot_qa/enabled=true` in a test-only project configuration

## Current bootstrap behavior

- The plugin installs an autoload singleton, but the runtime bridge stays dormant until QA mode is explicitly enabled.
- `qa_args.gd` parses `--qa` and `--qa-*` user args into a JSON-compatible dictionary.
- `qa_protocol.gd` emits stable success/error envelopes with `protocol_version` and optional request ids.
- `qa_snapshot.gd` provides reusable JSON-compatible helpers for node trees, all `Control` nodes plus their effective visibility flags, focus graphs, runtime errors, and screenshot files.
- `qa_runtime.gd` is the shared source of truth for target resolution plus the implemented runtime commands: `tree.dump`, `ui.dump`, `focus.get`, `focus.graph`, `node.inspect`, `errors.read`, `input.tap_action`, `input.hold_action`, `input.release_action`, `input.click_target`, `input.mouse_click`, `input.key`, `input.joy_button`, and the M06 `assert.*` commands.
- `qa_bridge.gd` dispatches live commands when QA mode is active, requires the configured `--qa-session-token` on each live command, reports runtime `paused` state, implements `session.pause`, `session.resume`, paused `session.step`, and bounded `screenshot.capture`, exposes structured runtime-error recording helpers for fixtures/runtime helpers, and routes live `assert.*` failures with stable mismatch payloads.
- `qa_runner.gd` handles the one-shot scenario path used by `scenario run`: it loads `request.json`, instantiates the target scene, routes supported steps and assertions through `qa_runtime.gd`, captures real snapshot artifacts, and writes `result.json` with `snapshot_artifacts`.
- `qa_session_runner.gd` handles the live-session path used by `session start`: it loads one scene, binds `127.0.0.1:<random-port>`, serves one JSON-line request per TCP connection, and keeps the process alive until `session.stop`.
- In `--headless` runs where Godot does not expose viewport pixels, screenshot capture falls back to a transparent PNG artifact so the snapshot contract stays stable.

## Current scope limits

- live `layout.audit_current` (`M20`)
- recorder layout-audit execution against a live session (`M20`)

## Safety expectations

- Do not ship the QA addon in release exports by default.
- Do not rely on the autoload existing as proof that QA mode is active.
- Expect inactive commands to fail with a structured `bridge_inactive` error until QA mode is enabled.
- Expect live commands to require both localhost reachability and the per-session token; the token value belongs only in `qa/tmp/session.token`, not normal CLI output.
