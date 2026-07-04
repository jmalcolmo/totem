class_name XpPickup
extends Area2D

@export var xp_value := 4


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("gain_xp"):
		body.gain_xp(xp_value)
		queue_free()
