extends Node2D

@onready var base = %Base
@onready var type = $Type
@onready var ani : AnimatedSprite2D = type.get_children()[0]

func set_type(val : int):
	ani = type.get_children()[val]
	ani.visible = true

func on_focus():
	ani.frame = 1
	
func on_lose_focus():
	ani.frame = 0
	base.frame = 0

func pressed():
	base.frame = 1

func released():
	base.frame = 0


func on_click(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				base.frame = 1
			else:
				base.frame = 0
