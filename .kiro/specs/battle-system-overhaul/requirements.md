# Requirements Document

## Introduction

PulseCombat is an iOS fighting game (SwiftUI + SpriteKit, iOS 17+) where real-world fitness activity powers in-game combat stats. The current battle system uses primitive SKShapeNode stick figures, a flat gray arena, bare-bones HUD, and an extremely basic CPU AI that stands idle most of the time. This overhaul replaces the entire battle experience with sprite-based character rendering, animated stages with parallax, a polished HUD, visual effects (hit sparks, screen shake, combo counters), a reactive multi-difficulty CPU AI with combo support, an improved input system with combo/special-move detection, a dynamic camera, and sound design hooks — targeting Street Fighter IV iOS-level quality.

## Glossary

- **Battle_Scene**: The SpriteKit `SKScene` subclass (`BattleScene`) that hosts all real-time combat rendering, input handling, AI, and game-loop logic.
- **Fighter_Node**: The SpriteKit node representing a single fighter character on screen, responsible for sprite animation, hitboxes, and state transitions.
- **Sprite_Sheet**: A PNG texture atlas containing sequential animation frames for a single fighter action (idle, walk, attack, block, hit, special).
- **HUD**: The heads-up display overlay rendered inside Battle_Scene showing health bars, round timer, combo counter, and special meter.
- **AI_Controller**: The subsystem within Battle_Scene that drives CPU opponent decision-making, reaction logic, combo execution, and difficulty scaling.
- **Combo_System**: The input and damage subsystem that detects sequential attack inputs within a timing window and rewards successful chains with bonus damage and visual feedback.
- **Special_Meter**: A gauge that fills as a fighter deals or receives damage, enabling a high-damage special move when full.
- **Parallax_Background**: A multi-layer scrolling stage backdrop where layers move at different speeds relative to camera position to create depth.
- **Camera_Controller**: A SpriteKit `SKCameraNode` manager that dynamically frames both fighters, zooms on key moments, and applies screen shake.
- **Input_Manager**: The subsystem that translates touch events into movement, attacks, blocks, dodges, and special-move gesture sequences.
- **VFX_Manager**: The subsystem responsible for spawning particle emitters, hit-spark sprites, and screen-shake impulses in response to combat events.
- **Sound_Manager**: The subsystem that exposes hooks for playing hit sounds, background music, announcer voice lines, and UI audio cues.
- **Difficulty_Level**: An enumeration (easy, medium, hard) that parameterizes AI_Controller behavior including reaction time, combo frequency, and aggression.

## Requirements

### Requirement 1: Sprite-Based Fighter Rendering

**User Story:** As a player, I want fighters rendered as detailed 2D animated sprites instead of primitive shapes, so that the battle feels like a polished fighting game.

#### Acceptance Criteria

1. WHEN Battle_Scene loads a fighter, THE Fighter_Node SHALL render the character using frames from a Sprite_Sheet texture atlas instead of SKShapeNode primitives.
2. THE Fighter_Node SHALL support the following animation states: idle, walk_forward, walk_backward, light_attack, heavy_attack, block, hit_stun, knockdown, special_attack, and victory.
3. WHEN the Fighter_Node transitions between animation states, THE Fighter_Node SHALL blend from the current frame to the first frame of the target animation within 0.05 seconds.
4. WHILE the Fighter_Node is in the idle state and no input is active, THE Fighter_Node SHALL loop the idle animation continuously.
5. THE Fighter_Node SHALL load all Sprite_Sheet frames from an `SKTextureAtlas` keyed by the fighter's `CharacterModel` identifier.
6. THE Fighter_Node SHALL support customizable sprite sets generated externally (e.g., via AI art tools) by loading texture atlases from the app bundle keyed by a unique fighter style identifier derived from the user's AvatarConfig.
7. IF a Sprite_Sheet atlas is missing for a given CharacterModel or style, THEN THE Fighter_Node SHALL fall back to a default generic fighter atlas and log a warning.

### Requirement 2: Stage and Parallax Background

**User Story:** As a player, I want visually rich stage backgrounds with depth, so that battles feel immersive rather than taking place on a flat gray line.

#### Acceptance Criteria

1. WHEN Battle_Scene initializes, THE Parallax_Background SHALL render at least three depth layers: a far background, a mid-ground, and a near foreground.
2. WHILE the Camera_Controller moves horizontally, THE Parallax_Background SHALL scroll each layer at a speed proportional to its depth (far layers slower, near layers faster).
3. THE Parallax_Background SHALL tile or wrap each layer seamlessly so that no visual seam or gap appears during horizontal scrolling.
4. WHEN Battle_Scene loads, THE Parallax_Background SHALL accept a stage identifier string and load the corresponding set of layer textures from the asset catalog.
5. IF a stage texture set is missing, THEN THE Parallax_Background SHALL fall back to a solid gradient background and log a warning.

### Requirement 3: Polished HUD

**User Story:** As a player, I want a clear, visually polished heads-up display showing health, time, combo count, and special meter, so that I can make informed decisions during combat.

#### Acceptance Criteria

1. THE HUD SHALL display a health bar for each fighter at the top of the screen, rendered with a gradient fill (green to yellow to red) that reflects the current health percentage.
2. WHEN a fighter takes damage, THE HUD SHALL animate the health bar decrease with a trailing "damage ghost" bar that fades over 0.3 seconds.
3. THE HUD SHALL display a round timer centered at the top of the screen, counting down from the configured round duration in whole seconds.
4. WHEN the round timer reaches 10 seconds remaining, THE HUD SHALL change the timer text color to red and pulse the text scale at 1-second intervals.
5. THE HUD SHALL display a combo counter near the attacking fighter that shows the current hit count and accumulated combo damage.
6. WHEN a combo ends (no new hit within the combo timing window), THE HUD SHALL fade out the combo counter over 0.2 seconds.
7. THE HUD SHALL display a Special_Meter bar below each fighter's health bar that fills from 0% to 100%.
8. WHEN the Special_Meter reaches 100%, THE HUD SHALL flash the meter bar and display a "READY" indicator.

### Requirement 4: Visual Effects System

**User Story:** As a player, I want hit sparks, screen shake, and flashy special-move effects, so that combat feels impactful and exciting.

#### Acceptance Criteria

1. WHEN a fighter's attack connects with the opponent, THE VFX_Manager SHALL spawn a hit-spark particle emitter at the point of contact.
2. WHEN a fighter's attack connects with the opponent, THE Camera_Controller SHALL apply a screen shake with intensity proportional to the damage dealt, lasting no longer than 0.15 seconds.
3. WHEN a fighter executes a special attack, THE VFX_Manager SHALL play a full-screen flash effect lasting 0.1 seconds followed by a unique particle trail on the attacking limb.
4. WHEN a fighter is knocked down (health reaches zero), THE VFX_Manager SHALL trigger a slow-motion effect at 0.3x speed for 0.5 seconds before the KO result displays.
5. WHEN a combo counter reaches 3 or more hits, THE VFX_Manager SHALL increase hit-spark particle count and screen shake intensity by 50% compared to a single-hit effect.
6. THE VFX_Manager SHALL use SpriteKit `SKEmitterNode` for all particle effects and reuse emitter instances from a pool to avoid frame-rate drops below 60 FPS on iPhone 13.

### Requirement 5: Reactive CPU AI with Difficulty Levels

**User Story:** As a player, I want a CPU opponent that reacts to my moves, executes combos, and scales in difficulty, so that battles are challenging and fun at every skill level.

#### Acceptance Criteria

1. THE AI_Controller SHALL support three Difficulty_Level settings: easy, medium, and hard.
2. WHEN the player executes an attack, THE AI_Controller SHALL evaluate a block-or-dodge reaction within a time window determined by Difficulty_Level (easy: 0.5 seconds, medium: 0.3 seconds, hard: 0.15 seconds).
3. WHILE the AI_Controller is in the medium or hard Difficulty_Level, THE AI_Controller SHALL execute attack combos of up to 2 hits (medium) or up to 4 hits (hard) when the opponent is in hit_stun.
4. THE AI_Controller SHALL vary its action selection using weighted probabilities that change based on Difficulty_Level (easy: 50% attack, 30% block, 20% dodge; medium: 40% attack, 25% block, 15% dodge, 20% combo; hard: 30% attack, 15% block, 10% dodge, 30% combo, 15% special).
5. WHEN the AI_Controller's fighter health drops below 30%, THE AI_Controller SHALL increase block probability by 15 percentage points and decrease attack probability by 15 percentage points (survival mode).
6. WHILE the AI_Controller is at hard Difficulty_Level, THE AI_Controller SHALL track the player's most-used action over the last 10 inputs and increase the counter-action probability by 20 percentage points.
7. THE AI_Controller SHALL enforce a minimum action cooldown per Difficulty_Level (easy: 0.4 seconds, medium: 0.25 seconds, hard: 0.1 seconds) to prevent inhuman reaction speed.
8. IF the AI_Controller's fighter is idle for more than 0.8 seconds, THEN THE AI_Controller SHALL initiate an approach or attack action to prevent passive standing.

### Requirement 6: Combo and Special Move Input System

**User Story:** As a player, I want to chain attacks into combos and perform special moves through specific input sequences, so that combat rewards skill and timing.

#### Acceptance Criteria

1. WHEN the player lands consecutive attacks within a 0.4-second window between each hit, THE Combo_System SHALL register the sequence as a combo and increment the combo counter.
2. THE Combo_System SHALL apply a damage multiplier to each successive hit in a combo: hit 1 at 1.0x, hit 2 at 1.1x, hit 3 at 1.2x, and each subsequent hit at an additional +0.1x.
3. WHEN the player inputs a specific directional sequence followed by an attack button (e.g., forward-forward-attack), THE Input_Manager SHALL recognize the input as a special move command.
4. WHEN a valid special move command is detected and the Special_Meter is at 100%, THE Fighter_Node SHALL execute the special attack animation and THE Special_Meter SHALL reset to 0%.
5. IF the Special_Meter is below 100% when a special move command is detected, THEN THE Input_Manager SHALL treat the input as a regular attack.
6. THE Special_Meter SHALL increase by 5% of its capacity for each attack that connects and by 3% of its capacity for each hit received.
7. WHEN a combo of 5 or more hits is completed, THE Combo_System SHALL award a bonus of 10% Special_Meter fill.

### Requirement 7: Dynamic Camera System

**User Story:** As a player, I want the camera to dynamically frame the action, zoom in on key moments, and keep both fighters visible, so that the battle always looks cinematic.

#### Acceptance Criteria

1. THE Camera_Controller SHALL keep both fighters visible on screen at all times by adjusting the camera position to the midpoint between the two fighters.
2. WHEN the distance between fighters decreases below 30% of the screen width, THE Camera_Controller SHALL zoom in by reducing the camera scale toward 0.85x over 0.3 seconds.
3. WHEN the distance between fighters exceeds 70% of the screen width, THE Camera_Controller SHALL zoom out by increasing the camera scale toward 1.15x over 0.3 seconds.
4. WHEN a special attack is executed, THE Camera_Controller SHALL zoom to 0.75x scale centered on the attacker for 0.4 seconds, then return to normal framing over 0.3 seconds.
5. THE Camera_Controller SHALL clamp horizontal position so that the stage boundaries are never exceeded and no empty space is visible beyond the Parallax_Background edges.
6. THE Camera_Controller SHALL apply all position and scale changes using ease-in-out interpolation to prevent jarring transitions.

### Requirement 8: Sound Design Hooks

**User Story:** As a developer, I want a centralized sound system with hooks for all combat events, so that audio can be integrated and iterated on without modifying battle logic.

#### Acceptance Criteria

1. THE Sound_Manager SHALL expose named hook methods for the following events: attack_hit, attack_blocked, attack_whiff, combo_hit, special_attack, knockdown, round_start, round_end, timer_warning, and menu_select.
2. WHEN a combat event occurs in Battle_Scene, THE Battle_Scene SHALL call the corresponding Sound_Manager hook method with the event context (e.g., damage amount, combo count).
3. THE Sound_Manager SHALL load audio files from a configurable mapping of event names to audio file names, allowing audio assets to be swapped without code changes.
4. THE Sound_Manager SHALL support simultaneous playback of up to 4 sound effects without clipping or dropping audio.
5. THE Sound_Manager SHALL provide a method to start and stop looping background music with crossfade transitions of 0.5 seconds.
6. IF an audio file referenced in the event mapping is missing, THEN THE Sound_Manager SHALL log a warning and continue without crashing.

### Requirement 9: Improved On-Screen Controls

**User Story:** As a player, I want responsive, well-designed on-screen controls that support directional input, distinct attack buttons, and special move gestures, so that I can execute moves precisely.

#### Acceptance Criteria

1. THE Input_Manager SHALL render a virtual joystick on the left side of the screen for directional movement (left, right, up for jump, down for crouch).
2. THE Input_Manager SHALL render distinct attack buttons on the right side of the screen: light attack, heavy attack, block, and special.
3. WHEN the player touches and drags the virtual joystick, THE Input_Manager SHALL report the directional vector to Battle_Scene within one frame (16.67 milliseconds at 60 FPS).
4. WHEN the player taps an attack button, THE Input_Manager SHALL register the input within one frame and provide haptic feedback using UIImpactFeedbackGenerator.
5. THE Input_Manager SHALL support multi-touch so that the player can move and attack simultaneously.
6. THE Input_Manager SHALL render all control elements with semi-transparent styling that does not obscure the fighters or HUD.
7. WHILE no touch is active on the virtual joystick, THE Input_Manager SHALL return the joystick visual to its center rest position within 0.1 seconds.

### Requirement 10: Performance and Device Compatibility

**User Story:** As a player, I want the battle to run smoothly on my device, so that gameplay is responsive and visually consistent.

#### Acceptance Criteria

1. THE Battle_Scene SHALL maintain a minimum frame rate of 60 FPS on iPhone 13 during normal combat with all VFX active.
2. THE Battle_Scene SHALL maintain a minimum frame rate of 60 FPS on iPhone 16 Pro during special attack sequences with maximum particle effects.
3. WHEN the frame rate drops below 55 FPS for more than 0.5 seconds, THE VFX_Manager SHALL reduce particle counts by 50% until the frame rate recovers above 58 FPS.
4. THE Fighter_Node SHALL use texture atlases with a maximum individual frame size of 512x512 points to balance visual quality and memory usage.
5. THE Battle_Scene SHALL consume no more than 200 MB of additional memory beyond the app baseline during an active battle.
6. WHEN Battle_Scene is dismissed, THE Battle_Scene SHALL release all texture atlases, emitter nodes, and audio resources within 1 second to prevent memory leaks.
