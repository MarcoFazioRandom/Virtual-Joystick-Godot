extends Control

class_name Joystick

# If the joystick is receiving inputs.
var is_working := false

# The joystick output.
var output := Vector2.ZERO

# FIXED: The joystick doesn't move.
# DYNAMIC: Every time the joystick area is pressed, the joystick position is set on the touched position.
# FOLLOWING: If the finger moves outside the joystick background, the joystick follows it.
enum JoystickMode {FIXED, DYNAMIC, FOLLOWING}

export(JoystickMode) var joystick_mode := JoystickMode.FIXED

# REAL: return a vector with a lenght beetween 0 (deadzone) and 1; useful for implementing different velocity or acceleration.
# NORMALIZED: return a normalized vector.
enum VectorMode {REAL, NORMALIZED}

export(VectorMode) var vector_mode := VectorMode.REAL

# The color of the button when the joystick is in use.
export(Color) var _pressed_color := Color.gray

# The number of directions, e.g. a D-pad is joystick with 4 directions, keep 0 for a free joystick.
export(int, 0, 12) var directions := 0

# It changes the angle of simmetry of the directions.
#export(int, -180, 180) 
export var simmetry_angle := 90

#If the handle is inside this range, in proportion to the background size, the output is zero.
export(float, 0, 0.5) var dead_zone := 0.2;

#The max distance the handle can reach, in proportion to the background size.
export(float, 0.5, 2) var clamp_zone := 1;

#VISIBILITY_ALWAYS = Always visible.
#VISIBILITY_TOUCHSCREEN_ONLY = Visible on touch screens only.
enum VisibilityMode {ALWAYS , TOUCHSCREEN_ONLY }

export(VisibilityMode) var visibility_mode := VisibilityMode.ALWAYS

onready var _background := $Background
onready var _handle := $Background/Handle
onready var _original_color : Color = _handle.self_modulate
onready var _original_position : Vector2 = _background.rect_position

var _touch_index :int = -1

func _ready() -> void:
	if not OS.has_touchscreen_ui_hint() and visibility_mode == VisibilityMode.TOUCHSCREEN_ONLY:
		hide()

func _touch_started(event: InputEventScreenTouch) -> bool:
	return event.pressed and _touch_index == -1

func _touch_ended(event: InputEventScreenTouch) -> bool:
	return not event.pressed and _touch_index == event.index

func _input(event: InputEvent) -> void:
	if not (event is InputEventScreenTouch or event is InputEventScreenDrag):
		return
	
	if event is InputEventScreenTouch:
		if _touch_started(event) and _is_inside_control_rect(event.position, self):
			if (joystick_mode == JoystickMode.DYNAMIC or joystick_mode == JoystickMode.FOLLOWING):
				_center_control(_background, event.position)
			if _is_inside_control_circle(event.position, _background):
				_touch_index = event.index
				_handle.self_modulate = _pressed_color
		elif _touch_ended(event):
			_reset()
	
	elif event is InputEventScreenDrag and _touch_index == event.index:
		var ray :float = _background.rect_size.x / 2
		var dead_size := dead_zone * ray
		var clamp_size := clamp_zone * ray
		
		var center :Vector2 = _background.rect_global_position + (_background.rect_size / 2)
		var vector :Vector2 = event.position - center
		
		if vector.length() > dead_size:
			if directions > 0:
				vector = _directional_vector(vector, directions, deg2rad(simmetry_angle))
			
			if vector_mode == VectorMode.NORMALIZED:
				output = vector.normalized()
				_center_control(_handle, output * clamp_size + center)
			elif vector_mode == VectorMode.REAL:
				var clamped_vector := vector.clamped(clamp_size)
				output = vector.normalized() * (clamped_vector.length() - dead_size) / (clamp_size - dead_size)
				_center_control(_handle, clamped_vector + center)
			
			is_working = true
			if joystick_mode == JoystickMode.FOLLOWING:
				_following(vector)
		else:
			is_working = false
			output = Vector2.ZERO
			_reset_handle()
			return

func _center_control(control: Control, new_global_position: Vector2) -> void:
	control.rect_global_position = new_global_position - (control.rect_size / 2)
	#control.rect_global_position = new_global_position - control.rect_pivot_offset

func _reset_handle():
	_center_control(_handle, _background.rect_global_position + (_background.rect_size / 2))

func _reset():
	_touch_index = -1
	is_working = false
	output = Vector2.ZERO
	_handle.self_modulate = _original_color
	_background.rect_position = _original_position
	_reset_handle()

func _is_inside_control_rect(global_position: Vector2, control: Control) -> bool:
	var x: bool = global_position.x > control.rect_global_position.x and global_position.x < control.rect_global_position.x + (control.rect_size.x * control.rect_scale.x)
	var y: bool = global_position.y > control.rect_global_position.y and global_position.y < control.rect_global_position.y + (control.rect_size.y * control.rect_scale.y)
	return x and y

func _is_inside_control_circle(global_position: Vector2, control: Control) -> bool:
	var ray := control.rect_size.x * control.rect_scale.x / 2
	var center := control.rect_global_position + Vector2(ray, ray)
	var ray_position := global_position - center
	return ray_position.length_squared() < ray * ray

func _following(vector: Vector2) -> void:
	var clamp_size :float = clamp_zone * _background.rect_size.x / 2
	if vector.length() > clamp_size:
		var radius := vector.normalized() * clamp_size
		var delta := vector - radius
		var new_pos :Vector2 = _background.rect_position + delta
		new_pos.x = clamp(new_pos.x, -_background.rect_size.x / 2, rect_size.x - _background.rect_size.x / 2)
		new_pos.y = clamp(new_pos.y, -_background.rect_size.y / 2, rect_size.y - _background.rect_size.y / 2)
		_background.rect_position = new_pos

# warning-ignore:shadowed_variable
func _directional_vector(vector: Vector2, n_directions: int, simmetry_angle := PI/2) -> Vector2:
	var angle := (vector.angle() + simmetry_angle) / (PI / n_directions)
	angle = floor(angle) if angle >= 0 else ceil(angle)
	if abs(angle) as int % 2 == 1:
		angle = angle + 1 if angle >= 0 else angle - 1
	angle *= PI / n_directions
	angle -= simmetry_angle
	return Vector2(cos(angle), sin(angle)) * vector.length()
