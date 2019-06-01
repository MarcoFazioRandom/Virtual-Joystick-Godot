extends Control

class_name Joystick

# STATIC: The joystick doesn't move.
# MOVING: Every time the joystick area is pressed, the joystick position is set on the touched position.
# FOLLOWING: If the finger moves outside the joystick background, the joystick follows it.
enum UI_Mode {STATIC, MOVING, FOLLOWING}

# REAL: return a vector with a lenght beetween 0 (deadzone) and 1; useful for implementing different velocity or acceleration.
# NORMALIZED: return a normalized vector.
enum Vector_Mode {REAL, NORMALIZED}

# If the joystick is receiving inputs.
var is_working := false

# The joystick output.
var output := Vector2.ZERO

export(UI_Mode) var ui_mode := UI_Mode.STATIC

export(Vector_Mode) var vector_mode := Vector_Mode.REAL

# The color of the button when the joystick is in use.
export(Color) var _pressed_color := Color.gray

# The number of directions, e.g. a D-pad is joystick with 4 directions, keep 0 for a free joystick.
export(int) var directions := 0

# It changes the angle of simmetry of the directions.
export(int) var simmetry := 90

# When the joystick value is less than the deadzone, the output is zero.
export(int, 64) var dead_zone := 20

# The max distance the button can reach from the center.
export var clamp_zone := 128

onready var _background := $Background
onready var _circle := $Background/Circle
onready var _original_color : Color = _circle.modulate

func _gui_input(event: InputEvent) -> void:
	if (ui_mode == UI_Mode.MOVING or ui_mode == UI_Mode.FOLLOWING) and \
			(event is InputEventScreenTouch and event.pressed):
		
		var new_pos = event.position - _background.rect_size/2
		_clamp_joystick_position(new_pos)

		_circle.modulate = _pressed_color
		is_working = true

func _on_Background_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		is_working = event.pressed
		if is_working:
			_circle.modulate = _pressed_color
		else:
			_reset_joystick()
	
	if event is InputEventScreenDrag:
		var vector : Vector2 = event.position - _background.rect_size/2
		
		# Control if the joystick is inside the deadzone
		if vector.length() < dead_zone:
			_set_circle_center_position(_background.rect_size/2)
			output = Vector2.ZERO
			return
		
		_update_output(vector)
		
		if ui_mode == UI_Mode.FOLLOWING:
			_following(vector)

func _reset_joystick() -> void:
	is_working = false
	output = Vector2.ZERO
	_set_circle_center_position(_background.rect_size/2)
	_circle.modulate = _original_color

func _set_circle_center_position(new_position : Vector2) -> void:
	_circle.rect_position = new_position - (_circle.rect_size / 2)

func _update_output(vector: Vector2) -> void:
	vector = vector.clamped(clamp_zone)
	
	if directions > 0:
		vector = _directional_vector(vector, directions, deg2rad(simmetry))
	
	_set_circle_center_position(vector + _background.rect_size/2)
	
	if vector_mode == Vector_Mode.NORMALIZED:
		output = vector.normalized()
	
	elif vector_mode == Vector_Mode.REAL:
		var vector_range = clamp_zone - dead_zone
		var length = vector.length() - dead_zone
		length = clamp(length, 0, vector_range)
		var proportion = length / vector_range
		output = vector.normalized() * proportion

func _following(vector: Vector2) -> void:
	if vector.length() > clamp_zone:
		var radius = vector.normalized() * clamp_zone
		var delta = vector - radius
		var new_pos = _background.rect_position + delta
		_clamp_joystick_position(new_pos)

func _directional_vector(vector: Vector2, n_directions: int, simmetry := PI/2) -> Vector2:
	var angle := (vector.angle() + simmetry) / (PI / n_directions)
	angle = floor(angle) if angle >= 0 else ceil(angle)
	if abs(angle) as int % 2 == 1:
		angle = angle + 1 if angle >= 0 else angle - 1
	angle *= PI / n_directions
	angle -= simmetry
	vector = Vector2(cos(angle), sin(angle)) * vector.length()
	return vector

func _clamp_joystick_position(new_position: Vector2):
	new_position.x = clamp(new_position.x, -_background.rect_size.x / 2, rect_size.x - _background.rect_size.x / 2)
	new_position.y = clamp(new_position.y,- _background.rect_size.y / 2, rect_size.y - _background.rect_size.y / 2)
	_background.rect_position = new_position
