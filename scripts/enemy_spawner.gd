class_name EnemySpawner
extends Node

## Spawns enemies in a ring around the player. Spawn interval shrinks over the
## run and the per-tick spawn count rises, so pressure ramps up over time.
## A second enemy type can be supported by swapping/weighting `enemy_scene`.

signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
@export var player: Node2D
@export var enemy_container: Node2D
@export var base_interval := 2.0
@export var min_interval := 0.4
## Interval is multiplied by this factor for every 30 seconds elapsed.
@export var interval_decay_per_30s := 0.9
## One extra enemy per spawn tick for each full minute elapsed, up to this cap.
@export var max_spawn_count := 4
@export var spawn_distance := 600.0

var _elapsed := 0.0
var _spawn_timer := 0.0


func _process(delta: float) -> void:
	_elapsed += delta
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var count: int = mini(1 + int(_elapsed / 60.0), max_spawn_count)
		for i in count:
			_spawn_one()
		_spawn_timer = current_interval()


func current_interval() -> float:
	return maxf(min_interval, base_interval * pow(interval_decay_per_30s, _elapsed / 30.0))


func _spawn_one() -> void:
	if not is_instance_valid(player):
		return
	var enemy: Enemy = enemy_scene.instantiate()
	enemy_container.add_child(enemy)
	enemy.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * spawn_distance
	enemy.target = player
	enemy_spawned.emit(enemy)
