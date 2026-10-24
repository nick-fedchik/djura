---
name: classic-arcade-game-developer
description: >-
  Expert guidance, physics formulas, procedural pseudo-3D rendering, 2D spatial
  audio synthesis, gamepad ergonomics (XInput/Logitech F310), and game loop
  architecture for developing golden-age classic arcade games (Bomb Jack,
  Pac-Man, Donkey Kong, Galaga, Bubble Bobble) in Godot 4.x. Activate when
  designing, implementing, refactoring, or debugging retro arcade games,
  platformer physics, chiptune/synthwave audio, or arcade cabinet UI.
---

# Classic Arcade Game Developer Skill

An engineering and game-design reference for building responsive, authentic golden-age arcade games (1980–1990 era, such as *Bomb Jack*, *Pac-Man*, *Donkey Kong*, *Bubble Bobble*) modernized with Hi-Fi pseudo-3D visuals and spatial stereo audio in **Godot 4.x**.

---

## 1. Golden-Age Arcade Design Invariants

1. **Single-Screen Tactical Readability:**
   - The entire arena must be visible without camera scrolling (e.g., vertical arcade `480×640` or `224×256` aspect ratio `3:4`).
   - Strict visual luminance hierarchy:
     - **Background:** Low saturation, dark tones (`L < 0.15`).
     - **Static Geometry (Platforms/Walls):** Medium saturation with crisp top bevel highlights (`L ~ 0.50`).
     - **Interactive Entities (Hero, Bombs, Enemies, Power-Ups):** High saturation, dynamic specular highlights, and drop shadows (`L > 0.80`).
2. **Chain-Multiplier Risk/Reward Loop (*Bomb Jack* Pattern):**
   - Collectible items have two states: **Unlit (Base)** and **Lit (Active Chain)**.
   - Collecting a Lit item immediately ignites the next item in the sequence and increments the chain streak multiplier ($200 \times N$), accompanied by an ascending audio pitch shift (`pitch_scale = clamp(1.0 + (streak - 1) * 0.05, 1.0, 1.8)`).
   - Collecting an Unlit item awards base points ($100$) and resets the streak multiplier to $1$.
3. **Zero-Lag Arcade Control Feel:**
   - Horizontal ground movement reaches top speed instantaneously or within $2\text{–}3$ frames; stopping uses high deceleration (`SPEED * 8.0 * delta`).
   - Air control allows full mid-air steering without punishing momentum lock.

---

## 2. Platformer & Parkour Physics Architecture (`CharacterBody2D`)

### 2.1. Multi-Modal Gravity & Aerial Control
Classic *Bomb Jack* aerial gameplay relies on three distinct vertical physics regimes:
- **Standard Ascent/Descent:** `NORMAL_GRAVITY = 1100.0 px/s²`, `JUMP_VELOCITY = -560.0 px/s`.
- **Flutter / Gliding (Wingsuit / Cape Spread):**
  - Triggered while falling (`velocity.y > 0`) by holding or tapping `jump`.
  - Tap impulse arrests descent (`velocity.y = min(velocity.y, 0.0) + FLAP_BOOST` where `FLAP_BOOST = -90.0`).
  - Hold state smoothly clamps terminal velocity to `GLIDE_FALL_SPEED = 75.0 px/s`.
- **Fast Drop (Aerodynamic Dive):**
  - Triggered in mid-air by pressing `move_down`.
  - Immediately forces `velocity.y = max(velocity.y, FAST_DROP_SPEED)` (`650.0 px/s`).
- **One-Way Platform Pass-Through:**
  - Platforms use `CollisionShape2D.one_way_collision = true`.
  - Pressing `move_down + jump` while grounded increments `position.y += 4.0` to drop cleanly through the platform.

### 2.2. Biomechanical Landing Absorption (Squat vs. Parkour Roll)
Track `prev_velocity_y = velocity.y` immediately prior to `move_and_slide()`. Upon ground contact (`is_on_floor() and not was_on_floor`):
- **High-Impact Threshold (`prev_velocity_y > 330.0`):**
  - **Vertical Fall (`abs(velocity.x) <= 40.0`):** Trigger a **3-Point Absorption Squat** (`squash_stretch = Vector2(1.52, 0.48)`, `squat_timer = 0.24s`), planting one hand on the platform.
  - **Directional Fall (`abs(velocity.x) > 40.0`):** Trigger a **360° Parkour Safety Roll** (`is_rolling = true`, `roll_duration = 0.36s`), rotating `body_tilt` through `TAU` in `facing_direction` while boosting horizontal speed (`SPEED * 1.15`).
- **Low-Impact Hop (`prev_velocity_y <= 330.0`):** Apply subtle elastic squash (`Vector2(1.22, 0.82)`).

---

## 3. Procedural Pseudo-3D Vector Rendering (`CanvasItem._draw`)

Avoid flat 2D rectangles; render entities with volumetric depth cues directly in `_draw()`:

1. **Spherical Iso-Luminance Raytracing (for Bombs, Orbs, Heads):**
   - Define a normalized light source vector from top-left (e.g., `light_offset = Vector2(-0.36, -0.36) * radius`).
   - Render $8\text{–}10$ concentric circles interpolating center from `sphere_center` toward `sphere_center + light_offset` and radius from $R$ down to $0.15R$, blending colors from charcoal shadow $\to$ midtone $\to$ specular highlight.
   - Add a **Fresnel Rim Arc** (`draw_arc`) along the bottom-right edge (`0.2..2.1 rad`) and a 4-point star glint that twinkles periodically.
2. **Cylindrical Limb & Cloth Shading:**
   - Render torsos, boots, and sleeves with 3-tone shading: dark shadow on the trailing edge, midtone body polygon, and bright specular line on the leading edge.
   - Use double-sided polygons for capes/mantles (distinct outer color and inner lining revealed during movement waves).
3. **Dynamic Altitude Drop Shadows:**
   - Project a two-tier semi-transparent oval shadow (`alpha = 0.38` outer, `alpha = 0.55` inner) onto the surface below. Scale shadow radius inversely with hover/jump height.

---

## 4. Hi-Fi Retro Audio Synthesis & Spatial Stereo

1. **Positional 2D Stereo Field:**
   - Place an `AudioListener2D` (`current = true`) at the exact center of the arena (`Vector2(240, 320)`).
   - Emit player and collectible SFX via ephemeral `AudioStreamPlayer2D` nodes (`max_distance = 1500.0`, `attenuation = 0.3`) spawned at the exact event coordinates (`bomb.global_position`).
2. **Arcade Cabinet Acoustic Bus (`default_bus_layout.tres`):**
   - Attach `AudioEffectLowPassFilter` (`cutoff_hz = 13500.0`) on the `Master` bus to roll off harsh digital aliasing and emulate warm paper-cone arcade speakers.
   - Attach `AudioEffectLimiter` (`ceiling_db = -0.5`) to prevent clipping during multi-channel polyphony.
3. **Seamless BGM & Victory Transitions:**
   - Normalize generated `.wav` tracks to `-0.7 dB` (`0.92` peak amplitude).
   - Set `edit/loop_mode=1` and `compress/mode=0` (lossless PCM) in `.wav.import` for background music.
   - Mount `BGMPlayer` directly in the main scene with `autoplay = true`. On stage clear, immediately call `bgm_player.stop()`, play the non-looping victory track, and resume `bgm_player.play()` when the next stage spawns.

---

## 5. Display & Controller Ergonomics (2K & XInput)

1. **2K (2560×1440) Integer Scaling & Cabinet Mode:**
   - Base viewport: `480×640`. Window override: `960×1280` (exact $2\times$ integer scale).
   - Stretch mode: `canvas_items`, aspect: `keep` (automatically pillarboxes in fullscreen).
   - Bind `toggle_fullscreen` to `F11` and Joypad Button 4 (`Back`/`Select`), and `KEY_ESCAPE` to exit fullscreen.
2. **XInput Gamepad (Logitech F310) Mapping:**
   - Map `move_left` / `move_right` to both D-Pad (`button_index` 13/14) and Left Stick X (`axis 0`, `deadzone = 0.3`) read via `Input.get_axis("move_left", "move_right")`.
   - Map `move_down` to D-Pad Down (`button_index` 12) and Left Stick Y (`axis 1`, `+1.0`).
   - Map `jump` to Face Buttons `A`, `B`, `X` (`button_index` 0, 1, 2).

---

## 6. Headless Verification Workflow

Always validate scene integrity, class caches, and script compilation via CLI before concluding any task:
```bash
# 1. Reimport assets and update global class cache:
godot --headless --editor --path <project_dir> --quit

# 2. Run 25 physics frames headlessly to verify zero parse/runtime errors:
godot --headless --path <project_dir> --quit-after 25
```
