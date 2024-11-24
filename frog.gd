extends Area2D

signal done_catching(caught : int)
signal clear_cell(pos : Vector2)

@onready var frog = %FrogSprite
@onready var fly_collision = %FlyCollision
@onready var sfx_catch = $SFX/SFXCatch

var next_x = -1
var next_y = -1
# Interval between movements
const step_delay = 0.07
var step_time = 0.0
const step = 18

# Current fly being caught
var target_fly: Area2D = null
var caught_flies = 0


func _ready():
	frog.on_idle()


func _process(delta):
	if (next_x > 0 and position.x != next_x) or (next_y > 0 and position.y != next_y):
		step_time += delta
		if step_time >= step_delay:
			frog.on_jump()
			step_time = 0.0
			if next_x > 0:
				if position.x < next_x:
					frog.scale.x = 1
					position.x = min(position.x + step, next_x)
				elif position.x > next_x:
					frog.scale.x = -1
					position.x = max(position.x - step, next_x)
			elif next_y > 0:
				if position.y < next_y:
					position.y = min(position.y + step, next_y)
				elif position.y > next_y:
					position.y = max(position.y - step, next_y)
			if (next_x <= 0 or position.x == next_x) and (next_y <= 0 or position.y == next_y):
				try_catch_fly()


func set_target(x, y):
	next_x = x
	next_y = y


func try_catch_fly():
	target_fly = null
	var flies = fly_collision.get_overlapping_areas()
	if flies.size() > 0:
		for fly in flies:
			if !fly.is_queued_for_deletion():
				target_fly = fly
				break
	if target_fly != null:
		var dir : int
		if target_fly.position.x < position.x:
			dir = 0 # fly to the left
		elif target_fly.position.x > position.x:
			dir = 1 # fly to the right
		elif target_fly.position.y < position.y:
			dir = 2 # fly above
		elif target_fly.position.y > position.y:
			dir = 3 # fly below
		frog.on_catching(dir)
		# Note: as of Godot 4.3, AudioStreamPlayer.play() resets pitch_scale to 1.
		# Must set the pitch scale AFTER play.
		sfx_catch.play()
		sfx_catch.pitch_scale = randf_range(0.5, 1.5)
		caught_flies += 1
	else:
		frog.on_idle()
		done_catching.emit(caught_flies)
		caught_flies = 0


func on_caught_fly():
	if target_fly != null:
		clear_cell.emit(target_fly.position)
		target_fly.queue_free()
	try_catch_fly()


func reset():
	frog.on_idle()
	next_x = -1
	next_y = -1
