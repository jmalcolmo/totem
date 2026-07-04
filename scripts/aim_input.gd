class_name AimInput
extends RefCounted

## Shared cursor/stick aim reading for the hop and totem systems. A tilted
## left stick acts as a virtual cursor offset from the player (full tilt =
## STICK_RANGE_PX); otherwise the mouse cursor position is used.

const STICK_DEVICE := 0
const STICK_DEADZONE := 0.25
## Full stick tilt maps to this many pixels of virtual cursor offset. Matches
## the hop system's outer radius + max overshoot, so full tilt = max hop.
const STICK_RANGE_PX := 310.0


## Aim point as an offset in pixels from the given node (usually the player).
static func aim_offset(from: Node2D) -> Vector2:
	var stick := Vector2(
		Input.get_joy_axis(STICK_DEVICE, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(STICK_DEVICE, JOY_AXIS_LEFT_Y)
	)
	if stick.length() > STICK_DEADZONE:
		return stick.limit_length(1.0) * STICK_RANGE_PX
	return from.get_global_mouse_position() - from.global_position


static func aim_direction(from: Node2D) -> Vector2:
	var offset := aim_offset(from)
	return offset.normalized() if offset != Vector2.ZERO else Vector2.RIGHT
