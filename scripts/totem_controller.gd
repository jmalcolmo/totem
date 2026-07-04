class_name TotemController
extends Node2D

## Player-side half of the totem system. The player picks the totem up by
## pressing "throw" while standing still inside its pickup range, which starts
## the charge-up: the player is locked in place and fully vulnerable (the
## game's only vulnerability window by design) while the aim arrow grows toward
## the cursor. Pressing "throw" again releases: the totem flies to the arrow
## tip and the player is launched to the same landing point via HopMovement
## (its one contact point with the movement system).

@export var player: Player
@export var hop_movement: HopMovement
## Time for the aim arrow to grow from min to max throw distance.
@export var charge_time_to_max := 1.2
@export var min_throw_distance := 80.0

## Set by Main.
var totem: Totem

var _charging := false
var _charge_time := 0.0


func _physics_process(delta: float) -> void:
	if _charging:
		_process_charge(delta)
	else:
		_try_pickup()
	queue_redraw()


func _try_pickup() -> void:
	if totem == null or not hop_movement.is_stationary():
		return
	if not Input.is_action_just_pressed("throw"):
		return
	if totem.can_pick_up(player):
		totem.hold(player)
		player.control_locked = true
		_charging = true
		_charge_time = 0.0


func _process_charge(delta: float) -> void:
	_charge_time += delta
	if Input.is_action_just_pressed("throw"):
		_release()


func throw_distance_now() -> float:
	var t := clampf(_charge_time / charge_time_to_max, 0.0, 1.0)
	return lerpf(min_throw_distance, player.stats.throw_distance, t)


func _release() -> void:
	var target := player.global_position \
		+ AimInput.aim_direction(player) * throw_distance_now()
	totem.fly_to(target)
	hop_movement.launch_to(target)
	player.control_locked = false
	_charging = false


func _draw() -> void:
	if not _charging:
		return
	var direction := AimInput.aim_direction(player)
	var tip := direction * throw_distance_now()
	var color := Color(0.95, 0.75, 0.2, 0.9)
	draw_line(Vector2.ZERO, tip, color, 2.0)
	var side := direction.orthogonal() * 6.0
	draw_polygon(
		PackedVector2Array([tip + direction * 12.0, tip + side, tip - side]),
		PackedColorArray([color])
	)
