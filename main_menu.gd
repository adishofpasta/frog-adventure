extends Node2D

@onready var frog = %FrogSprite
@onready var cursor = %Cursor
@onready var button = %ButtonBack
@onready var start = %menu_gold_start
@onready var howto = %menu_gold_howto
@onready var credits = %menu_gold_credits
@onready var music = %Music
@onready var music_timer = $Music/MusicTimer

var state = -1


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	button.set_type(0)


func on_button_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if state == 1:
				%HowTo.visible = false
			elif state == 2:
				%Credits.visible = false
			%Title.visible = true
			button.visible = false
			state = -1


func _on_timer_timeout():
	if randi() % 10 == 0:
		frog.play("lucky")


func on_jump_ani_finished():
	if frog.animation == "lucky":
		frog.play("default")


func _on_menu_gold_start_mouse_entered():
	start.visible_characters = -1


func _on_menu_gold_start_mouse_exited():
	start.visible_characters = 0


func _on_menu_gold_howto_mouse_entered():
	howto.visible_characters = -1


func _on_menu_gold_howto_mouse_exited():
	howto.visible_characters = 0


func _on_menu_gold_credits_mouse_entered():
	credits.visible_characters = -1


func _on_menu_gold_credits_mouse_exited():
	credits.visible_characters = 0


func howto_onclick(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			%Title.visible = false
			%HowTo.visible = true
			state = 1
			button.visible = true


func credits_onclick(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			%Title.visible = false
			%Credits.visible = true
			state = 2
			button.visible = true


func start_onclick(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file("res://game.tscn")


func on_music_finished():
	music_timer.start()


func can_restart_music():
	music.play()
