@tool
extends HBoxContainer

signal removed

const InfoBox = preload("res://addons/To-Do/SRC/TaskInfo.tscn")

@onready var line_edit = $"%LineEdit"

var data:Dictionary

func _ready() -> void :
	if not data.is_empty() :
		line_edit.text = data.name


func _on_DeleteButton_pressed():
	emit_signal("removed", data)
	queue_free()


func _on_InfoButton_pressed():
	var ins = InfoBox.instantiate()
	if data.is_empty() :
		ins.text = "data isn't available"
	else :
		var text = "Name : %s \n Start Time : %s \n Duration : %s \n End Time : %s \n"
		var formated_text = text%[data.name, data.start_time,
		data.duration, data.end_time]
		ins.text = formated_text
	$"../../..".add_child(ins)
