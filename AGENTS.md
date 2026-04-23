# AGENTS.md — Friction Zero: Mecha Arena

## Project overview
Friction Zero: Mecha Arena is a local shared-screen top-down competitive arena game built in Godot. Players control industrial robots on floating platforms and try to eliminate rivals by pushing them off the arena or by destroying all four body parts.

This project should feel like:
- skating and colliding with precision
- heavy, industrial, readable robot combat
- strategic dismantling of enemy robots
- tactical decision-making between direct impact play and skill-based ranged influence

This project should **not** drift into:
- noisy visual chaos that hides game state
- floaty combat without weight
- spammy ability design
- unclear or overcomplicated controls in the default experience

## Core design pillars
1. **Movement** — heavy on startup, freer while sliding.
2. **Impact** — collisions matter and should feel meaningful.
3. **Wear and tear** — robots degrade over time via modular damage.
4. **Readability** — visual clarity is a hard requirement.
5. **Strategic depth with party accessibility** — easy to understand, hard to master.

## Primary player fantasy
Primary sensation:
- skate and collide with precision

Secondary sensations:
- strategically dismantle the rival
- feel heavy and industrial
- constantly weigh whether to commit to melee or use a skill/ranged option

## Match structure
- Modes:
  - Free-for-all (FFA), up to 8 players
  - Team vs Team, up to 4 vs 4
- Camera:
  - shared screen
  - almost top-down / lightly tilted top-down readability
- Arena:
  - floating platform with lethal edges
- Desired macro flow:
  - balanced opening
  - time for analysis and positioning
  - escalating pressure
  - explosive ending

## Combat philosophy
Typical duel flow should usually be:
- probing / reading
- repositioning
- decisive collision

The most exciting moments should come from:
- a perfectly timed impact
- premeditated setups
- team coordination
- readable but still surprising payoffs

The game should reward:
- opponent reading (~30%)
- resource management (~30%)
- precision (~25%)
- controlled chaos (~15%)

Chaos should preserve comeback chances, but should not dominate the design.

## Controls and difficulty modes
Two control modes are part of the game concept:

### Easy mode
- robot points in the movement direction
- aiming is tied to the main body movement
- more accessible party experience

### Hard mode
- left stick controls movement
- right stick rotates the upper torso independently
- allows more precise directional attacks and targeting

Do not design systems that only work in Hard mode unless clearly marked as advanced.

## Energy system
Each robot distributes energy among four parts:
- left arm
- right arm
- left leg
- right leg

Energy affects performance:
- legs: speed, sliding control, inertia
- arms: push strength and close-range dominance

Redistribution must be:
- meaningful
- non-spammy
- readable
- important enough to feel strategic

Overdrive is allowed as a high-risk / high-reward state:
- concentrated power on one part
- temporary advantage
- followed by penalties / overheating

## Modular damage
Each arm and leg has separate health.

Damage intent should come from a combination of:
- side of impact
- torso orientation in Hard mode
- contextual attack type

Expected visual robot anatomy logic:
- arms project more from the front
- legs are more exposed toward the rear

Losing a part must matter, but not immediately make a comeback impossible.
- losing legs usually hurts more than losing arms
- this can vary by robot archetype
- damaged robots should become mostly more clumsy, sometimes slightly more unpredictable

## Elimination systems
There are multiple elimination paths:
1. Push a robot out of the arena.
2. Destroy all four parts.
3. Use the delayed explosion of a fully disabled body as an indirect threat.

When all four parts are gone:
- robot becomes a disabled body
- it cannot act
- it can be pushed
- it explodes after a short timer
- explosion damages nearby parts and pushes outward

Optional advanced rule:
- unstable explosion if the robot was in Overdrive before destruction

Explosion-based eliminations should be rarer and feel special.

## Detached parts and recovery
Destroyed parts fall into the arena.

Rules:
- allies can recover and return parts to the original robot
- returned parts come back with partial health
- enemies can throw parts into the void for permanent denial
- pickup should be simple (touch/pass near)
- carrying a part should block other active skill use
- too many leftover parts/corpses should eventually clean up over time

Detached parts are important but secondary to positioning and collisions.

## Skills and items
Do not assume cooldown-only design.
The project explicitly supports a mixed resource model:
- some robots may have a core skill that uses ammo/charges
- the map can spawn universal items
- some one-use items can exist in smaller quantity

Item philosophy:
- only one carried item at a time
- few items, but important
- visually obvious and telegraphed
- semi-random spawn logic
- valuable pickups can appear near arena edges

Priority item types:
- ammo / charge
- mobility
- repair
- energy
- utility

Abilities should generally be:
- readable
- few on screen at once
- capable of strong repositioning if used skillfully
- not overwhelming the visual clarity of melee play

## Team vs Team identity
Must emphasize:
- coordination
- rescues
- planned attacks
- tactical pressure
- comeback potential

Helping allies recover parts should be as important as planning a coordinated attack.

A possible team-only post-death system exists in the concept:
- eliminated player ejects in a mini pilot ship outside the arena
- ship floats in the outer layer of space
- collects temporary support items
- can perform light support, tactical interference, and occasional stronger actions
- must stay visually discreet enough not to confuse living players in the main arena

## FFA identity
Must emphasize:
- survival
- opportunism
- betrayal
- repositioning
- avoiding exposure
- mixture of 1v1s and third-party interruptions

FFA should not depend on team-role interactions to be fun.

## Archetypes
The current intended archetypes are:
1. Pusher / Tank
2. Mobility / Reposition
3. Dismantler
4. Control / Zone
5. Assistance / Recovery
6. Poke / Skillshot

Each archetype should have a strong identity.
Avoid blurry archetypes unless there is a very good reason.

## Map philosophy
Maps should be mixed arenas with:
- mostly clean, open center
- more valuable and more dangerous edges
- cover spots
- repositioning routes
- possible traps depending on map identity

Desired center behavior:
- useful for escape and repositioning
- low objective value
- sometimes becomes uncomfortable if players stay too long
- may contain lower-value items

Desired edge behavior:
- stable duel zones
- tempting because of value or movement routes
- risk/reward space
- should reward skilled players more, while still tempting newer players
- should not become permanent “owned zones” for specific characters

Endgame pressure should mainly come from:
- progressive space reduction

## Visual clarity and UI
This game must remain readable for both players and spectators.

Preferred clarity rules:
- robot damage should be visible primarily through the robot body itself
  - smoke
  - sparks
  - loose pieces
  - visual wear
- HUD should be configurable:
  - explicit mode with more always-on information
  - cleaner mode where information appears contextually (damage, redistribution, overdrive, etc.)
- spectators should grasp the important state quickly even without reading many numbers

If in doubt, favor legibility over spectacle.

## Desired emotional outcomes
When players lose, they should mostly feel:
- “I almost had it.”
- “They got me well.”

The game should motivate replay, not resentment.

Post-match features may include:
- simple stats
- end-of-match replay snippets of important deaths or plays
- clear explanations of how a player lost

## Godot / implementation guidance
This project is intended for Godot and should be developed with a bias toward:
- modular systems
- readable scenes and scripts
- mechanics-first prototyping
- minimal confusion for a low-programming-skill developer

## Workflow constraints
- Do not use git worktrees unless explicitly requested.
- For documentation cleanup tasks, stay strictly within documentation and organization work unless the user explicitly asks for gameplay or code changes.
- La documentacion activa del proyecto debe escribirse en espanol. `docs/historial/` puede conservar contenido en su idioma original por tratarse de archivo historico.

When proposing code or architecture:
- preserve the core fantasy: skate and collide with precision
- preserve readability
- avoid overengineering
- do not introduce systems that require many simultaneous overlapping effects unless explicitly approved
- prefer a prototype path that validates feel quickly

## How to use the documentation folder
Before planning or coding significant features, review `docs/diseno.md` first.
If deeper historical context is needed, then consult the archived design material under `docs/historial/diseno/`.
Use the active docs as the working reference and the archived docs as supporting context.

## QA guidance
- Prefer `godot-qa` for lightweight runtime inspection and committed smoke scenarios when touching HUD, Control layout, overlays, prompts, or other clearly UI-facing contracts.
- In this repo, the usual lightweight entry checks are `godot-qa --project . doctor`, `godot-qa --project . scenario list`, and a focused `godot-qa --project . scenario run <scenario>`.
- Keep using scene-level GDScript tests as the primary source of truth for gameplay, world, camera, physics, and other contracts that `godot-qa` still does not express well.

If there is a conflict:
1. Preserve the core pillars in this `AGENTS.md`.
2. Prefer the most recent and most concrete design document.
3. Ask for clarification only if the conflict would materially change the prototype.

## Done criteria for early work
For any proposed implementation, prefer steps that:
- validate movement feel early
- validate collision feel early
- validate readability early
- keep the project playable after each step
- avoid locking the design too early before testing
