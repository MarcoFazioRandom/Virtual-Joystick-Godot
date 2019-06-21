extends Control

class_name Joystick

# If the joystick is receiving inputs.
var is_working := false

# The joystick output.
var output := Vector2.ZERO

# STATIC: The joystick doesn't move.
# MOVING: Every time the joystick area is pressed, the joystick position is set on the touched position.
# FOLLOWING: If the finger moves outside the joystick background, the joystick follows it.
enum Joystick_mode {STATIC, MOVING, FOLLOWING}

export(Joystick_mode) var joystick_mode := Joystick_mode.STATIC

# REAL: return a vector with a lenght beetween 0 (deadzone) and 1; useful for implementing different velocity or acceleration.
# NORMALIZED: return a normalized vector.
enum Vector_mode {REAL, NORMALIZED}

export(Vector_mode) var vector_mode := Vector_mode.REAL

# The color of the button when the joystick is in use.
export(Color) var _pressed_color := Color.gray

# The number of directions, e.g. a D-pad is joystick with 4 directions, keep 0 for a free joystick.
export(int) var directions := 0

# It changes the angle of simmetry of the directions.
export(int) var simmetry_angle := 90

#If the handle is inside this range, in proportion to the background size, the output is zero.
export(float, 0, 0.5) var dead_zone := 0.2;

#The max distance the handle can reach, in proportion to the background size.
export(float, 0.5, 2) var clamp_zone := 1;

onready var _background := $Background
onready var _handle := $Background/Handle
onready var _original_color : Color = _handle.modulate
onready var _original_position : Vector2 = _background.rect_position

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and (joystick_mode == Joystick_mode.MOVING or joystick_mode == Joystick_mode.FOLLOWING):
		if event.is_pressed():
			var new_pos = event.position - _background.rect_size / 2
			_background.rect_position = new_pos
		else:
			_background.rect_position = _original_position

func _on_Background_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_handle.modulate = _pressed_color
		else:
			is_working = false
			output = Vector2.ZERO
			_set_handle_center_position(_background.rect_size / 2)
			_handle.modulate = _original_color
	
	if event is InputEventScreenDrag:
		var vector : Vector2 = event.position - _background.rect_size / 2
		var dead_size = dead_zone * _background.rect_size.x / 2
		if vector.length() < dead_size:
			is_working = false
			output = Vector2.ZERO
			_set_handle_center_position(_background.rect_size / 2)
			return
		_update_output(vector)
		is_working = true
		if joystick_mode == Joystick_mode.FOLLOWING:
			_following(vector)

func _set_handle_center_position(new_position : Vector2) -> void:
	_handle.rect_position = new_position - _handle.rect_size / 2

func _update_output(vector: Vector2) -> void:
	var dead_size = dead_zone * _background.rect_size.x / 2
	var clamp_size = clamp_zone * _background.rect_size.x / 2
	vector = vector.clamped(clamp_size)
	if directions > 0:
		vector = _directional_vector(vector, directions, deg2rad(simmetry_angle))
	output = vector.normalized()
	if vector_mode == Vector_mode.REAL and vector.length() < clamp_size:
		output *= (vector.length() - dead_size) / (clamp_size - dead_size)
	_set_handle_center_position(output * clamp_size + _background.rect_size / 2)

func _following(vector: Vector2) -> void:
	var clamp_size = clamp_zone * _background.rect_size.x / 2
	if vector.length() > clamp_size:
		var radius = vector.normalized() * clamp_size
		var delta = vector - radius
		var new_pos = _background.rect_position + delta
		new_pos.x = clamp(new_pos.x, -_background.rect_size.x / 2, rect_size.x - _background.rect_size.x / 2)
		new_pos.y = clamp(new_pos.y, -_background.rect_size.y / 2, rect_size.y - _background.rect_size.y / 2)
		_background.rect_position = new_pos

func _directional_vector(vector: Vector2, n_directions: int, simmetry_angle := PI/2) -> Vector2:
	var angle := (vector.angle() + simmetry_angle) / (PI / n_directions)
	angle = floor(angle) if angle >= 0 else ceil(angle)
	if abs(angle) as int % 2 == 1:
		angle = angle + 1 if angle >= 0 else angle - 1
	angle *= PI / n_directions
	angle -= simmetry_angle
	return Vector2(cos(angle), sin(angle)) * vector.length()