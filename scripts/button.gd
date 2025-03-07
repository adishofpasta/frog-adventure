extends Node2D

@onready var base = %Base
@onready var type = $Type
@onready var title = %Title
@onready var ani : AnimatedSprite2D = type.get_children()[0]

var has_title = false

func set_type(val : int):
	ani.visible = false
	if val >= 0:
		ani = type.get_children()[val]
		ani.visible = true

func set_title(text : String):
	has_title = text != ""
	title.text = text

func on_focus():
	ani.frame = 1
	title.visible = has_title
	
func on_lose_focus():
	ani.frame = 0
	base.frame = 0
	title.visible = false

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
