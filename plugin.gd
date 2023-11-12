@tool
extends EditorPlugin

const MainControl = preload("res://addons/To-Do/SRC/Main.tscn")
var ins:Control

func _enter_tree():
	ins = MainControl.instantiate()
	add_control_to_bottom_panel(ins, "To-Do")


func _exit_tree():
	remove_control_from_bottom_panel(ins)
	if is_instance_valid(ins) :
		ins.queue_free()


func get_plugin_name()-> String:
	return "To-Do"


func _save_external_data() :
	if is_instance_valid(ins) :
		ins.emit_signal("save_external_data")
