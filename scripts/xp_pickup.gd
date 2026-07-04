class_name XpPickup
extends Area2D

## Dropped XP. Collected by the player's XpCollector when it enters the
## player's (invisible) pickup radius — see xp_collector.gd.

@export var xp_value := 4

var _collected := false


func collect(collector: Node) -> void:
	if _collected:
		return
	_collected = true
	if collector.has_method("gain_xp"):
		collector.gain_xp(xp_value)
	queue_free()
