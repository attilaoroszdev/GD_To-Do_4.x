@tool
extends Panel

signal state_changed()
signal note_removed(note, save)

const DEFAULT_BORDER_COLOUR = "#202531"
const DEFAULT_BG_COLOUR = "#262c3b"
const DEFAULT_PICKER_RECT_COLOUR = "#2a3142"
const TASK_BG_ALPHA:float = 0.06
const TASK_BORDER_ALPHA:float = 0.6

@onready var title_edit = $"%Title"
@onready var container = $"%VBoxContainer"
@onready var content_edit = $"%Content"
@onready var save_button = $"%SaveButton"
@onready var task_chooser = $"%TaskChooser"

var title:String
var content:String
var linked_task:int = 0
var linked_task_completed:bool = false # No need to save this, it will be dynamically assigned on load
var new_stylebox_normal
var new_stylebox_disabled
var task_colours:Array = []

func _on_DeleteButton_pressed():
	emit_signal("note_removed", self, true)


func _on_Content_text_changed():
	content = content_edit.text
#	I really don't want to call save on every keypress.
#	Will save on gtab change or on exit
#	emit_signal("state_changed")
	# Save button is hidden for now, but it's there
	save_button.disabled = false



func _on_Title_text_changed(new_text):
	title = new_text
	# Save button is hidden for now, but it's there
	save_button.disabled = false


func _ready():
	new_stylebox_normal = task_chooser.get_theme_stylebox("normal").duplicate()
	new_stylebox_disabled = task_chooser.get_theme_stylebox("disabled").duplicate()
	title_edit.text = title
	content_edit.text = content
	
	

# Button hidden, but it could be enabled
func _on_SaveButton_pressed():
	emit_signal("state_changed")
	save_button.disabled = true



# This is where we save thigns, when the user clicks anywhere else
func lost_focus():
	emit_signal("state_changed")
	save_button.disabled = true


# Associates the Note with an existing open task. I made the Title read-only, os the Note
# Will be identified by the assigned task only (less confusing, could be changed)
func _on_TaskChooser_item_selected(index):
	linked_task = task_chooser.get_item_id(index)
	if index > 0:
		title = "Notes for task:"
		title_edit.text = title
		title_edit.editable = false
		set_colour_tag(linked_task)
	else:
		title_edit.text = title
		title_edit.editable = true
		set_colour_tag(0)
		
	emit_signal("state_changed")
	save_button.disabled = true



# Set the task chooser's colour to the note's colour tag
func set_colour_tag(index:int):
	var color_tag = DEFAULT_BG_COLOUR

	if index == 0:
		color_tag = DEFAULT_BG_COLOUR
	else:
		for n in range(task_colours.size()):
			# The array: task_colours[[task_id],[color_tag]]
			# Set the color tag if the id matches
			if task_colours[n][0] == index:
				color_tag = task_colours[n][1]
				break

	if color_tag == DEFAULT_BG_COLOUR:
		new_stylebox_normal.border_color = Color(DEFAULT_BORDER_COLOUR)
		new_stylebox_normal.bg_color = Color(DEFAULT_BG_COLOUR)
	else:
		var new_border_color = Color(color_tag)
		new_border_color.a = TASK_BORDER_ALPHA
		new_stylebox_normal.border_color = new_border_color
		var new_bg_color = Color(color_tag)
		new_bg_color.a = TASK_BG_ALPHA
		new_stylebox_normal.bg_color = new_bg_color
	
	task_chooser.add_theme_stylebox_override("normal", new_stylebox_normal)


# There isno need to look things up, the chooser is disabled, so color can be static
func set_completed_color_tag(color_tag):
	if color_tag == DEFAULT_BG_COLOUR:
		new_stylebox_disabled.border_color = Color(DEFAULT_BORDER_COLOUR)
	else:
		var new_border_color = Color(color_tag)
		new_border_color.a = TASK_BORDER_ALPHA
		new_stylebox_disabled.border_color = new_border_color
	
	task_chooser.add_theme_stylebox_override("disabled", new_stylebox_disabled)
