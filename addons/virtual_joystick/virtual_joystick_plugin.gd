@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("Virtual Joystick", "Control", preload("virtual_joystick_instantiator.gd"), preload("virtual_joystick_icon.png"))


func _exit_tree():
	remove_custom_type("Virtual Joystick")
