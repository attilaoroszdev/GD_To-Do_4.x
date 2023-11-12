@tool
extends Panel

signal state_changed()
signal note_removed(note, save)

@onready var title_edit = $"%Title"
@onready var content_edit = $"%Content"
@onready var save_button = $"%SaveButton"
@onready var task_chooser = $"%TaskChooser"
var title:String
var content:String
var linked_task:int = 0
var linked_task_completed:bool = false # No need to save this, it will be dynamically assigned on load

func _on_DeleteButton_pressed():
	emit_signal("note_removed", self, true)
	# I want to save things before freeing the Task node
#	queue_free()


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

	else:
		title_edit.text = title
		title_edit.editable = true
		
	emit_signal("state_changed")
	save_button.disabled = true
