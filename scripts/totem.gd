class_name Totem
extends Node2D

## The run's only damage source. Lifecycle: INERT (retrievable on the ground)
## -> HELD (by the player, hidden, during charge-up) -> FLYING (to the throw
## point) -> ACTIVE (autofires at the nearest enemy until charges run out)
## -> INERT again at its landing spot. It never auto-recalls; the player must
## come back for it. Single target only — AOE/chaining/multiple totems are
## future augments and intentionally not supported here.

@export var projectile_scene: PackedScene
## Shots fired per placement before the totem goes inert.
@export var max_charges := 6
## Radius (pixels) of the pickup circle drawn around the totem. Standing
## anywhere inside it lets the player grab the totem, mid-hop or not.
@export var pickup_radius := 96.0
## Matches HopMovement.launch_duration so player and totem land together.
@export var flight_duration := 0.3

enum State { INERT, HELD, FLYING, ACTIVE }

## Set by Main. Fire rate and damage come from attack_speed / attack_damage.
var stats: PlayerStats
## Set by Main; searched for the nearest enemy when firing.
var enemy_container: Node2D

var state := State.INERT
var charges := 0

var _cooldown := 0.0
var _fly_target := Vector2.ZERO
var _fly_velocity := Vector2.ZERO
var _fly_time_left := 0.0

@onready var visual: Polygon2D = $Visual
@onready var charges_label: Label = $ChargesLabel


func _ready() -> void:
	_update_appearance()


func can_pick_up(body: Node2D) -> bool:
	return state == State.INERT \
		and body.global_position.distance_to(global_position) <= pickup_radius


func hold(holder: Node2D) -> void:
	global_position = holder.global_position
	state = State.HELD
	_update_appearance()


func fly_to(point: Vector2) -> void:
	_fly_target = point
	_fly_time_left = flight_duration
	_fly_velocity = (point - global_position) / flight_duration
	state = State.FLYING
	_update_appearance()


func _physics_process(delta: float) -> void:
	match state:
		State.FLYING:
			global_position += _fly_velocity * delta
			_fly_time_left -= delta
			if _fly_time_left <= 0.0:
				global_position = _fly_target
				_activate()
		State.ACTIVE:
			_cooldown -= delta
			if _cooldown <= 0.0:
				_try_fire()


func _activate() -> void:
	state = State.ACTIVE
	charges = max_charges
	_cooldown = 0.0
	_update_appearance()


func _try_fire() -> void:
	var target := _nearest_enemy()
	if target == null:
		return # no enemy yet — keep the charge and retry next frame

	var projectile: Projectile = projectile_scene.instantiate()
	var container := get_tree().get_first_node_in_group("projectile_container")
	if container == null:
		container = get_tree().current_scene
	container.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = global_position.direction_to(target.global_position)
	projectile.damage = stats.attack_damage

	_cooldown = stats.attack_interval()
	charges -= 1
	if charges <= 0:
		state = State.INERT
	_update_appearance()


func _nearest_enemy() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for child in enemy_container.get_children():
		if child is Enemy:
			var d: float = global_position.distance_squared_to(child.global_position)
			if d < nearest_distance:
				nearest_distance = d
				nearest = child
	return nearest


func _update_appearance() -> void:
	visible = state != State.HELD
	match state:
		State.INERT:
			visual.color = Color(0.5, 0.45, 0.4)
			charges_label.text = ""
		State.FLYING:
			visual.color = Color(0.95, 0.75, 0.2)
			charges_label.text = ""
		State.ACTIVE:
			visual.color = Color(0.95, 0.75, 0.2)
			charges_label.text = str(charges)
	queue_redraw()


func _draw() -> void:
	# Pickup circle, always visible on the totem. Green while inert (ready to
	# grab), dim otherwise so it still reads as the totem's footprint.
	var ring := Color(0.4, 0.9, 0.5, 0.55) if state == State.INERT else Color(1, 1, 1, 0.15)
	draw_arc(Vector2.ZERO, pickup_radius, 0.0, TAU, 64, ring, 1.5)
