extends Node2D

@onready var button_play = $ButtonPlay
@onready var button_restart = $ButtonRestart
@onready var button_music = $ButtonMusic
@onready var button_sfx = $ButtonSFX
@onready var button_quit = $ButtonQuit
@onready var pause_label = $PauseLabel
@onready var music_bus = AudioServer.get_bus_index("Music")
@onready var sfx_bus = AudioServer.get_bus_index("SFX")


func _ready():
	button_play.set_type(2)
	button_play.set_title("Continue")
	button_restart.set_type(3)
	button_restart.set_title("Restart\r\n Round")
	button_music.set_type(4 if !AudioServer.is_bus_mute(music_bus) else 5)
	button_music.set_title("Music")
	button_sfx.set_type(6 if !AudioServer.is_bus_mute(sfx_bus) else 7)
	button_sfx.set_title("SFX")
	button_quit.set_type(8)
	button_quit.set_title("Quit")


func _input(event):
	if event.is_action_pressed("esc_click"):
		get_tree().paused = false
		get_tree().change_scene_to_file("res://main_menu.tscn")


func on_timer_tick():
	pause_label.visible = !pause_label.visible


func main_menu_onclick(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# call_deferred can cause some slight sfx/music play in the frame right before going back to main menu.
			# However it's necessary, to prevent the button from being triggered while in an invalid state.
			# It would cause "can_process: Condition !is_inside_tree() is true. Returning: false"
			# So, first we stop the sfx and rainforest loop - which will provide a smooth transition.
			for _sfx in $"../SFX".get_children():
				_sfx.stop()
			$"../RainForestTheme".stop()
			call_deferred("change_scene")


func change_scene():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main_menu.tscn")


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
