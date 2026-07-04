# Base Engine Spec (jul3)

Reference for the generic top-down roguelike engine in the sibling `jul3`
folder — the reusable base that this `totem` project (and future prototypes)
is copied from. The `jul3` folder itself is never modified; it stays a clean,
reusable starting point.

This document describes the **base** as it ships in `jul3`. Where `totem` has
since replaced a base system, that is called out in
[What totem replaces](#what-totem-replaces) at the end — everything above that
section is the untouched base.

- **Engine:** Godot 4.x (project marked feature `4.7`), GDScript only.
- **Main scene:** `res://scenes/main.tscn`.
- **Genre loop:** free-move player, auto-firing weapon aimed at the cursor,
  ring-spawned enemies that seek the player, XP drops, leveling, and a
  3-choice upgrade menu on level up.

---

## File / scene structure

One scene per game object under `scenes/`, each with a matching script under
`scripts/`. Scripts that are instanced/looked-up by others use `class_name`.

```
scenes/
  main.tscn          Root orchestrator scene (see tree below)
  player.tscn        CharacterBody2D + Weapon + Camera2D
  weapon.tscn        Node2D auto-fire weapon, holds projectile_scene
  projectile.tscn    Area2D bullet
  enemy.tscn         CharacterBody2D seeker + DamageArea
  xp_pickup.tscn     Area2D XP gem
  hud.tscn           CanvasLayer HUD (HP/XP bars, level, timer)
  upgrade_menu.tscn  CanvasLayer level-up choice UI
scripts/
  main.gd            (extends Node2D)          run orchestrator
  player.gd          class_name Player         movement, HP, XP, leveling
  player_stats.gd    class_name PlayerStats    the six stats (Resource)
  weapon.gd          class_name Weapon         auto-fire toward cursor
  projectile.gd      class_name Projectile     travels, deals damage, expires
  enemy.gd           class_name Enemy          seeks player, contact damage
  enemy_spawner.gd   class_name EnemySpawner   ring spawns, ramping pressure
  xp_pickup.gd       class_name XpPickup       grants XP on pickup
  upgrade_pool.gd    class_name UpgradePool    upgrade defs + apply logic
  upgrade_menu.gd    class_name UpgradeMenu    presents 3 choices
  hud.gd             (extends CanvasLayer)     binds HUD to player signals
```

### `main.tscn` node tree

```
Main (Node2D, main.gd)
├── Player (instance of player.tscn)
├── Projectiles (Node2D, group "projectile_container")   ← projectiles reparent here
├── Enemies (Node2D)                                       ← enemy container
├── Pickups (Node2D)                                       ← XP gems container
├── EnemySpawner (Node, enemy_spawner.gd)                  ← node_paths: player, enemy_container
├── HUD (instance of hud.tscn)
├── UpgradeMenu (instance of upgrade_menu.tscn)
└── GameOverLayer (CanvasLayer, process_mode = Always, hidden)
    └── … Dim / CenterContainer / "Game Over" / RestartButton (%RestartButton)
```

### `player.tscn` node tree

```
Player (CharacterBody2D, player.gd; layer 1, mask 2, motion_mode = Floating)
├── Visual (Polygon2D, blue square)
├── CollisionShape2D (CircleShape2D r=12)
├── Weapon (instance of weapon.tscn)
└── Camera2D
```

Enemy, projectile, and pickup scenes are each a root physics node plus a
`Polygon2D` visual and a collision shape; the enemy additionally has a child
`DamageArea` (Area2D, larger radius) used for contact damage.

---

## The six stats and how they're wired

All run-time tuning lives in **`player_stats.gd`** (`class_name PlayerStats`,
`extends Resource`). It is the single source of truth read *live* by the
player and weapon, so upgrades that mutate it apply immediately.

| Stat            | Base default | Read by            | Effect |
|-----------------|--------------|--------------------|--------|
| `move_speed`    | 220.0        | `player.gd`        | `velocity = input_dir * move_speed` in `_physics_process` |
| `max_hp`        | 100.0        | `player.gd`, HUD   | HP ceiling; `hp` initialized to it in `_ready` |
| `hp_regen`      | 0.0 (HP/s)   | `player.gd`        | `hp += hp_regen * delta` each frame, clamped to `max_hp` |
| `armor`         | 0.0          | `player.gd`        | `take_damage` = `max(amount - armor, 1.0)` (always ≥1) |
| `attack_damage` | 10.0         | `weapon.gd`        | copied to each spawned `projectile.damage` |
| `attack_speed`  | 1.25 (shots/s)| `weapon.gd`       | fire cooldown = `attack_interval()` = `1.0 / attack_speed` |

`PlayerStats.attack_interval()` is the only helper on the resource:
`return 1.0 / attack_speed`.

### Wiring / ownership

- `Player` owns the resource: `@export var stats: PlayerStats`. In the scene
  no `.tres` is assigned, so `_ready()` does
  `if stats == null: stats = PlayerStats.new()` — **each run starts with a
  fresh stats object at the script defaults** (no persistence between runs).
- `Player._ready()` hands the same reference to the weapon: `weapon.stats =
  stats`. Because it's a `Resource` (reference type), the weapon and player
  read the *same* object; mutating it from upgrades is seen everywhere at once.
- To add a new upgradeable number, add an `@export` on `PlayerStats`, read it
  live from the relevant system, and handle its id in `UpgradePool`.

### Upgrade path

`upgrade_pool.gd` (`class_name UpgradePool`, `extends RefCounted`, all static)
defines the six upgrades in `UPGRADES` (id / name / description) and applies
them in `apply(id, player)`:

| id              | apply() effect                          |
|-----------------|-----------------------------------------|
| `attack_speed`  | `stats.attack_speed *= 1.15` (+15%)     |
| `attack_damage` | `stats.attack_damage += 5.0`            |
| `max_hp`        | `stats.max_hp += 20.0` and `player.heal(20.0)` |
| `hp_regen`      | `stats.hp_regen += 1.0`                 |
| `move_speed`    | `stats.move_speed *= 1.10` (+10%)       |
| `armor`         | `stats.armor += 1.0`                    |

- All options are equally weighted and repeatable.
- `UpgradePool.roll(count)` shuffles a copy of `UPGRADES` and returns the
  first `count` (main rolls 3).
- Unknown ids fall through to `push_warning`.

---

## System-by-system notes

### Player (`player.gd`)
- Signals: `health_changed(current, max_hp)`, `xp_changed(xp, xp_required)`,
  `leveled_up(new_level)`, `died`. HUD and Main subscribe.
- `_physics_process`: reads `Input.get_vector("move_left","move_right",
  "move_up","move_down")` for movement, then applies HP regen.
- `take_damage(amount)`: subtracts `armor` (min 1 damage), emits
  `health_changed`, emits `died` once at `hp <= 0` (guarded by `_dead`).
- Leveling: `gain_xp(amount)` uses a `while xp >= xp_required()` loop so a
  single large XP gain can grant multiple levels. `xp_required()` returns
  `10 + level * 5`.

### Weapon (`weapon.gd`)
- `@export var projectile_scene: PackedScene`; reads `stats` (set by player).
- `_process`: counts down `_cooldown`; on expiry fires and resets to
  `stats.attack_interval()`.
- `_fire()`: aims at `get_global_mouse_position()`, instances a projectile,
  and parents it to the node in group **`projectile_container`** (falls back to
  the current scene) so bullets live independent of the moving weapon. Sets the
  projectile's `direction` and `damage` (= `attack_damage`).
- Extension point (per code comment): a second weapon = another Node2D scene
  whose script also reads `stats`.

### Projectile (`projectile.gd`, Area2D)
- `speed = 500`, `lifetime = 2.0`. Moves along `direction`, self-frees at
  lifetime end. On `body_entered`, if the body `has_method("take_damage")` it
  deals `damage` and frees itself (single-hit).

### Enemy (`enemy.gd`, CharacterBody2D)
- Exports: `max_hp 20`, `move_speed 90`, `contact_damage 8`,
  `damage_interval 0.8`, `xp_value 4`.
- Seeks `target` (set by the spawner) each physics frame; idles if the target
  becomes invalid.
- Contact damage via a child `DamageArea`: every `damage_interval`, damages one
  overlapping body that `has_method("take_damage")`.
- Signal `died(xp_value, death_position)` emitted on death, then `queue_free`.

### Enemy spawner (`enemy_spawner.gd`, Node)
- Exports: `enemy_scene`, `player`, `enemy_container`, `base_interval 2.0`,
  `min_interval 0.4`, `interval_decay_per_30s 0.9`, `max_spawn_count 4`,
  `spawn_distance 600`.
- Difficulty ramp: spawn interval = `base_interval * decay^(elapsed/30s)`
  clamped to `min_interval`; per-tick spawn count = `1 + floor(elapsed/60s)`
  capped at `max_spawn_count`.
- Spawns on a ring of radius `spawn_distance` around the player, sets each
  enemy's `target`, and emits `enemy_spawned(enemy)`.

### XP pickup (`xp_pickup.gd`, Area2D)
- On `body_entered`, if the body `has_method("gain_xp")` grants `xp_value` and
  frees itself.

### HUD (`hud.gd`, CanvasLayer)
- `setup(player)` connects to the player's health/xp/level signals and seeds
  initial values. Uses `%`-unique nodes: `%HpBar`, `%XpBar`, `%LevelLabel`,
  `%TimeLabel`. Runs a wall-clock run timer in `_process`.

### Upgrade menu (`upgrade_menu.gd`, CanvasLayer)
- `open(new_level, options)` builds one `Button` per option and shows itself;
  emits `upgrade_chosen(id)` when clicked. Set to process while the tree is
  paused so it works during the level-up pause.

### Main orchestrator (`main.gd`, Node2D)
- Wires everything by signal in `_ready`: `hud.setup(player)`, player
  `leveled_up`/`died`, spawner `enemy_spawned`, menu `upgrade_chosen`, and the
  restart button.
- Enemy death → instances an `XpPickup` (preloaded) at the death position into
  `Pickups`.
- Level-up flow: level-ups queue into `_pending_level_ups`; each pauses the
  tree (`get_tree().paused = true`) and opens the menu with `UpgradePool.roll(3)`.
  On choice, `UpgradePool.apply` mutates stats, then either unpauses or shows
  the next queued choice (handles multi-level gains).
- Death → pause + show `GameOverLayer`. Restart → unpause +
  `reload_current_scene()`.

---

## Cross-cutting conventions

- **Stats as a shared Resource.** One `PlayerStats` instance is referenced by
  player and weapon; mutate it to change behavior live. No `.tres` on disk, so
  runs always start at the script defaults.
- **Signal-up / orchestrate-in-Main.** Game objects emit signals; `Main`
  connects them and owns cross-object flow and pause state. HUD only listens.
- **Duck-typed combat.** Damage and XP use `has_method("take_damage")` /
  `has_method("gain_xp")` rather than type checks, so anything can opt in.
- **Container groups / node paths.** Projectiles reparent to the
  `projectile_container` group; the spawner takes explicit `player` /
  `enemy_container` node paths. Keep these wired when restructuring `main.tscn`.
- **Pause model.** `get_tree().paused` drives level-up and game-over stops;
  the menu and game-over layers process while paused.

### Physics layers (`project.godot`)

| Bit | Name        | Used by |
|-----|-------------|---------|
| 1   | player      | Player body |
| 2   | enemies     | Enemy bodies |
| 3   | projectiles | Projectile areas |
| 4   | pickups     | XP pickup areas |

Player: layer 1, mask 2. Enemy: layer 2, mask 3 (player + enemies).
Projectile: layer 4, mask 2. XP pickup: layer 8, mask 1.

### Input actions (base)

`move_left` / `move_right` / `move_up` / `move_down`, each bound to WASD **and**
arrow keys, deadzone 0.2. (These are the only gameplay actions in the base.)

### Documented extension points

- Second **weapon**: instance another Node2D whose script also reads `stats`.
- Second **enemy type**: swap/weight `enemy_scene` on the spawner.
- New **upgrade**: append to `UpgradePool.UPGRADES` and handle its id in
  `apply()`; add a backing `@export` on `PlayerStats` if it needs state.

---

## What totem replaces

This `totem` project keeps the base loop (spawning, HP, XP, leveling, upgrade
UI) but swaps two systems and repurposes stats. When treating `jul3` as the
base, expect these to differ here:

- **Movement:** free WASD in `player.gd` → hop-based movement
  (`hop_movement.gd`, aim-distance rings). `move_speed` now means *max hop
  distance*; the WASD input actions are removed in favor of a `throw` action.
- **Combat:** the auto-fire `Weapon`/`weapon.tscn` → the totem/javelin system
  (`totem.gd` + `totem_controller.gd`); the player has no personal attack.
  `attack_speed` / `attack_damage` now drive the totem.
- **Additions (not in base):** `aim_input.gd` (shared mouse/stick aim),
  `background_grid.gd` (visual grid), `xp_collector.gd` (invisible XP pickup
  radius on the player, replacing touch-based XP pickup).

See `README.md` for totem's current controls and tuning.
