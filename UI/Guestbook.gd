extends Control

signal load_game_file
signal mouse_over
signal mouse_out
signal line_edit_mouse_entered
signal line_edit_mouse_exited

const ICON_SIZE = Vector2(75, 75)
@onready var grid = $ScrollContainer/Grid
@onready var signature_button = load("res://UI/signature.tscn")
@onready var line_edit = load("res://UI/line_edit.tscn")
var guest_book = {}
var exceptions = ["logs", "shader_cache"]
var name_entry

# Guestbook for loading user files


# Show current user folders
func view():
	
	var texture_script = Globals.texture_script.new()
	# Clear current optionsx
	if grid.get_child_count()>0:
		for child in grid.get_children():
			child.queue_free()
	
	
	var dir = DirAccess.open(Globals.user_directory)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			
			if file_name in exceptions:
				file_name = dir.get_next()
				continue
			
			# Load User folders
			if dir.current_is_dir():
				var button = signature_button.instantiate()
				button.text = file_name
				button.tooltip_text = "Load " + file_name
				button.mouse_entered.connect(_on_button_mouse_entered)
				button.mouse_exited.connect(_on_button_mouse_exited)
				button.pressed.connect(_user_selected.bind(file_name))
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

				var trash = Button.new()				
				set_stylebox_small(trash)
				trash.set_custom_minimum_size(ICON_SIZE)
				trash.tooltip_text = "Delete " + file_name
				trash.mouse_entered.connect(_on_button_mouse_entered)
				trash.mouse_exited.connect(_on_button_mouse_exited)
				trash.pressed.connect(_trash_selected.bind(file_name))
				trash.size_flags_horizontal = Control.SIZE_SHRINK_END
				trash.set_button_icon(texture_script.get_profile_icon("trash"))
				guest_book[file_name] = [button, trash]
				grid.add_child(button)
				grid.add_child(trash)
			
			file_name = dir.get_next()
		
		if guest_book.is_empty():
			$Label.text = "No game files yet!\nSign the guest book to start a new game."
		
	else:
		$Label.text = "Error: User folder not found"
		
	name_entry = line_edit.instantiate()
	name_entry.tooltip_text = "Sign your name"
	name_entry.mouse_entered.connect(_line_edit_mouse_entered)
	name_entry.mouse_exited.connect(_line_edit_mouse_exited)
	name_entry.text_submitted.connect(_new_selected)
	name_entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var button = Button.new()
	button.tooltip_text = "Create new file"
	set_stylebox_small(button)
	button.set_custom_minimum_size(ICON_SIZE)
	button.mouse_entered.connect(_on_button_mouse_entered)
	button.mouse_exited.connect(_on_button_mouse_exited)
	button.pressed.connect(_new_selected)
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.set_button_icon(texture_script.get_profile_icon("new"))
	grid.add_child(name_entry)
	grid.add_child(button)
	visible = true
	
# Load user file
func _user_selected(username):
	emit_signal("load_game_file", username)
	visible = false

# Start new game
func _new_selected():
	var line_text = name_entry.text
	
	# Invalid filename
	if line_text=="":
		$Label.text = "Please sign the guestbook."
		return
	if line_text in guest_book.keys():
		$Label.text = "%s is already in the guestbook.\nSign a new name or click %s to load file" % [line_text, line_text]
		return
	if !line_text.is_valid_filename():
		$Label.text = "%s is an invalid filename.\nUse a different name" % [line_text]
		return
		
	# Valid filename
	emit_signal("load_game_file", line_text)
	visible = false

# delete user directory
func _trash_selected(username, open_guestbook=true):
	
	# Remove all files in user directory
	var dir = DirAccess.open(Globals.user_directory+username)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir():
				dir.remove(file_name)
			file_name = dir.get_next()
				
	# Delete nodes
	if guest_book[username][0] in grid.get_children():
		guest_book[username][0].queue_free()
		guest_book[username][1].queue_free()
		
	guest_book.erase(username)
	# Remove user directory
	DirAccess.remove_absolute(Globals.user_directory+username)
	
	# Reload user files	
	if open_guestbook:
		view()

func _line_edit_mouse_entered():
	emit_signal("line_edit_mouse_entered")

func _line_edit_mouse_exited():
	emit_signal("line_edit_mouse_exited")

func _on_button_mouse_entered():
	emit_signal("mouse_over")
	
func _on_button_mouse_exited():
	emit_signal("mouse_out")

# Get stylebox for small buttons
func set_stylebox_small(button):
	
	for type in ["normal", "hover", "pressed"]:
		var stylebox = get_theme_stylebox("small_"+type, "Button")
		button.add_theme_stylebox_override(type, stylebox)
	
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Return true if case-insensitive name found in keys
func is_new_name(new_name):
	var keys = guest_book.keys()
	for key in keys:
		if key.to_upper() == new_name.to_upper():
			return false
	return true
