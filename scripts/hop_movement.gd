class_name HopMovement
extends Node2D

## Hop-based movement driven by how far the aim point is from the player.
## Aim inside the inner ring: stand still. Between the rings: capped slow
## walk for fine adjustment. Past the outer ring: hop toward the aim, with
## distance scaling by overshoot up to the move_speed stat. Direction locks
## at takeoff and landing chains straight into the next hop (no landing lag).
## No i-frames: the player can be hit mid-hop. Draws both rings for reference.
## Combat only touches this system through launch_to().

@export var player: Player

@export var inner_radius := 40.0
@export var outer_radius := 110.0
## Aiming this many pixels past the outer ring gives the max-distance hop.
@export var overshoot_for_max_hop := 200.0
@export var min_hop_distance := 60.0
@export var hop_duration := 0.7
@export var walk_speed := 70.0
## Matches Totem.flight_duration so player and totem land together on a throw.
@export var launch_duration := 0.3

enum State { GROUNDED, HOPPING, LAUNCHING }

var _state := State.GROUNDED
var _air_velocity := Vector2.ZERO
var _air_time_left := 0.0


func is_grounded() -> bool:
	return _state == State.GROUNDED


## Immediately cancels any in-progress hop/launch and grounds the player. Used
## by the totem pickup so grabbing the totem interrupts a hop mid-air.
func force_ground() -> void:
	_state = State.GROUNDED
	_air_time_left = 0.0
	player.velocity = Vector2.ZERO


## Max hop distance in pixels; this is what the move speed stat now controls.
func max_hop_distance() -> float:
	return player.stats.move_speed


## Throw launch: pulls the player to `point` alongside the flying totem.
## Replaces a hop for that movement beat; no steering mid-flight.
func launch_to(point: Vector2) -> void:
	_state = State.LAUNCHING
	_air_time_left = launch_duration
	_air_velocity = (point - player.global_position) / launch_duration


func _physics_process(delta: float) -> void:
	match _state:
		State.GROUNDED:
			_process_grounded()
		State.HOPPING, State.LAUNCHING:
			_process_airborne(delta)
			if _state == State.GROUNDED:
				_process_grounded() # no landing lag: next hop can start this frame
	queue_redraw()


func _process_grounded() -> void:
	if player.control_locked:
		player.velocity = Vector2.ZERO
		return
	var aim := AimInput.aim_offset(player)
	var aim_length := aim.length()
	if aim_length <= inner_radius:
		player.velocity = Vector2.ZERO
	elif aim_length <= outer_radius:
		player.velocity = aim.normalized() * walk_speed
		player.move_and_slide()
	else:
		_start_hop(aim.normalized(), aim_length - outer_radius)


func _start_hop(direction: Vector2, overshoot: float) -> void:
	var t := clampf(overshoot / overshoot_for_max_hop, 0.0, 1.0)
	var distance := lerpf(min_hop_distance, max_hop_distance(), t)
	_state = State.HOPPING
	_air_time_left = hop_duration
	_air_velocity = direction * (distance / hop_duration)


func _process_airborne(delta: float) -> void:
	player.velocity = _air_velocity
	player.move_and_slide()
	_air_time_left -= delta
	if _air_time_left <= 0.0:
		_state = State.GROUNDED
		player.velocity = Vector2.ZERO


func _draw() -> void:
	draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 48, Color(1, 1, 1, 0.15), 1.5)
	draw_arc(Vector2.ZERO, outer_radius, 0.0, TAU, 64, Color(1, 1, 1, 0.25), 1.5)
