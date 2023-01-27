extends Sprite2D

@export var joystickLeft : VirtualJoystick = null

@export var speed : float = 100

@export var joystickRight : VirtualJoystick = null

func _process(delta: float) -> void:
#	# Movement using the joystick output:
#	if joystickLeft and joystickLeft.is_pressed():
#		position += joystickLeft.get_output() * speed * delta
	
	# Movement using Input functions:
	var move := Vector2.ZERO
	move.x = Input.get_axis("ui_left", "ui_right")
	move.y = Input.get_axis("ui_up", "ui_down")
	position += move * speed * delta
	
	# Rotation:
	if joystickRight and joystickRight.is_pressed():
		rotation = joystickRight.get_output().angle()
