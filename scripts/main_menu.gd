extends Node2D

@onready var frog = %FrogSprite
@onready var cursor = %Cursor
@onready var button_back = %ButtonBack
@onready var button_music = %ButtonMusic
@onready var button_sfx = %ButtonSFX
@onready var start = %menu_gold_start
@onready var howto = %menu_gold_howto
@onready var credits = %menu_gold_credits
@onready var music = %Music
@onready var music_timer = $Music/MusicTimer
@onready var music_bus = AudioServer.get_bus_index("Music")
@onready var sfx_bus = AudioServer.get_bus_index("SFX")

var state = -1


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	button_back.set_type(0)
	button_music.set_type(4 if !AudioServer.is_bus_mute(music_bus) else 5)
	button_music.set_title("Music")
	button_sfx.set_type(6 if !AudioServer.is_bus_mute(sfx_bus) else 7)
	button_sfx.set_title("SFX")


func on_button_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if state == 1:
				%HowTo.visible = false
			elif state == 2:
				%Credits.visible = false
			%Title.visible = true
			button_back.visible = false
			button_music.visible = true
			button_sfx.visible = true
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
			button_back.visible = true
			button_music.visible = false
			button_sfx.visible = false


func credits_onclick(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			%Title.visible = false
			%Credits.visible = true
			state = 2
			button_back.visible = true
			button_music.visible = false
			button_sfx.visible = false


func start_onclick(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file("res://scenes/game.tscn")


func on_music_finished():
	music_timer.start()


func can_restart_music():
	music.play()


func on_toggle_music(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			AudioServer.set_bus_mute(music_bus, !AudioServer.is_bus_mute(music_bus))
			button_music.set_type(4 if !AudioServer.is_bus_mute(music_bus) else 5)


func on_toggle_sfx(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			AudioServer.set_bus_mute(sfx_bus, !AudioServer.is_bus_mute(sfx_bus))
			button_sfx.set_type(6 if !AudioServer.is_bus_mute(sfx_bus) else 7)
