extends Node2D

@onready var digit = %Digit

func set_number(val : int):
	digit.frame = val

func set_state(state : String):
	var frame = digit.frame
	digit.animation = state
	digit.frame = frame
