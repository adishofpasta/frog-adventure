extends Node2D

@onready var icon = %Icon
@onready var scene = get_tree().current_scene

func _process(_delta):
	var mouse = get_global_mouse_position()
	position = Vector2(floor(mouse.x / 8) * 8, floor(mouse.y / 8) * 8)
	if scene and scene.name == "FrogGame":
		if mouse.y < 80:
			icon.frame = 1
		else:
			icon.frame = 0
