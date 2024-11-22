extends Node2D

signal fly_caught

@onready var frog_animation = %FrogAnimation
@onready var tongue = %Tongue

func on_idle():
	frog_animation.play("idle")

func on_jump():
	frog_animation.animation = "jump"
	frog_animation.frame = 1
	
func on_catching(dir : int):
	frog_animation.animation = "catch"
	if dir == 0:
		scale.x = -1
		dir = 1
	elif dir == 1:
		# Handle the case where you jump down or up while facing left
		scale.x = 1
	elif dir == 2:
		tongue.rotation_degrees = 270.0
		tongue.position = Vector2(12, -40)
	elif dir == 3:
		tongue.rotation_degrees = 90.0
		tongue.position = Vector2(4, 40)
	frog_animation.frame = dir
	tongue.play("extend")

func on_caught():
	if tongue.animation == "extend":
		tongue.frame = 0
		tongue.rotation_degrees = 0.0
		tongue.position = Vector2(40, 0)
		frog_animation.play("idle")
		fly_caught.emit()
