@tool
extends Control

signal save_external_data

##the file paths for the data files.
const tasks_save_path = "res://addons/To-Do/Data/tasks.json"
const notes_save_path = "res://addons/To-Do/Data/notes.json"

##loading note and task scenes.
const task = preload("res://addons/To-Do/SRC/Task.tscn")
const note = preload("res://addons/To-Do/SRC/Note.tscn")

@onready var task_edit = $"%TaskEdit"
@onready var tasks_v_box = $"%TasksVBox"
@onready var starred_tasks_v_box = $"%StarredTasksVBox"
@onready var completed_tasks_v_box = $"%CompletedTasksVBox"
@onready var starred_tasks_label = $"%StarredTasksLabel"
@onready var active_tasks_label = $"%ActiveTasksLabel"
@onready var completed_tasks_label = $"%CompletedTaskslabel"
@onready var open_focus_tasks = $"%OpenFocusTasks"
@onready var notes_v_box = $"%NotesVBox"
@onready var focus_timer = $"%FocusTimer"
@onready var notes_tab = $"%Notes"
@onready var tab_container = $"%TabContainer"
@onready var delete_all_tasks_button = $"%DeleteAllTasksButton"
@onready var delete_all_notes_button = $"%DeleteAllNotessButton"
@onready var delete_completed_tasks_button = $"%DeleteCompletedTasksButton"
@onready var notes_scroll_container = $"%NotesScrollContainer"

# Only to save empty when it's really empty. Had some problems losing all my tasks...
var tasks_are_empty:bool = true
var notes_are_empty:bool = true

# Incremental IDs for tasks. 
var running_task_id:int

##adda new task
func _on_AddButton_pressed():
	if task_edit.text != "" :
		tasks_are_empty = false
		running_task_id += 1
		var ins = task.instantiate()
		ins.content = task_edit.text
		# Small addition to the task data, to better connect with notes
		ins.id = running_task_id
		ins.is_starred = false
		
		ins.data = {
			"name" : task_edit.text,
			"addition_time" : Time.get_datetime_string_from_system(false, true),
			"state" : "Incompleted",
			"completion_time" : "..."
		}.duplicate()
		tasks_v_box.add_child(ins)
		# Movethe new task to the first position. More erginomic, and logical
		tasks_v_box.move_child(ins, 0)
		
		task_edit.text = ""
		

		ins.connect("state_changed", task_state_changed)
		ins.connect("content_changed", save_changes)
		
		# A ton of new signals for interaction with different parts
		ins.connect("task_removed", remove_task)
		ins.connect("move_up", move_task_up)
		ins.connect("move_down", move_task_down)
		ins.connect("start_task_timer", start_timer_from_task)
		ins.connect("stop_task_timer", stop_timer_from_task)
		ins.connect("note_button_pressed", task_note_button_pressed)
		ins.connect("favourite_pressed", task_starred)
		ins.connect("color_tag_changed", task_color_tag_changed)
		ins.favourite_button.button_pressed = false
#		sort_tasks()
		disable_up_down_buttons_at_edges()
		toggle_list_labels()
		save_changes()
		# Since we now have at least one task
		delete_all_tasks_button.disabled = false
#		delete_completed_tasks_button.disabled = false

# Moves task up one opsition
func move_task_up(ins):
	var pos = ins.get_index()
	# Probably unnecessary button should be disabled anyway
	if pos > 0:
		ins.get_parent().move_child(ins, pos - 1)
		# If the task is at the top, we don't need the up button
		disable_up_down_buttons_at_edges()

# Moves task down one opsition	
func move_task_down(ins):
	var pos = ins.get_index() 
	# Probably unnecessary button should be disabled anyway
	if pos < ins.get_parent().get_child_count() - 1:
		ins.get_parent().move_child(ins, pos + 1)
		# If it's the last incomplete task, it should not be able to move more
		disable_up_down_buttons_at_edges()



# Need to be able to stop any active focus timer associated with this task
# Not a very elegant solution, but it works. Unless the task name was changed, while focusing
func task_state_changed(task):
	if task.completed:
		if focus_timer.is_focusing:
			if focus_timer.task_name.text == task.content:
				focus_timer._on_StartFocus_pressed()
	
	# Remove task from wherever it is
	task.get_parent().remove_child(task)
	
	# And put it into the right container
	if task.completed:
		completed_tasks_v_box.add_child(task)
		completed_tasks_v_box.move_child(task, 0)
	else:
		if task.is_starred:
			starred_tasks_v_box.add_child(task)
		else:
			tasks_v_box.add_child(task)
		
	delete_completed_tasks_button.disabled = completed_tasks_v_box.get_child_count() == 0
	toggle_list_labels()
	disable_up_down_buttons_at_edges()
#	sort_tasks()


#This has become totally unnecessary now
#func sort_tasks():
#	var starred_tasks_tmp:Array = []
#	var incomplete_tasks_tmp:Array = []
#	var completed_tasks_tmp:Array = []
#
#	# Sort existing tasks into temporary arrays, then rremove them from the contianer
#	for task in tasks_v_box.get_children():
#		if task.completed:
#			completed_tasks_tmp.append(task)
#		else:
#			if task.is_starred:
#				starred_tasks_tmp.append(task)
#			else:
#				incomplete_tasks_tmp.append(task)
#		tasks_v_box.remove_child(task)
#
#	# Add back tasks from each array. Signals and data remain intact
#	for task in starred_tasks_tmp:
#		starred_tasks_v_box.add_child(task)
#	starred_tasks_tmp.clear()
#	for task in incomplete_tasks_tmp:
#		tasks_v_box.add_child(task)
#	incomplete_tasks_tmp.clear()
#	for task in completed_tasks_tmp:
#		completed_tasks_v_box.add_child(task)
#	completed_tasks_tmp.clear()
#
#	# Check the buttons
#	disable_up_down_buttons_at_edges()
#	save_changes()


func sort_notes():
	var unlinked_tmp:Array = []
	var linked_to_unfinished_tmp:Array = []
	var linked_to_completed_tmp:Array =[]
	
	
	for note in notes_v_box.get_children():
		if note.linked_task == 0:
			unlinked_tmp.append(note)
		else:
			if note.linked_task_completed:
				linked_to_completed_tmp.append(note)
			else:
				linked_to_unfinished_tmp.append(note)
		notes_v_box.remove_child(note)
		
	for note in unlinked_tmp:
		notes_v_box.add_child(note)
	unlinked_tmp.clear()
	for note in linked_to_unfinished_tmp:
		notes_v_box.add_child(note)
	linked_to_unfinished_tmp.clear()
	for note in linked_to_completed_tmp:
		notes_v_box.add_child(note)
	linked_to_completed_tmp.clear()
	
	load_predefined_tasks()
	save_changes()
		

		
# This is a lot neater and easier with less room for error.
# It will disable the up button for the first and the down button for the last task
# in every container
func disable_up_down_buttons_at_edges():
	if starred_tasks_v_box.get_child_count() == 1:
		starred_tasks_v_box.get_child(0).move_up_button.disabled = true
		starred_tasks_v_box.get_child(0).move_down_button.disabled = true
	else:
		for starred_task in starred_tasks_v_box.get_children():
			var pos = starred_task.get_position_in_parent()
			starred_task.move_up_button.disabled = pos == 0
			starred_task.move_down_button.disabled = pos == starred_tasks_v_box.get_child_count() - 1
	
	if tasks_v_box.get_child_count() == 1:
		tasks_v_box.get_child(0).move_up_button.disabled = true
		tasks_v_box.get_child(0).move_down_button.disabled = true
	else:
		for task in tasks_v_box.get_children():
			var pos = task.get_position_in_parent()
			task.move_up_button.disabled = pos == 0
			task.move_down_button.disabled = pos == tasks_v_box.get_child_count() - 1

	for completed_task in completed_tasks_v_box.get_children():
		completed_task.move_up_button.disabled = true
		completed_task.move_down_button.disabled = true
	save_changes()


##adds new note
func _on_NewNoteButton_pressed():
	# Zero beinng passed as the ID for "No task linked"
	add_new_note(0)

# Needed to separate this, so I can do it from the task, too
# It links the note to a passed task ID
func add_new_note(task_to_link:int):
	var ins = note.instantiate()
	# Added an identifier for the linked task
	ins.linked_task = task_to_link
	notes_v_box.add_child(ins)
	await get_tree().process_frame
	notes_v_box.move_child(ins, 0)
	notes_scroll_container.set_deferred("scroll_vertical", 0)
	# Scroll down to the newly added note.
	# Would probably be better to add notes to the top, as with tasks?
	ins.connect("state_changed", save_changes)
	ins.connect("note_removed", remove_note)
	delete_all_notes_button.disabled = false
	# This loads the available tasks into a picker on the task
	load_predefined_tasks()
	check_existing_task_notes()


##saves data to a file at a given path.
func _save(data, path:String) :
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


##loads data from a given path.
func _load(path:String) :
	var file = FileAccess
	if file.file_exists(path) :
		file = file.open(path, FileAccess.READ)
		var data = JSON.parse_string(file.get_as_text())
		file.close()
		return data


func _ready():
	load_tasks_and_notes()

# Moved this into a separate function for more flexibility
func load_tasks_and_notes():
	# We don't know of any existing IDs yet
	running_task_id =  1
	##makes sure every @onready var is set.
	for child in get_children() :
		child.connect("ready", child_ready)
	##removes all the tasks(if were).
	for t in tasks_v_box.get_children() :
		t.queue_free()
		await t.tree_exited
		
	for t in starred_tasks_v_box.get_children() :
		t.queue_free()
		await t.tree_exited
		
	for t in completed_tasks_v_box.get_children() :
		t.queue_free()
		await t.tree_exited
	var tasks_data = _load(tasks_save_path)
	var have_completed_tasks:bool = false
	if tasks_data != null :
		##loops trough evry task in the data.
		for t in tasks_data :
			var ins = task.instantiate()
			##sets the task vars to the values stored in the data file.
			ins.completed = t.completed
			if ins.completed:
				have_completed_tasks = true
			# For backward compatibility, for tasks created with previous versions, that did not
			# yet have ids assigned
			if t.has("is_starred"):
				ins.is_starred = t.is_starred
			else:
				ins.is_starred = false
			if t.has("id"):
				ins.id = t.id
			else:
				ins.id = running_task_id
				running_task_id += 1
			# So we can continue from the highest available ID for new tasks
			if running_task_id < ins.id:
				running_task_id = ins.id
			ins.content = t.content
			
			if t.has("color_tag"):
				ins.color_tag = t.color_tag
			else:
				ins.color_tag = ins.DEFAULT_BG_COLOUR
				
			if t.has("data") :
				ins.data = t.data.duplicate()
			
			# Put things into their appropriate containers
			if ins.completed:
				completed_tasks_v_box.add_child(ins)
			elif ins.is_starred:
				starred_tasks_v_box.add_child(ins)
			else:
				tasks_v_box.add_child(ins)
		
			ins.connect("state_changed", task_state_changed)
			ins.connect("content_changed", save_changes)
			ins.connect("task_removed", remove_task)
			ins.connect("move_up", move_task_up)
			ins.connect("move_down", move_task_down)
			ins.connect("start_task_timer", start_timer_from_task)
			ins.connect("stop_task_timer", stop_timer_from_task)
			ins.connect("note_button_pressed", task_note_button_pressed)
			ins.connect("favourite_pressed", task_starred)
			ins.connect("color_tag_changed", task_color_tag_changed)
			ins.favourite_button.button_pressed = ins.is_starred
		
		

	##just the same as above ;)
	for n in notes_v_box.get_children() :
		n.queue_free()
		await n.tree_exited
	var notes_data = _load(notes_save_path)
	if notes_data != null :
		for n in notes_data :
			var ins = note.instantiate()
			ins.content = n.content
			ins.title = n.title
			# For backward compatibility, for notes created with eralier versions that didn't 
			# yet include the linked_task ID
			if n.has("linked_task"):
				ins.linked_task = int(n.linked_task)
			else:
				# Zero means no associated task
				ins.linked_task = 0
			notes_v_box.add_child(ins)
			ins.connect("state_changed", save_changes)
			ins.connect("note_removed", remove_note)
	# Some necessary checks and stuff, as already seen above		
	if tasks_v_box.get_child_count() > 0 or starred_tasks_v_box.get_child_count() > 0 or completed_tasks_v_box.get_child_count() > 0:
		tasks_are_empty = false
#		sort_tasks()
		disable_up_down_buttons_at_edges()
		
		
		delete_all_tasks_button.disabled = false
	else:
		delete_all_tasks_button.disabled = true

	toggle_list_labels()
	#Disable the button if there are no completed tasks at load time
	delete_completed_tasks_button.disabled = completed_tasks_v_box.get_child_count() == 0

#	if is_instance_valid(notes_v_box):
	if notes_v_box.get_child_count() > 0 or starred_tasks_v_box.get_child_count() > 0 or completed_tasks_v_box.get_child_count() > 0:
		notes_are_empty = false
		delete_all_notes_button.disabled = false
		load_predefined_tasks()
		sort_notes()
	else:
		delete_all_notes_button.disabled = true
	check_existing_task_notes()

# only show the label, if for non-empty list containers
func toggle_list_labels():
	starred_tasks_label.visible = starred_tasks_v_box.get_child_count() > 0
	active_tasks_label.visible = tasks_v_box.get_child_count() > 0
	completed_tasks_label.visible = completed_tasks_v_box.get_child_count() > 0	

# Rewrote this to check all three containers
func check_existing_task_notes():
	for vbox in [starred_tasks_v_box, tasks_v_box, completed_tasks_v_box]:
		for task in vbox.get_children():
			task.set_has_note(false)
			for note in notes_v_box.get_children():
				if note.linked_task > 0:
					if task.id == note.linked_task:
						# Change the button for those tasks that have notes
						task.set_has_note(true)
						break

# Have a new version above
## Checks for every task in the task list if it has any notes linked to it
#func check_existing_task_notes():
#	if notes_v_box.get_child_count() > 0:
#		for task in tasks_v_box.get_children():
#			# Defaulting to not having anything
#			task.set_has_note(false)
#			for note in notes_v_box.get_children():
#				if note.linked_task > 0:
#					if task.id == note.linked_task:
#						# Change the button for those tasks that have notes
#						task.set_has_note(true)
#						break


# Does what it says. The save_after_removal boolean is used by mass-removal functions
# So it won't keep saving after every removed task.
func remove_task(task, save_after_removal:bool):
	var parent_v_box = task.get_parent()
	parent_v_box.remove_child(task)
	# Also delete the linked note
	
	for note in notes_v_box.get_children():
		if note.linked_task == task.id:
			remove_note(note, save_after_removal)
	task.queue_free()
	# I had to comment this out, it caused trouble
#	await task.tree_exited
	# Probably unnecessary, but won't hurt
	if tasks_v_box.get_child_count() == 0 and starred_tasks_v_box.get_child_count() == 0 and completed_tasks_v_box.get_child_count() == 0:
		tasks_are_empty = true
	else:
		disable_up_down_buttons_at_edges()
	parent_v_box = null
	# Optional, for mass removal (Remove all button), not to save after every note removed
	if save_after_removal:
		toggle_list_labels()
		save_changes()


func remove_note(note, save_notes_after_removal:bool):
	notes_v_box.remove_child(note)
	note.queue_free()
#	await note.tree_exited
	# Probably unnecessary, but won't hurt
	if notes_v_box.get_child_count() == 0:
		notes_are_empty = true
	# Optional, for mass removal (Remove all button), not to save after every note removed
	if save_notes_after_removal:
		save_changes()
		check_existing_task_notes()

##saves the data to a file.
func save_changes() :
	##defines an array var for data.
	var tasks_data = []
	# Go through each container and add any content found to the array
	for vbox in [starred_tasks_v_box, tasks_v_box, completed_tasks_v_box]:
		if is_instance_valid(vbox) :
			##loops trough every task.
			for t in tasks_v_box.get_children() :
				##gets the data of the task.
				var info = {
					"id": t.id, # For identifying atached notes
					"is_starred": t.is_starred, # favourites are marked with a srtar now
					"content" : t.content,
					"completed" : t.completed,
					"data" : t.data.duplicate(),
				}
				if not tasks_data.has(info) :
					##appends the data of the task to the whole data array.
					tasks_data.append(info)
		##saves the data to a file.
		# Since the save_changes called from exit_tree deleted all my stuff, I really only want to 
		# save an empty array when it was explicitly made empty
		if tasks_data.size() > 0 or tasks_are_empty:
			_save(tasks_data, tasks_save_path)
	##just the same as above ;)
	var notes_data = []
	if is_instance_valid(notes_v_box) :
		for n in notes_v_box.get_children() :
			var info = {
				"title" : n.title,
				"content" : n.content,
				"linked_task": n.linked_task
			}
			notes_data.append(info)
		# Since the save_changes called from exit_tree deleted all my stuff, I really only want to 
		# save an empty array when it was explicitly made empty
		if notes_data.size() > 0 or notes_are_empty:
			_save(notes_data, notes_save_path)


##saves the data before quiting or disabling the plugin.
func _exit_tree():
	# This sometimes overwrote my data with [] (empty data), see modifications in save_changes() to hopefully avoid this problem
	save_changes()

# Were there any problems with @onready?
func child_ready() -> void :
	task_edit = $"%TaskEdit"
	tasks_v_box = $"%TasksVBox"
	notes_tab = $"%Notes"


func _on_TaskEdit_text_entered(new_text):
	# Shouild add task when pressing enter
	_on_AddButton_pressed()

# Will load any incomplete tasks into the Timers doropdown menu
# Also passes them to the Notes tab, that can set up its notes
# (With completed notes as well)
func load_predefined_tasks() -> void:
	open_focus_tasks.clear()
	var open_tasks:Array = []
	var completed_tasks:Array = []
	# Add starred tasks first
	if starred_tasks_v_box.get_child_count() > 0:
		for task in starred_tasks_v_box.get_children():
			open_focus_tasks.add_item(task.content)
			open_tasks.append(task)
	# Then incomplete tasks
	if tasks_v_box.get_child_count() > 0:
		for task in tasks_v_box.get_children():
			
			open_focus_tasks.add_item(task.content)
			open_tasks.append(task)
	# And also completedtasks 9this will be used on the notes
	if completed_tasks_v_box.get_child_count() > 0:
		for task in completed_tasks_v_box.get_children():		
			completed_tasks.append(task)
	# The last option "Other..." will allow for entering any Title for focus timer
	open_focus_tasks.add_item("Other...")
	if is_instance_valid(notes_tab):
		notes_tab.set_up_task_chooser(open_tasks, completed_tasks)

# Do things when TabBar change
func _on_TabContainer_tab_changed(tab):
	save_changes()
	if tab > 0:
		#Both timer adn Notes might need this
		load_predefined_tasks()
		focus_timer.set_up_chooser()
		
	else:
		# Tasks need to know about their notes, in case new ones were added
		check_existing_task_notes()
	sort_notes()

# Will start a FreeFocus timer from the task's button, and change to that tab
func start_timer_from_task(task):
	var task_pos = task.get_index()
	tab_container.current_tab = 2
	focus_timer.focus_type_tabs.current_tab = 1
	focus_timer.open_focus_tasks.select(task_pos)
	focus_timer._on_OpenFocusTasks_item_selected(task_pos)
	focus_timer._on_StartFocus_pressed()
	
# Stops the above timer
func stop_timer_from_task(task):
	focus_timer._on_StartFocus_pressed()
	

# Change the button from stop to start on the appropriat task
func _on_FocusTimer_timer_stopped():
	if is_instance_valid(tasks_v_box):
		for task in tasks_v_box.get_children():
			task.start_timer_button.visible = true
			task.stop_timer_button.visible = false

# Does what it says. Should maybe add a confirmation dialogue
func _on_DeleteAllTasksButton_pressed():
	for vbox in [starred_tasks_v_box, tasks_v_box, completed_tasks_v_box]:
		if is_instance_valid(vbox):
			running_task_id = 1
			for task in vbox.get_children():
				remove_task(task, false)
	tasks_are_empty = true
	toggle_list_labels()
	save_changes()
	delete_all_tasks_button.disabled = true
	delete_completed_tasks_button.disabled = true

# Only delete completed tasks for housekeeping
func _on_DeleteCompletedTasksButton_pressed():
	if is_instance_valid(completed_tasks_v_box):
		for task in completed_tasks_v_box.get_children():
			remove_task(task, false)
		toggle_list_labels()
		save_changes()
		delete_completed_tasks_button.disabled = true

# Does what it says. Should maybe add a confirmation dialogue
func _on_DeleteAllNotessButton_pressed():
	if is_instance_valid(notes_v_box):
		for note in notes_v_box.get_children():
			remove_note(note, false)
		notes_are_empty = true
		save_changes()
		delete_all_notes_button.disabled = true

# Checks if task has associatd note. If found, it will attep to scroll down
# to that note after changing the tab, it not, it will add a new note
# associating it with the task
func task_note_button_pressed(task):
	tab_container.current_tab = 1
	var has_note:bool = false
	for note in notes_v_box.get_children():
		if note.linked_task == task.id:
			notes_scroll_container.set_v_scroll(0)
			notes_scroll_container.call_deferred("ensure_control_visible", note)
			has_note = true
			break
			
	if not has_note:
		task.set_has_note(true)
		add_new_note(task.id)
		
# Should probably be called "toggle_task_starred". It will mark or unmark a task as starred 
# and move it to the appropriate container
func task_starred(task, is_starred):
	if is_starred:
		tasks_v_box.remove_child(task)
		starred_tasks_v_box.add_child(task)
		starred_tasks_v_box.move_child(task, 0)
	else:
		starred_tasks_v_box.remove_child(task)
		tasks_v_box.add_child(task)
		tasks_v_box.move_child(task, 0)
#	sort_tasks()
	toggle_list_labels()
	disable_up_down_buttons_at_edges()
	

# _task and _color_tag are not yet used, but added for future
func task_color_tag_changed(_task, _color_tag):
	save_changes()
	load_predefined_tasks()
