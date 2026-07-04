class_name UpgradeMenu
extends CanvasLayer

## Minimal level-up choice UI. Runs while the tree is paused (process_mode is
## Always on this layer). Main pauses/unpauses; this only reports the choice.

signal upgrade_chosen(id: String)

@onready var title_label: Label = %TitleLabel
@onready var options_box: HBoxContainer = %OptionsBox


func open(new_level: int, options: Array[Dictionary]) -> void:
	title_label.text = "Level %d! Choose an upgrade:" % new_level
	for child in options_box.get_children():
		child.queue_free()
	for option in options:
		var button := Button.new()
		button.text = "%s\n%s" % [option["name"], option["description"]]
		button.custom_minimum_size = Vector2(180, 90)
		button.pressed.connect(_on_option_pressed.bind(option["id"]))
		options_box.add_child(button)
	visible = true


func _on_option_pressed(id: String) -> void:
	visible = false
	upgrade_chosen.emit(id)
