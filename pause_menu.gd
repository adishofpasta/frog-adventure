extends Node2D

@onready var button_play = $ButtonPlay
@onready var button_restart = $ButtonRestart
@onready var pause_label = $PauseLabel
@onready var to_main_menu = $ToMainMenu_Gold


func _ready():
	button_play.set_type(2)
	button_restart.set_type(3)


func on_timer_tick():
	pause_label.visible = !pause_label.visible


func main_menu_entered():
	to_main_menu.visible_characters = -1

func main_menu_exited():
	to_main_menu.visible_characters = 0


func main_menu_onclick(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://main_menu.tscn")
