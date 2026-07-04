# totem — hop + totem roguelike prototype

Godot 4.x (GDScript) prototype built on the generic roguelike base (enemy
spawning, HP, XP pickups, leveling, upgrade menu), with two replacement
systems: hop-based movement and totem/javelin combat. The player has no
personal attack — the totem is the only source of damage.

## Run

Open the project in Godot 4.x and press F5. Main scene is `scenes/main.tscn`.

## Controls

Mouse and analog stick are both supported; a tilted left stick acts as a
virtual cursor around the player.

- **Cursor inside inner ring** — stand still
- **Cursor between the rings** — slow walk (fine adjustment)
- **Cursor past outer ring** — hop toward the cursor; hop distance scales
  with how far past the ring the cursor is, up to the move speed stat.
  Direction only changes between hops; no landing lag between chained hops.
- **Pick up totem** — stand still (cursor in inner ring) within pickup range
  of the inert totem; pickup and charge-up start automatically. You are
  locked in place and fully vulnerable while charging.
- **Left click / gamepad bottom button (`throw`)** — release the throw. The
  totem flies to the arrow tip and you are launched to the same spot.

Once placed, the totem autofires at the nearest enemy until its charges run
out, then goes inert (gray) where it landed. Hop back and stand next to it to
retrieve it.

## Systems / tuning

- `scripts/hop_movement.gd` — movement only. Ring radii, hop duration, walk
  speed, and overshoot-to-max-hop mapping are exported on the node. Max hop
  distance = `move_speed` stat.
- `scripts/totem.gd` + `scripts/totem_controller.gd` — combat only. Charges
  per placement (`max_charges`, default 6), pickup range, flight duration,
  charge time, and min throw distance are exported. Fire rate/damage come
  from the `attack_speed` / `attack_damage` stats; max throw distance from
  the `throw_distance` stat (no upgrade wired yet).
- `scripts/aim_input.gd` — shared mouse/stick aim helper used by both.

The two systems only touch through `HopMovement.launch_to()` (the throw
launch) and `Player.control_locked` (the charge lock), so augments can hook
into either independently.

## Structure

- `scenes/` — one scene per game object (`main`, `player`, `totem`,
  `projectile`, `enemy`, `xp_pickup`, `hud`, `upgrade_menu`)
- `scripts/` — matching scripts, plus `player_stats.gd` (shared stat
  resource), `upgrade_pool.gd` (upgrade definitions), `enemy_spawner.gd`,
  `hop_movement.gd`, `totem_controller.gd`, `aim_input.gd`

## Branches

- `dev` — active development
- `prod` — promoted stable builds
