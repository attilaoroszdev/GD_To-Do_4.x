@tool
extends HBoxContainer

signal state_changed(task)
signal content_changed()
signal task_removed(task, save)
signal move_up(task)
signal move_down(task)
signal start_task_timer(task)
signal stop_task_timer(task)
signal note_button_pressed(task)
signal favourite_pressed(task, starred)

const InfoBox = preload("res://addons/To-Do/SRC/TaskInfo.tscn")

@export var content:String
@onready var label = $LineEdit
@onready var check_box = $CheckBox
@onready var move_up_button = $"%MoveUpButton"
@onready var move_down_button = $"%MoveDownButton"
@onready var start_timer_button = $"%TimerStartButton"
@onready var stop_timer_button = $"%TimerStopButton"
@onready var task_note_button = $"%TaskNoteButton"
@onready var favourite_button = $"%FavouriteButton"

var note_icon = preload("res://addons/To-Do/Icons/File.svg")
var new_note_icon = preload("res://addons/To-Do/Icons/New.svg")
var id:int
var completed := false
var has_note:bool = false
var data:Dictionary
var is_starred:bool = false

func _ready():
	label.text = content
	check_box.button_pressed = completed
	label.editable = not completed
	favourite_button.button_pressed = is_starred
	if data.is_empty() :
		print("data empty")
		data = {
			"name" : content,
			"addition_time" : "...",
			"state" : "Completed" if completed else "Incomplete",
			"completion_time" : "..."
		}
	data.state = "Completed" if completed else "Incomplete"


func _on_CheckBox_toggled(button_pressed):
	completed = button_pressed
	if not data.is_empty() :
		if completed :
#			is_starred = false
#			favourite_button.button_pressed = false
			favourite_button.visible = false
			label.editable = false
			move_up_button.disabled = true
			move_down_button.disabled = true
			start_timer_button.disabled = true
			data.state = "Completed"
			if data.completion_time == "..." :
				data.completion_time = Time.get_datetime_string_from_system(false, true)
		else :
			favourite_button.visible = true
			label.editable = true
			move_up_button.disabled = false
			move_down_button.disabled = false
			start_timer_button.disabled = false
			data.state = "Incomplete"
			if not data.completion_time == "..." :
				# there was a tpypo preventing "completion time to be reset to "..."
				data.completion_time = "..."

	# I want to save regardless. E.g. if I re-enable a previously completed task (changed my mind, forgot something)
#	if button_pressed == completed :
#		return
	# Sets the View/add note button
	set_has_note(has_note)
	
	emit_signal("state_changed", self)


func _on_DeleteButton_pressed():
	emit_signal("task_removed", self, true)
	# Want to save things upon deletion, and maybe do other thigns.
	# It wil be freed from the parent
#	queue_free()


func _on_LineEdit_text_changed(new_text):
	if new_text == content :
		return
	content = new_text
	emit_signal("content_changed")


func _on_InfoButton_pressed():
	var ins = InfoBox.instantiate()
	
	if data.is_empty() :
		ins.text = "data isn't available"
	else :
		var text = "Name : %s \n Addition Time : %s \n State : %s \n Completion Time : %s \n"
		var formated_text = text%[data.name, data.addition_time,
		data.state, data.completion_time]
		ins.text = formated_text
	
	$"../../..".add_child(ins)

# Does what it says
func _on_MoveUpButton_pressed():
	emit_signal("move_up", self)

# Does what it says
func _on_MoveDownButton_pressed():
	emit_signal("move_down", self)

# Does what it says
func _on_TimerStartButton_pressed():
	start_timer_button.visible = false
	stop_timer_button.visible = true
	emit_signal("start_task_timer", self)

# Does what it says
func _on_TimerStopButton_pressed():
	start_timer_button.visible = true
	stop_timer_button.visible = false
	emit_signal("stop_task_timer", self)

# Not even using this, dunno why it's there
func set_task_id(value):
	id = value

# Not even using this, dunno why it's there	
func get_task_id() -> int:
	return id

# Does what it says
func _on_TaskNoteButton_pressed():
	emit_signal("note_button_pressed", self)

# Set up task-note button and tooltip
func set_has_note(value:bool):
	has_note = value
	if has_note:
		task_note_button.icon = note_icon
		
		task_note_button.disabled = false
		if completed:
			task_note_button.tooltip_text = "View note linked to this task (read only)"
		else:
			task_note_button.tooltip_text = "View and edit note linked to this task"
	else:
		
		task_note_button.disabled = completed
		if completed:
			task_note_button.icon = note_icon
			task_note_button.tooltip_text = "Cannot assign notes to completed tasks"
		else:
			task_note_button.icon = new_note_icon
			task_note_button.tooltip_text = "Add new note linked to this task"


func _on_FavouriteButton_toggled(button_pressed):
	is_starred = button_pressed
	
	if is_starred:
		move_down_button.disabled = true
		move_up_button.disabled = true
	else:
		move_down_button.disabled = false
		move_up_button.disabled = false
	emit_signal("favourite_pressed", self, is_starred)

