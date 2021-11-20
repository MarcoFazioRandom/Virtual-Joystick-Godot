# https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot

extends Control

class_name VirtualJoystick

#### EXPORTED VARIABLE ####

# The color of the button when the joystick is in use.
export(Color) var _pressed_color := Color.gray

# If the input is inside this range, the output is zero.
export(float, 0, 100, 1) var deadzone_size : float = 10

# The max distance the handle can reach.
export(float, 0, 300, 1) var clampzone_size : float = 75

# FIXED: The joystick doesn't move.
# DYNAMIC: Every time the joystick area is pressed, the joystick position is set on the touched position.
enum JoystickMode {FIXED, DYNAMIC}

export(JoystickMode) var joystick_mode := JoystickMode.FIXED

# VISIBILITY_ALWAYS = Always visible.
# VISIBILITY_TOUCHSCREEN_ONLY = Visible on touch screens only.
enum VisibilityMode {ALWAYS , TOUCHSCREEN_ONLY }

export(VisibilityMode) var visibility_mode := VisibilityMode.ALWAYS

# Use Input Actions
export var use_input_actions := true

# Project -> Project Settings -> Input Map
export var action_left := "ui_left"
export var action_right := "ui_right"
export var action_up := "ui_up"
export var action_down := "ui_down"

#### OUTPUT VARIABLES ####

# If the joystick is receiving inputs.
var _pressed := false setget , is_pressed

func is_pressed() -> bool:
	return _pressed

# The joystick output.
var _output := Vector2.ZERO setget , get_output

func get_output() -> Vector2:
	return _output

#### PRIVATE VARIABLES ####

onready var _base := $Base
onready var _tip := $Base/Tip
onready var _base_texture_ray_size : float = $Base/TextureRect.rect_size.x / 2
onready var _original_color : Color = _tip.modulate
onready var _new_tip_position : Vector2 = _tip.rect_position

var _touch_index : int = -1

#### FUNCTIONS ####

func _ready() -> void:
	if not OS.has_touchscreen_ui_hint() and visibility_mode == VisibilityMode.TOUCHSCREEN_ONLY:
		hide()

func _gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1:
			if joystick_mode == JoystickMode.DYNAMIC:
				_base.rect_position = event.position
			if joystick_mode == JoystickMode.DYNAMIC or (joystick_mode == JoystickMode.FIXED and _is_touch_inside_base(event.position)):
				accept_event()
				_touch_index = event.index
				_tip.modulate = _pressed_color
				_update_joystick(event.position)
		elif not event.pressed and _touch_index == event.index:
			accept_event()
			_reset()
	if event is InputEventScreenDrag and _touch_index == event.index:
		accept_event()
		_update_joystick(event.position)

func _is_touch_inside_base(touch_position: Vector2) -> bool:
	var vector : Vector2 = (touch_position - _base.rect_position) / _base.rect_scale
	if vector.length_squared() <= _base_texture_ray_size * _base_texture_ray_size:
		return true
	else:
		return false

func _update_joystick(touch_position: Vector2) -> void:
	var vector = (touch_position - _base.rect_position) / _base.rect_scale
	vector = vector.clamped(clampzone_size)
	_new_tip_position = vector
	_output = vector / clampzone_size
	if vector.length_squared() >= deadzone_size * deadzone_size:
		_pressed = true
		_output = (vector - (vector.normalized() * deadzone_size)) / (clampzone_size - deadzone_size)
	else:
		_pressed = false
		_output = Vector2.ZERO
	if use_input_actions:
		_update_input_actions()

func _update_input_actions():
	if _output.x < 0:
		Input.action_press(action_left, -_output.x)
	elif Input.is_action_pressed(action_left):
		Input.action_release(action_left)
	if _output.x > 0:
		Input.action_press(action_right, _output.x)
	elif Input.is_action_pressed(action_right):
		Input.action_release(action_right)
	if _output.y < 0:
		Input.action_press(action_up, -_output.y)
	elif Input.is_action_pressed(action_up):
		Input.action_release(action_up)
	if _output.y > 0:
		Input.action_press(action_down, _output.y)
	elif Input.is_action_pressed(action_down):
		Input.action_release(action_down)

func _reset():
	_pressed = false
	_output = Vector2.ZERO
	_new_tip_position = Vector2.ZERO
	_tip.rect_position = Vector2.ZERO
	_touch_index = -1
	_tip.modulate = _original_color
	if use_input_actions:
		if Input.is_action_pressed(action_left) or Input.is_action_just_pressed(action_left):
			Input.action_release(action_left)
		if Input.is_action_pressed(action_right) or Input.is_action_just_pressed(action_right):
			Input.action_release(action_right)
		if Input.is_action_pressed(action_down) or Input.is_action_just_pressed(action_down):
			Input.action_release(action_down)
		if Input.is_action_pressed(action_up) or Input.is_action_just_pressed(action_up):
			Input.action_release(action_up)

func _process(_delta):
	_tip.rect_position = _new_tip_position
