extends Node2D

# Object refs
@onready var frog = %Frog
@onready var frog_position = frog.position
@onready var game = %Game
@onready var cursor = %Cursor
@onready var pause_menu = %PauseMenu
@onready var clear_msg = %RoundClear
@onready var menu_button = %MenuButton
@onready var button_restart = $PauseMenu/ButtonRestart
@onready var preview_lilypad = %PreviewLilypad
@onready var lily_timer = %LilyTimer
@onready var jump_timer = %JumpTimer
@onready var game_timer = %GameTimer
@onready var round_timer = %EndRoundTimer
@onready var blink_timer = preview_lilypad.get_child(0)
@onready var blink_timer_2 = preview_lilypad.get_child(1)
@onready var sfx_jump = $SFX/SFXJump
@onready var sfx_clear_stage = $SFX/SFXClearStage
@onready var sfx_win_game = $SFX/SFXWinGame

# Grid constants (width and height of cells)
const w = 640
const h = 480
const w_cell = 64
const h_cell = 60
var rows : int = h / h_cell
var cols : int = w / w_cell
var size : int = rows * cols
# Array representing the state of each cell (0 = empty, 1 = lilypad, 2 = frog, 3 = fly)
var grid = Array()
# Multi-purpose cell-sized vector, for placement help
const cell = Vector2(w_cell, h_cell)
# The objects for placement
const lilypad = preload("res://scenes/lilypad.tscn")
const fly = preload("res://scenes/fly.tscn")
# Lilypad data: amount and availability
var lily_available : int = 0
var lily_this_round = 0
var has_preview : bool = false
# UI numbers
var no_lily = []
var no_clock = []
var no_level = []
# Current game level and fly goal
var level = -1
var flies = 0
# Blocked indexes for fly placement - this avoids that a fly can start directly near the frog.
var blocked_indexes = [23, 25, 14, 34]
var fly_bounds = [1335, 1336, 436, 426, 527, 528, 618, 608, 708, 709]
# Target, resource and time amount per stage
const fly_count = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
const lily_count = [4, 4, 4, 4, 4, 4, 4, 5, 5, 5]
# If you clear a round with time to spare, you get extra lilies
var lily_bonus = 0
const round_time = [9, 12, 15, 15, 18, 18, 21, 21, 24, 30]
# Game timer in seconds + 2 of wait time
const game_delay : float = 2.0
var stage_delay = game_delay
var game_time
var clear_delay = 0.0
var lily_delay = 0.0
var round_starting = false
var round_state = 0
var game_paused = false


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	menu_button.set_type(1)
	# Resize the grid to the game window
	grid.resize(size)
	# Group the timers for ease of handling, because we're fancy
	game_timer.add_to_group("timers")
	lily_timer.add_to_group("timers")
	jump_timer.add_to_group("timers")
	round_timer.add_to_group("timers")
	blink_timer.add_to_group("timers")
	blink_timer_2.add_to_group("timers")
	# Get references of UI numbers
	no_lily.append_array(%NoLily.get_children())
	no_clock.append_array(%NoClock.get_children())
	no_level.append_array(%Round.get_children())
	
	# Start the round
	start_round(false)


func _process(_delta):
	var mouse = game.get_local_mouse_position()
	if round_state == 0:
		if has_preview:
			mouse.x = clamp(mouse.x, 0, w - w_cell)
			mouse.y = clamp(mouse.y, 0, h - h_cell)
			var grid_index = (mouse / cell).floor()
			var cell_center = grid_index * cell + cell / 2
			preview_lilypad.position = cell_center
			# Offset of the status bar is equal to 2 extra rows, hence the y - 2
			var index_raw = grid_index.x + grid_index.y * cols
			if grid[index_raw] == 0:
				preview_lilypad.frame = 0
			else:
				preview_lilypad.frame = 1
			# Place a lilypad if action is available
			if Input.is_action_just_pressed("left_click"):
				if grid[index_raw] == 0:
					has_preview = false
					blink_timer.stop()
					preview_lilypad.visible = false
					var new_lilypad = lilypad.instantiate()
					new_lilypad.position = cell_center
					game.add_child(new_lilypad)
					new_lilypad.add_to_group("lilypads")
					grid[index_raw] = 1
					set_lilypad_number(-1, true, false)
		# Trying to place a lilypad when one is not available
		elif lily_delay <= 0.0 and lily_available == 0 and Input.is_action_just_pressed("left_click"):
			lily_delay = 1.0
			blink_timer_2.start()


# Start next round
func start_round(restart : bool):
	# Reset the grid and initialize the clock
	grid.fill(0)
	# Clear leftover lilypads from the scene
	for _lily in get_tree().get_nodes_in_group("lilypads"):
		game.remove_child(_lily)
		_lily.queue_free()
	# Clear leftover flies from the scene (this applies only to a restart)
	if restart:
		for _fly in get_tree().get_nodes_in_group("flies"):
			game.remove_child(_fly)
			_fly.queue_free()
	# Align the frog with the grid - this may go if the frog is handled as spawn instead of being part of the scene
	frog.reset()
	frog.position = frog_position
	var grid_index = (frog.position / cell).floor()
	var frog_index = grid_index.x + grid_index.y * cols
	grid[frog_index] = 2
	# Place the frog on a lilypad, we ain't levitating
	var first_lilypad = lilypad.instantiate()
	first_lilypad.position = frog.position
	game.add_child(first_lilypad)
	first_lilypad.add_to_group("lilypads")
	
	set_level(level + 1)
	set_time(game_time)
	set_lilypad_number(lily_count[level] + lily_bonus, false, restart)
	place_flies(fly_count[level])
	round_state = 0
	round_starting = true
	
	# Set delay for pregame
	game_timer.wait_time = 0.25
	game_timer.timeout.connect(on_tick_pre)
	game_timer.start()


# Pre-game countdown
func on_tick_pre():
	stage_delay -= game_timer.wait_time
	if stage_delay > 0:
		set_digits(1, 5 if stage_delay > 1 else 1, "")
		if stage_delay <= 1:
			set_digits(0, 4, "static")
	else:
		game_timer.stop()
		stage_delay = game_delay
		set_digits(0, 0, "")
		game_timer.timeout.disconnect(on_tick_pre)
		game_timer.wait_time = 1.0
		game_timer.timeout.connect(on_tick)
		round_starting = false
		game_timer.start()
		lily_timer.start()
		jump_timer.start()


# Game countdown
func on_tick():
	game_time -= 1;
	if game_time < 0:
		game_time = 0
		game_timer.stop()
		clear_round(2)
	elif game_time > 0 and game_time % 3 == 0:
		set_lilypad_number(1, true, false)
	set_time(game_time)
	if game_time == 0:
		set_digits(0, 1, "warn")


# Place a specified amount of flies on the water. Must already know level number (use after set_level).
func place_flies(amount):
	flies = 0
	var picked : int = 0
	var bound_x0 = (fly_bounds[level] / 10) % 10
	var bound_x1 = fly_bounds[level] % 10
	var bound_y0 = fly_bounds[level] / 1000
	var bound_y1 = (fly_bounds[level] / 100) % 10
	while (picked < amount):
		var rand_x = randi_range(bound_x0, bound_x1)
		var rand_y = randi_range(bound_y0, bound_y1)
		var rand_index = rand_y * 10 + rand_x
		if grid[rand_index] == 0 && !blocked_indexes.has(rand_index):
			grid[rand_index] = 3
			var _fly = fly.instantiate()
			var _row = rand_index / cols
			var _col = rand_index % cols
			_fly.position = Vector2(_col * w_cell + w_cell / 2, _row * h_cell + h_cell / 2)
			_fly.z_index = 3
			game.add_child(_fly)
			_fly.add_to_group("flies")
			picked += 1
			flies += 1


# Check if a jump action is available
func on_try_jump():
	var frog_cell = grid.find(2)
	if frog_cell >= 0:
		# We must figure out how many directions we can take.
		# Frog will favor the right side, and then counter-clockwise (15 = 1111 = BLTR).
		var dir = 15
		var _row = frog_cell / cols
		var _col = frog_cell % cols
		if _col == cols - 1:
			dir ^= 1
		elif _col == 0:
			dir ^= 4
		if _row == 0:
			dir ^= 2
		elif _row == rows - 1:
			dir ^= 8
		# Attempt a jump
		if (dir & 1) != 0 and grid[frog_cell + 1] == 1:
			# Jump on the lilypad to the right
			on_jump(frog_cell, frog_cell + 1, frog.position.x + w_cell, 0)
		elif (dir & 2) != 0 and grid[frog_cell - cols] == 1:
			# Jump on the lilypad above
			on_jump(frog_cell, frog_cell - cols, 0, frog.position.y - h_cell)
		elif (dir & 4) != 0 and grid[frog_cell - 1] == 1:
			# Jump on the lilypad to the left
			on_jump(frog_cell, frog_cell - 1, frog.position.x - w_cell, 0)
		elif (dir & 8) != 0 and grid[frog_cell + cols] == 1:
			# Jump on the lilypad below
			on_jump(frog_cell, frog_cell + cols, 0, frog.position.y + h_cell)


# Jump on an adjacent lilypad
func on_jump(old_cell, new_cell, x, y):
	jump_timer.stop()
	frog.set_target(x, y)
	grid[old_cell] = 0
	grid[new_cell] = 2
	var lilypads_under = frog.get_overlapping_bodies()
	if lilypads_under.size() > 0:
		lilypads_under[0].queue_free()
	sfx_jump.play()
	sfx_jump.pitch_scale = randf_range(0.7, 1.5)


# Reset the jump timer after catching a fly
func on_frog_done_catching(caught):
	flies -= caught
	if flies == 0:
		clear_round(1 if level < 9 else 3)
	else:
		jump_timer.start()


# Clear a cell after catching a fly (from Frog)
func on_clear_cell(pos):
	var grid_index = (pos / cell).floor()
	var index_raw = grid_index.x + grid_index.y * cols
	grid[index_raw] = 0


# Enable the lilypad placement
func on_lilypad_ready():
	if lily_available > 0:
		has_preview = true
		blink_timer.start()


# Blink the lilypad preview under the cursor
func blink_preview():
	preview_lilypad.visible = !preview_lilypad.visible


# Blink the lilypad amount if player tries to place one while it's zero
func blink_lilypad_count():
	lily_delay -= blink_timer_2.wait_time
	if lily_delay <= 0.0 or lily_available > 0:
		lily_delay = 0.0
		for lily_no in no_lily:
			lily_no.visible = true
		blink_timer_2.stop()
	elif lily_available == 0:
		for lily_no in no_lily:
			lily_no.visible = !lily_no.visible


# Update the number of lilypads in the UI
func set_lilypad_number(delta, timer : bool, restart : bool):
	if restart:
		lily_available = lily_this_round
	else:
		lily_available += delta
		if !timer:
			lily_this_round = lily_available
	if lily_available < 0:
		lily_available = 0
	if lily_available < 10:
		no_lily[0].set_number(0)
	else:
		no_lily[0].set_number(lily_available / 10)
	no_lily[1].set_number(lily_available % 10)
	if timer and lily_available > 0:
		lily_timer.start()
		set_digits(0, 2, "run")
	elif lily_available == 0:
		set_digits(0, 2, "warn")


# Update the time number in the UI
func set_time(value):
	no_clock[0].set_number(value / 100)
	no_clock[1].set_number((value / 10) % 10)
	no_clock[2].set_number(value % 10)


# Update the round number in the UI, to level + 1. Also updates actual level variable and time!
func set_level(num):
	level = num
	game_time = round_time[level]
	var digit = num + 1
	if digit < 10:
		no_level[1].visible = false
		no_level[0].set_number(digit)
	else:
		no_level[0].set_number(digit / 10)
		no_level[1].set_number(digit % 10)
		no_level[1].visible = true


# Multi-purpose function to alter the display of UI numbers
func set_digits(blink : int, type : int, ani : String):
	if type == 0:
		for digit in no_clock:
			digit.set_state("run")
			digit.visible = true
		for digit in no_lily:
			digit.set_state("run")
			digit.visible = true
		for digit in no_level:
			digit.set_state("run")
		no_level[0].visible = true
		if level >= 9:
			no_level[1].visible = true
	else:
		if blink == 1:
			var has_ani : bool = ani != ""
			if (type & 1) != 0:
				for digit in no_clock:
					digit.visible = !digit.visible
					if has_ani:
						digit.set_state(ani)
			if (type & 2) != 0:
				for digit in no_lily:
					digit.visible = !digit.visible
					if has_ani:
						digit.set_state(ani)
			if (type & 4) != 0:
				no_level[0].visible = !no_level[0].visible
				if level >= 9:
					no_level[1].visible = !no_level[1].visible
				for digit in no_level:
					if has_ani:
						digit.set_state(ani)
		else:
			if (type & 1) != 0:
				for digit in no_clock:
					digit.set_state(ani)
					digit.visible = true
			if (type & 2) != 0:
				for digit in no_lily:
					digit.set_state(ani)
					digit.visible = true
			if (type & 4) != 0:
				for digit in no_level:
					digit.set_state(ani)
				no_level[0].visible = true
				if level >= 9:
					no_level[1].visible = true


# Blink the "round clear" text
func blink_message():
	clear_delay -= round_timer.wait_time
	if clear_delay > 0:
		clear_msg.visible = !clear_msg.visible
	else:
		clear_msg.visible = true
		if clear_delay <= -2.0:
			if round_state > 1:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
			else:
				clear_msg.visible = false
				round_timer.stop()
				round_timer.timeout.disconnect(blink_message)
				round_timer.timeout.connect(round_timer_tick)
				start_round(false)


# Prepare the game for the next round, after a win
func clear_round(state : int):
	round_state = state
	has_preview = false
	preview_lilypad.visible = false
	jump_timer.stop()
	blink_timer.stop()
	blink_timer_2.stop()
	game_timer.stop()
	game_timer.timeout.disconnect(on_tick)
	lily_timer.stop()
	set_digits(0, 7, "static")
	# Round won - check for bonus lilypads in the next round
	if state == 1:
		lily_bonus = ceili(((game_time - 1) / 3) * 1.5)
		if lily_bonus < 0:
			lily_bonus = 0
		pass
	# Round lost - print "Game over"
	elif state == 2:
		for msg in clear_msg.get_children():
			msg.text = " Game Over!"
		clear_msg.get_child(4).visible = true
	# Game is won - print it
	elif state == 3:
		for msg in clear_msg.get_children():
			msg.text = "  Game Won!"
	clear_delay = 0.5
	round_timer.wait_time = 0.25
	round_timer.start()


# Round timer to blink the "round clear" and then display menu
func round_timer_tick():
	clear_delay -= round_timer.wait_time
	if clear_delay <= 0:
		round_timer.stop()
		clear_delay = 1.0
		round_timer.wait_time = 0.125
		round_timer.timeout.disconnect(round_timer_tick)
		round_timer.timeout.connect(blink_message)
		round_timer.start()
		if round_state < 3:
			sfx_clear_stage.play()
		else:
			sfx_win_game.play()



func on_menu_button_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var can_restart = (round_state == 0) && !round_starting
				$PauseMenu/ButtonRestart/Area2D.visible = can_restart
				button_restart.set_type(3 if can_restart else -1)
				menu_button.set_type(-1)
				game_paused = true
				pause_game(true)
				for lily_no in no_lily:
					lily_no.visible = true
				get_tree().paused = true
				pause_menu.show()
			else:
				menu_button.released()


# Pause the game when the menu is opened
func pause_game(paused : bool):
	for _timer in get_tree().get_nodes_in_group("timers"):
		_timer.paused = paused

func on_play_button_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index and event.pressed:
			menu_button.set_type(1)
			game_paused = false
			get_tree().paused = false
			pause_game(false)
			pause_menu.hide()

func on_restart_button_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index and event.pressed:
			has_preview = false
			preview_lilypad.visible = false
			for _timer in get_tree().get_nodes_in_group("timers"):
				_timer.stop()
			game_timer.timeout.disconnect(on_tick)
			level -= 1
			menu_button.set_type(1)
			game_paused = false
			get_tree().paused = false
			pause_game(false)
			pause_menu.hide()
			start_round(true)
