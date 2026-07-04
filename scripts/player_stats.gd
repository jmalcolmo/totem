class_name PlayerStats
extends Resource

## Mutable run-time stats for the player. Upgrades modify these directly;
## systems (player, weapon) read them live so changes apply immediately.

@export var move_speed: float = 220.0
@export var max_hp: float = 100.0
@export var hp_regen: float = 0.0 # HP per second
@export var armor: float = 0.0 # flat damage reduction per hit (min 1 damage taken)
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.25 # shots per second


func attack_interval() -> float:
	return 1.0 / attack_speed
