class_name UpgradePool
extends RefCounted

## Static pool of level-up upgrades. All options are equally weighted and can
## be taken any number of times. Add new upgrades by appending to UPGRADES and
## handling the id in apply().

const UPGRADES: Array[Dictionary] = [
	{"id": "attack_speed", "name": "Attack Speed", "description": "+15% attack speed"},
	{"id": "attack_damage", "name": "Attack Damage", "description": "+5 attack damage"},
	{"id": "max_hp", "name": "Max HP", "description": "+20 max HP (heals 20)"},
	{"id": "hp_regen", "name": "HP Regen", "description": "+1 HP per second"},
	{"id": "move_speed", "name": "Move Speed", "description": "+10% move speed"},
	{"id": "armor", "name": "Armor", "description": "+1 armor (flat damage reduction)"},
]


static func roll(count: int) -> Array[Dictionary]:
	var pool := UPGRADES.duplicate()
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result


static func apply(id: String, player: Player) -> void:
	var stats := player.stats
	match id:
		"attack_speed":
			stats.attack_speed *= 1.15
		"attack_damage":
			stats.attack_damage += 5.0
		"max_hp":
			stats.max_hp += 20.0
			player.heal(20.0)
		"hp_regen":
			stats.hp_regen += 1.0
		"move_speed":
			stats.move_speed *= 1.10
		"armor":
			stats.armor += 1.0
		_:
			push_warning("Unknown upgrade id: %s" % id)
