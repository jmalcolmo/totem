class_name Player
extends CharacterBody2D

## HP/XP/level owner. Movement lives in the HopMovement child node and all
## damage output lives in the totem system — the player has no attack.

signal health_changed(current: float, max_hp: float)
signal xp_changed(xp: int, xp_required: int)
signal leveled_up(new_level: int)
signal died

@export var stats: PlayerStats

var hp: float
var level: int = 1
var xp: int = 0

## Set by TotemController during the throw charge-up; HopMovement reads it and
## holds the player in place. This is the game's only vulnerability window.
var control_locked := false

var _dead := false


func _ready() -> void:
	if stats == null:
		stats = PlayerStats.new()
	hp = stats.max_hp
	health_changed.emit(hp, stats.max_hp)
	xp_changed.emit(xp, xp_required())


func _physics_process(delta: float) -> void:
	if stats.hp_regen > 0.0 and hp < stats.max_hp and not _dead:
		hp = minf(hp + stats.hp_regen * delta, stats.max_hp)
		health_changed.emit(hp, stats.max_hp)


func take_damage(amount: float) -> void:
	if _dead:
		return
	var final_damage := maxf(amount - stats.armor, 1.0)
	hp -= final_damage
	health_changed.emit(hp, stats.max_hp)
	if hp <= 0.0:
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	hp = minf(hp + amount, stats.max_hp)
	health_changed.emit(hp, stats.max_hp)


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_required():
		xp -= xp_required()
		level += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_required())


func xp_required() -> int:
	return 10 + level * 5
