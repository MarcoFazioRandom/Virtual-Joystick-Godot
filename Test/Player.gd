extends KinematicBody2D

class_name Player

export var speed := 300

onready var joystick_move := $UI/JoystickMove
onready var joystick_look := $UI/JoystickLook

func _physics_process(delta: float) -> void:
	_move(delta)

func _move(delta: float) -> void:
	if joystick_move and joystick_move.is_working:
		move_and_slide(joystick_move.output * speed)
	
	if joystick_look and joystick_look.is_working and joystick_look.output.length_squared() > 0:
		rotation = joystick_look.output.angle()
