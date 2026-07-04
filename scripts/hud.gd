extends CanvasLayer

@onready var hp_bar: ProgressBar = %HpBar
@onready var xp_bar: ProgressBar = %XpBar
@onready var level_label: Label = %LevelLabel
@onready var time_label: Label = %TimeLabel

var _run_time := 0.0


func _process(delta: float) -> void:
	_run_time += delta
	var total := int(_run_time)
	time_label.text = "%02d:%02d" % [total / 60, total % 60]


func setup(player: Player) -> void:
	player.health_changed.connect(_on_health_changed)
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	_on_health_changed(player.hp, player.stats.max_hp)
	_on_xp_changed(player.xp, player.xp_required())
	_on_leveled_up(player.level)


func _on_health_changed(current: float, max_hp: float) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = maxf(current, 0.0)


func _on_xp_changed(xp: int, xp_required: int) -> void:
	xp_bar.max_value = xp_required
	xp_bar.value = xp


func _on_leveled_up(new_level: int) -> void:
	level_label.text = "Level %d" % new_level
