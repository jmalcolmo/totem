class_name BackgroundGrid
extends Node2D

## Draws a static, world-aligned grid so hops and walks read clearly against
## the background. This node stays at the origin (local space == world space)
## and each frame redraws only the lines covering the camera's view, snapped to
## world grid coordinates — so the grid appears fixed in the world while the
## player moves across it. Purely visual; nothing else reads from it.

## Camera anchor to keep the grid centered on (usually the player).
@export var target: Node2D
@export var cell_size := 64.0
@export var line_color := Color(1, 1, 1, 0.05)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = target.global_position if is_instance_valid(target) else global_position
	var half := get_viewport_rect().size * 0.5
	var top_left := center - half
	var bottom_right := center + half

	var x := floorf(top_left.x / cell_size) * cell_size
	while x <= bottom_right.x:
		draw_line(Vector2(x, top_left.y), Vector2(x, bottom_right.y), line_color, 1.0)
		x += cell_size

	var y := floorf(top_left.y / cell_size) * cell_size
	while y <= bottom_right.y:
		draw_line(Vector2(top_left.x, y), Vector2(bottom_right.x, y), line_color, 1.0)
		y += cell_size
