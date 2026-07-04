class_name Weapon
extends Node2D

## Base auto-firing weapon: fires a projectile toward the mouse cursor at an
## interval driven by the owner's PlayerStats. A second weapon can be added by
## instancing another scene with its own script that also reads `stats`.

@export var projectile_scene: PackedScene

var stats: PlayerStats

var _cooldown := 0.0


func _process(delta: float) -> void:
	if stats == null:
		return
	_cooldown -= delta
	if _cooldown <= 0.0:
		_fire()
		_cooldown = stats.attack_interval()


func _fire() -> void:
	var direction := global_position.direction_to(get_global_mouse_position())
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	var projectile: Projectile = projectile_scene.instantiate()
	var container := get_tree().get_first_node_in_group("projectile_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.damage = stats.attack_damage
