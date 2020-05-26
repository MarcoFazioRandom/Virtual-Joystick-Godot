extends KinematicBody2D

class_name Player

export var speed : float = 300

export (NodePath) var joystickLeftPath
onready var joystickLeft : Joystick = get_node(joystickLeftPath)

export (NodePath) var joystickRightPath
onready var joystickRight : Joystick = get_node(joystickRightPath)

func _physics_process(delta: float) -> void:
	_move(delta)

func _move(delta: float) -> void:
	if joystickLeft and joystickLeft.is_working:
		move_and_slide(joystickLeft.output * speed)
	
	if joystickRight and joystickRight.is_working:
		rotation = joystickRight.output.angle()
