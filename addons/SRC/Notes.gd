@tool
extends TabBar


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
@onready var notes_v_box = $"%NotesVBox"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Sets up the dropdown, populating it with available tasks for evey note, an sets
# it to the task associated with the note, if it exists
func set_up_task_chooser(open_tasks:Array, completed_tasks:Array):
	for note in notes_v_box.get_children():
		# Set things to default
		note.task_chooser.clear()
		note.task_chooser.disabled = false
		note.content_edit.editable = true
		note.title_edit.editable = true
		note.linked_task_completed = false
		# First check if the note is associated with a completed task
		var found_completed_task:bool = false
		if completed_tasks.size() > 0:
			for completed_task in completed_tasks:
				# If yes, set everyhign to read only
				if note.linked_task == completed_task.id:
					note.task_chooser.add_item(completed_task.content + " (completed)", completed_task.id)
					note.task_chooser.select(0)
					note.task_chooser.disabled = true
					note.content_edit.editable = false
					note.title_edit.editable = false
					note.linked_task_completed = true
					found_completed_task = true
					break
					
		# If not completed task was associated with the note
		if not found_completed_task:
			# The first option allows for creating new notes without adding any task to them, This is the default
			note.task_chooser.add_item("(No associated task)", 0)
			# Then popupate the dropdown with available open tasks
			if open_tasks.size() > 0:
				for open_task in open_tasks:
					note.task_chooser.add_item(open_task.content, open_task.id)
				note.task_chooser.select(note.task_chooser.get_item_index(note.linked_task))
				note._on_TaskChooser_item_selected(note.task_chooser.get_item_index(note.linked_task))

