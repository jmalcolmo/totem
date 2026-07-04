class_name XpCollector
extends Area2D

## Invisible XP pickup radius around the player: any XpPickup whose area
## overlaps this one is collected immediately, no physical contact needed.
## Kept as its own node so it stays decoupled from the movement and combat
## systems. Nothing is drawn.

## Radius (pixels) of the pickup field.
## TODO: promote to a PlayerStats value if a magnet-radius upgrade is added.
@export var radius := 120.0
@export var player: Player

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape.shape = circle


func _physics_process(_delta: float) -> void:
	# Poll overlaps rather than using area_entered so pickups spawned already
	# inside the radius (enemy dying next to the player) are still collected.
	for area in get_overlapping_areas():
		if area is XpPickup:
			area.collect(player)
