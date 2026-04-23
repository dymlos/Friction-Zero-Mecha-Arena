# 2026-04-23 - Production milestones proposal

This document reframes the project from "playable prototype with validated slices" to "complete local game with coherent end-to-end experience".

It is based on:
- `AGENTS.md`
- `Documentacion/01-10`
- `ESTADO_ACTUAL.md`
- `PLAN_DESARROLLO.md`
- `PROXIMOS_PASOS.md`
- `DECISIONES_TECNICAS.md`
- the detailed logs under `docs/status/`, `docs/roadmap-history/` and `docs/decisions/`

## Current reading of the project

The project is not starting from zero. The current build already has a strong playable base:
- shared-screen local `Teams` and `FFA`
- movement with inertia and meaningful collisions
- modular damage, energy and `Overdrive`
- detached parts, denial and delayed disabled-body explosion
- first archetype layer
- edge pickups, arena pressure and recap/final result flows
- first `Teams` post-death support slice
- active scene-level test coverage focused on `base/validation` parity

The main gap is not "missing one core mechanic". The gap is that the project is still organized like a well-instrumented prototype and now needs to evolve into a fuller product:
- better shell and menus
- better onboarding
- stronger presentation and readability
- stronger controller handling
- larger playable scale
- real 1080p performance work
- clearer player-facing options and information architecture

## Planning criteria used for this proposal

1. Protect the current combat identity first.
2. Avoid treating "bigger maps", "8 players" or "better graphics" as isolated requests.
3. Move earlier anything that can block many later features:
   - input contracts
   - local multiplayer scalability
   - performance budgets
   - shared-screen readability
4. Group together features that share the same player-facing surface:
   - pause + in-match info + settings
   - character explanations + practice + onboarding
5. Delay expensive polish layers until the game shell, pacing and information model are stable enough.

## Suggested milestone order

1. Production foundation and scalability
2. Match scale, maps and spatial pacing
3. Match UX, shell and information architecture
4. Roster identity, readability and character communication
5. Practice, onboarding and accessibility
6. Audio-visual production pass
7. Integration, optimization and release-readiness

## Milestone 1 - Production foundation and scalability

### Goal

Establish the technical and UX contracts that every later milestone depends on:
- target player counts
- controller ownership
- pause authority
- performance budgets
- shared-screen scale assumptions

### Main task groups

- `Performance`
  - profile current 720p vs 1080p behavior
  - define target frame budget and target hardware baseline
  - identify the main sources of slowdown before touching presentation polish
  - establish an optimization plan for simulation, rendering and UI

- `Local multiplayer systems`
  - formalize support for up to `8` local players
  - formalize `4v4` as the team-mode upper bound
  - validate multi-joypad ownership, hot-plug expectations and slot assignment rules
  - define what happens if a controller disconnects during a match

- `Input and control contracts`
  - define how player slots are created, recognized and preserved through menus and matches
  - define pause ownership and resume flow
  - define controller prompt strategy so the UI knows what buttons to show

- `Shared-screen scale review`
  - document the practical camera and readability constraints for 4, 6 and 8 players
  - define occupancy metrics that later map work must respect
  - document when the screen becomes too dense for current HUD and VFX language

### Why these tasks belong together

These are all foundational constraints. If they stay unresolved:
- map resizing can become wasted work
- pause/menu flows can break under multiple controllers
- practice mode can teach the wrong controls
- visual polish can make 1080p performance worse before the real bottlenecks are known

### Dependencies

- none as a production milestone
- should preserve existing `base/validation` scene parity rules while this work is planned and executed

### Risks and open questions

- "Support 8 players" is currently a product requirement, not yet a proven gameplay scale
- shared-screen readability may force different defaults for 4-player and 8-player sessions
- "any player can pause" needs a conflict policy:
  - who can confirm leaving?
  - can a player other than the pauser resume?
  - what happens if two players press `Start` at once?

### Exit criteria

- a documented performance target matrix exists
- controller ownership rules are explicit
- pause/resume/leave authority is explicit
- map work can start against a real occupancy/readability target instead of intuition

## Milestone 2 - Match scale, maps and spatial pacing

### Goal

Redesign the playable scale of the match so larger maps improve tactics instead of just increasing empty travel time.

### Main task groups

- `Gameplay space`
  - revisit map size, traversal times and combat footprint together
  - redesign arena layouts for flanking, dodging, hiding, repositioning and tactical spacing
  - validate edge-value, cover density and route variety under larger occupancy

- `Match pacing`
  - revisit spawn spacing and opening tempo on larger arenas
  - revisit pressure timing and safe-area reduction against the new scale
  - preserve the intended flow:
    - balanced opening
    - time for reading and positioning
    - escalating pressure
    - explosive ending

- `Mode-specific spatial needs`
  - ensure `FFA` still creates opportunism and third-party play
  - ensure `Teams` still allows rescues, coordinated pushes and recoveries
  - verify that larger maps do not make support/recovery loops too slow

### Why these tasks belong together

The request "make maps almost double" is underspecified on its own. In this project, map size affects:
- camera readability
- time to first engagement
- item value
- viability of rescues
- post-death support timing
- pressure timing
- 8-player crowding

So this has to be handled as one spatial/pacing milestone, not as a one-off geometry increase.

### Dependencies

- depends on Milestone 1 because the new map scale must be validated against real controller and performance constraints

### Risks and open questions

- bigger maps can accidentally weaken the collision fantasy if travel time grows too much
- more cover can become "micro-fortresses" that harm readability
- 8-player occupancy may require map variants, not just one universal layout philosophy
- current `Teams` post-death support slice may need retuning after map growth

### Exit criteria

- map scale guidelines are documented
- at least one clear large-map target for `Teams` and one for `FFA` is defined
- pacing implications are known before presentation polish starts

## Milestone 3 - Match UX, shell and information architecture

### Goal

Turn the current playable slice into a coherent playable product shell:
- pause
- menu structure
- in-match information
- configuration entry points
- clearer player-facing flow

### Main task groups

- `Menu and shell UX`
  - define the full flow from main menu to match setup to match to pause to exit
  - place `How to Play` in the main menu and pause menu
  - define where match settings and gameplay settings live

- `Pause flow`
  - any player can open pause with `Start`
  - match must stop in a real frozen state
  - pause menu must include:
    - resume
    - leave match
    - second confirmation before leaving
  - define whether pause also exposes settings, controls and `How to Play`

- `HUD and information model`
  - audit HUD for clarity under higher player counts
  - define rules for cooldowns, statuses, interaction prompts and object feedback
  - define what is always visible vs contextual
  - revisit top-level wording consistency across menus, pause, HUD and end-of-match surfaces

- `Configuration UX`
  - define player-facing options for graphics, audio, controls and gameplay
  - define which options belong pre-match and which belong in pause

### Why these tasks belong together

These requests all live on the same player-facing surface. Separating them would create duplicated wording, duplicated control prompts and inconsistent navigation.

### Dependencies

- depends on Milestone 1 because pause, prompts and settings depend on finalized controller ownership rules
- should follow Milestone 2 enough to know what the match actually needs to communicate on larger arenas

### Risks and open questions

- "clear interface at all times" is too broad unless translated into concrete visibility rules
- the project already has an explicit/contextual HUD concept; this milestone should refine it, not discard it
- menu scope can grow too fast if every future feature tries to land here at once

### Exit criteria

- the shell flow is documented end-to-end
- pause behavior is explicit
- UI responsibilities are clearly split between main menu, match setup, HUD, pause and result screens

## Milestone 4 - Roster identity, readability and character communication

### Goal

Make each playable character feel distinct while preserving one coherent robot family and improving legibility.

### Main task groups

- `Character identity`
  - define what must differentiate characters visually:
    - silhouette accents
    - color/material language
    - readability markers
    - archetype cues
  - preserve the same industrial family across the whole roster

- `Gameplay readability`
  - align visual identity with gameplay identity
  - ensure differences help both personality and instant recognition
  - define what must be readable from the body, not only from HUD text

- `Character communication`
  - define the `Characters` section content:
    - role
    - strengths
    - unique actions
    - joystick mapping
  - decide which information should be:
    - text
    - iconography
    - short clips/animated previews later
    - in-practice contextual prompts

### Why these tasks belong together

Visual differentiation and character explanation should not evolve separately. If the roster page says one thing and the actual model language says another, the game becomes harder to learn.

### Dependencies

- depends on Milestone 3 because the shell needs to know where character information lives
- should happen after Milestone 2 so character readability is judged on the intended map scale, not only the old compact arenas

### Risks and open questions

- too much variation can break the shared-family robot fantasy
- too little variation can make 8-player matches unreadable
- if roster gameplay keeps changing, long text can become expensive to maintain

### Exit criteria

- the roster identity rules are documented
- character communication format is defined
- "text vs icon vs in-game demonstration" decisions are explicit

## Milestone 5 - Practice, onboarding and accessibility

### Goal

Make the game learnable and testable without competitive pressure.

### Main task groups

- `Practice mode`
  - define scope:
    - free sandbox
    - map exploration
    - skill testing
    - item and object testing
    - part recovery/denial testing
  - decide whether the first version is solo-only or local-multiplayer-capable
  - decide whether it includes dummies, scripted drills or only free experimentation

- `How to Play`
  - explain match logic, win/loss conditions, important systems and core controls
  - split foundational knowledge from character-specific knowledge
  - keep long text minimal where a diagram or small visual callout would teach faster

- `Accessibility and learnability`
  - define minimum accessibility expectations for:
    - input remapping visibility
    - prompt clarity
    - text readability
    - color dependence
    - motion/noise tolerance
  - define what the game should teach in the shell, in practice and during a real match

### Why these tasks belong together

Practice mode is not only a sandbox feature. It is where onboarding, experimentation and controller learnability meet. Treating them as separate milestones would make the game explain itself in three different ways.

### Dependencies

- depends on Milestones 3 and 4 because onboarding needs the final information architecture and character language
- depends partially on Milestone 2 because practice maps should reflect the new spatial rules

### Risks and open questions

- "Practice mode" is still ambiguous:
  - free sandbox only?
  - training drills?
  - character lab?
  - map lab?
- a very text-heavy `How to Play` would conflict with the game's readability goals

### Exit criteria

- the first practice-mode scope is explicit
- onboarding content is split into reusable layers
- minimum accessibility expectations are documented

## Milestone 6 - Audio-visual production pass

### Goal

Raise presentation quality in a way that supports readability, weight and player feedback instead of fighting them.

### Main task groups

- `Visual production`
  - improve environment presentation for menus and matches
  - improve robot materials, effects and damage readability
  - improve menu presentation and scene cohesion

- `Audio feedback`
  - define a sound layer for:
    - collisions
    - modular damage
    - part recovery/denial
    - pickups
    - overdrive/state changes
    - menu and pause interactions

- `Music`
  - define musical behavior for:
    - main menu
    - match
    - late-match pressure
    - pause/results

### Why these tasks belong together

"Better graphics", "sound" and "music" are not one vague polish item, but they do belong in the same production pass because they shape the same final perception of weight, clarity and finish.

### Dependencies

- depends on Milestones 2 through 5 because presentation should reinforce already-defined pacing, shell flow and learnability
- should not start as a large pass before the 1080p performance baseline from Milestone 1 is understood

### Risks and open questions

- visual polish can easily damage readability in 8-player shared-screen
- audio breadth can expand faster than the underlying event model
- music direction should follow real match pacing, not assumed pacing

### Exit criteria

- the audiovisual plan is tied to concrete gameplay and UX surfaces
- readability remains the primary rule during polish

## Milestone 7 - Integration, optimization and release-readiness

### Goal

Close the loop so the game feels coherent from main menu to match end under real multiplayer conditions.

### Main task groups

- `Optimization and stability`
  - revisit 1080p performance after the new shell, maps and presentation layers exist
  - run full regression on multi-controller, 8-player and scene-parity risks
  - identify remaining scalability bottlenecks

- `Consistency pass`
  - verify that naming, prompts, settings, menus and match feedback tell the same story
  - verify that `How to Play`, `Characters`, HUD and practice mode align

- `Production closure`
  - define what is still intentionally deferred:
    - FFA post-death rule
    - replay snippets
    - additional roster expansion
    - advanced presentation layers

### Why these tasks belong together

This milestone is about coherence. It only works after the main surfaces exist.

### Dependencies

- depends on all previous milestones

### Risks and open questions

- if optimization is left only for the end, 1080p risk can resurface too late
- if the deferred list is not explicit, scope creep will continue

### Exit criteria

- the full loop is documented as consistent
- performance and scalability risks are re-evaluated after content growth
- deferred topics are explicit instead of remaining half-open promises

## Cross-cutting recommendations

These should stay active across all milestones:

- `QA and parity`
  - keep the current discipline around `base/validation` parity
  - do not let new menus or new player-count variants create silent scene drift

- `Performance`
  - treat optimization as two passes:
    - early diagnosis in Milestone 1
    - late integration pass in Milestone 7

- `Readability`
  - if a feature cannot explain itself cleanly in shared-screen, it is not ready

- `Scope control`
  - do not expand FFA post-death, replay systems or extra roster breadth while the production shell is still being defined

## Requests that need reformulation or explicit decisions

### 1. "Make maps almost double in size"

This should be reformulated as:
- review playable scale, occupancy, traversal, route count, item spacing and pressure timing for larger matches

Reason:
- map size alone is not a useful target

### 2. "Support up to 8 players"

This needs explicit decisions for:
- target hardware
- target framerate
- joypad count assumptions
- whether all main modes and maps must support 8 equally well from the first full pass

### 3. "Any player can pause with Start"

This needs a UX contract for:
- pause ownership
- leave-match confirmation ownership
- resume authority
- simultaneous pause inputs

### 4. "How to Play" and "Characters"

These should not default to long text blocks.

Recommended structure:
- short overview text
- per-system cards
- control icons/prompts
- compact character cards
- practice-mode reinforcement

### 5. "Practice mode"

Needs an initial scope decision:
- sandbox first
- sandbox plus drills
- solo only first, or local multiplayer too

### 6. "Better graphics, sound and music"

This should be split operationally into:
- readability-first visual pass
- gameplay feedback audio pass
- mood/music pass

## Recommended priority inside the new roadmap

### Highest priority

1. Milestone 1 - Production foundation and scalability
2. Milestone 2 - Match scale, maps and spatial pacing
3. Milestone 3 - Match UX, shell and information architecture

### Medium priority

4. Milestone 4 - Roster identity, readability and character communication
5. Milestone 5 - Practice, onboarding and accessibility

### Later priority, but still required for a full game

6. Milestone 6 - Audio-visual production pass
7. Milestone 7 - Integration, optimization and release-readiness

## Immediate next planning recommendations

Before implementation begins, the next planning pass should lock:
- target hardware and target FPS for 720p and 1080p
- expected supported controller count
- pause authority rules
- first full-match player-count target to optimize around
- first map-scale target for `Teams` and `FFA`
- first-scope definition for `Practice Mode`

