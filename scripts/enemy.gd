class_name Enemy
extends CharacterBody2D

signal died(xp_value: int, death_position: Vector2)

@export var max_hp := 20.0
@export var move_speed := 90.0
@export var contact_damage := 8.0
@export var damage_interval := 0.8 # seconds between contact damage ticks
@export var xp_value := 4

## Node the enemy seeks. Set by the spawner; if it becomes invalid the enemy idles.
var target: Node2D

var hp: float
var _dead := false
var _damage_cooldown := 0.0

@onready var damage_area: Area2D = $DamageArea


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	if is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * move_speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	_damage_cooldown -= delta
	if _damage_cooldown <= 0.0:
		for body in damage_area.get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(contact_damage)
				_damage_cooldown = damage_interval
				break


func take_damage(amount: float) -> void:
	if _dead:
		return
	hp -= amount
	if hp <= 0.0:
		_dead = true
		died.emit(xp_value, global_position)
		queue_free()
