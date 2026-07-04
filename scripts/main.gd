extends Node2D

## Run orchestrator: wires the player, spawner, HUD, and upgrade menu together
## via signals. Owns pause state for level-up choices and game over.

const XP_PICKUP_SCENE := preload("res://scenes/xp_pickup.tscn")

## Level-ups that still need an upgrade choice (handles multi-level XP gains).
var _pending_level_ups: Array[int] = []
var _choosing := false

@onready var player: Player = $Player
@onready var spawner: EnemySpawner = $EnemySpawner
@onready var pickups: Node2D = $Pickups
@onready var hud: CanvasLayer = $HUD
@onready var upgrade_menu: UpgradeMenu = $UpgradeMenu
@onready var game_over_layer: CanvasLayer = $GameOverLayer


func _ready() -> void:
	hud.setup(player)
	player.leveled_up.connect(_on_player_leveled_up)
	player.died.connect(_on_player_died)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	upgrade_menu.upgrade_chosen.connect(_on_upgrade_chosen)
	get_node("%RestartButton").pressed.connect(_on_restart_pressed)


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(xp_value: int, death_position: Vector2) -> void:
	var pickup: XpPickup = XP_PICKUP_SCENE.instantiate()
	pickups.add_child(pickup)
	pickup.global_position = death_position
	pickup.xp_value = xp_value


func _on_player_leveled_up(new_level: int) -> void:
	_pending_level_ups.append(new_level)
	_show_next_upgrade_choice()


func _show_next_upgrade_choice() -> void:
	if _choosing or _pending_level_ups.is_empty():
		return
	_choosing = true
	get_tree().paused = true
	upgrade_menu.open(_pending_level_ups.pop_front(), UpgradePool.roll(3))


func _on_upgrade_chosen(id: String) -> void:
	UpgradePool.apply(id, player)
	_choosing = false
	if _pending_level_ups.is_empty():
		get_tree().paused = false
	else:
		_show_next_upgrade_choice()


func _on_player_died() -> void:
	get_tree().paused = true
	game_over_layer.visible = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
