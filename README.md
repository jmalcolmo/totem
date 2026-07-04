# jul3 — top-down 2D roguelike prototype

Godot 4.x (GDScript) sandbox prototype: free-movement player, auto-firing weapon
aimed at the mouse, escalating enemy spawns, XP/level system, and a 3-choice
upgrade menu on level up.

## Run

Open the project in Godot 4.x and press F5. Main scene is `scenes/main.tscn`.

## Controls

- **WASD / arrow keys** — move
- **Mouse** — aim (weapon fires automatically)

## Structure

- `scenes/` — one scene per game object (`main`, `player`, `weapon`, `projectile`, `enemy`, `xp_pickup`, `hud`, `upgrade_menu`)
- `scripts/` — matching scripts, plus `player_stats.gd` (shared stat resource), `upgrade_pool.gd` (upgrade definitions), `enemy_spawner.gd`

## Branches

- `dev` — active development
- `prod` — promoted stable builds
