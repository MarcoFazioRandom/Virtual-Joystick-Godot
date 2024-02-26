@tool
extends Control

var scene

func _enter_tree():
	scene = preload("res://addons/virtual_joystick/virtual_joystick_scene.tscn").instantiate()
	add_child(scene)
	
	if ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch"):
		printerr("The Project Setting 'emulate_mouse_from_touch' should be set to False")
	if not ProjectSettings.get_setting("input_devices/pointing/emulate_touch_from_mouse"):
		printerr("The Project Setting 'emulate_touch_from_mouse' should be set to True")


func _exit_tree():
	scene.free()
