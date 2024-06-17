extends Control

signal mouse_over
signal mouse_out
signal line_edit_mouse_entered
signal line_edit_mouse_exited
signal save_game
signal load_game_file
signal rename_game_file
signal toggle_mouse_tail
signal change_mouse_tail_variables

# Globals.player settings stored in Globals.player resource file
var settings:Dictionary
var known_npcs:Array
var player_name:String
var just_saved = false
var numbers = []
var inventory_visible = false
var image_preview

var warnings = {"reload":"You haven't saved this file.\nTo Save: Click the 'Guestbook' or 'Save + Close'\
	\nTo Overwrite: Click 'Confirm'",
	"rename":"Rename %s to %s?\n To change the name, Click Confirm"} 


################## Load Data From File ########################
# called every time a game file is loaded (or started new), and every \
# time profile visibility is toggled on

# If necessary to reload Globals.player inventory in knapsack, do so here
func show_profile(image=null):
	
	if image != null:
		load_screenshot(image)
	
	if numbers.is_empty():
		create_images()
	
	# Set PlayerName and tickets
	player_name = Globals.player.player_name
	$Panel/PlayerName.text = Globals.player.player_name
	var custom_cursor_box = $"Panel/Settings/Custom Cursor Box"
	custom_cursor_box.get_node("MouseTailCheck").button_pressed = Globals.player.mouse_trail_enabled
	set_ticket_textures(Globals.player.tickets)
	set_settings(Globals.player.settings, Globals.player.unlocked_cursors)
	
	$Warning.visible = false
	visible = true
	
	
	if Globals.player.mouse_trail_enabled:
		var mouse_settings_node = $Panel/Settings/MouseTailOptions/GridContainer
		mouse_settings_node.get_node("SpinBox").value = settings["mouse_tail_length"]-2
		mouse_settings_node.get_node("ActButton").selected = settings["mouse_tail_action"]
		



#################### Save Current Game ###########################

	# Quit to desktop

################# Save and Close ######################################
func _on_close_pressed():
	await check_for_rename()
	emit_signal("save_game", true)
	
	# Quit to guestbook
func _on_guestbook_pressed():
	Globals.switch_mouse(0)
	await check_for_rename()
	emit_signal("save_game", false)
	visible = false

	

func get_player_settings():
	return settings
	

# Reload previous save state
func _on_last_place_pressed():
	if !just_saved:
		$Warning/MarginContainer/Label.text = warnings["reload"]
		$Warning.set_meta("warning", "reload")
		$Warning.popup_centered()
	else:
		$Warning.set_meta("warning", "reload")
		warning_confirmed(true)

########################## Rename Globals.player file ############################

func check_for_rename():
	if !(player_name == $Panel/PlayerName.text):
		_on_player_name_text_submitted($Panel/PlayerName.text)
		await $Warning.visibility_changed
	return true

func _on_player_name_text_submitted(new_text):
	if ($Panel/PlayerName.text.is_valid_filename() and $Panel/PlayerName.text!=""):
		$Warning/MarginContainer/Label.text = warnings["rename"] % [player_name, new_text]
		$Warning.set_meta("warning", "rename")
		$Warning.popup_centered()
	else:
		show_error("Enter a Valid filename")

############################## Mouse Inputs #################################

func _on_input_mouse_entered():
	emit_signal("mouse_over")

func _on_input_mouse_exited():
	emit_signal("mouse_out")

# Settings values updated: update dict and change settings
func _on_settings_drag_ended(value_changed, setting_type):
	var setting_node = $Panel/Settings.get_node_or_null(setting_type)
	if value_changed and (setting_node != null):		
		settings[setting_type] = setting_node.value
		
		# Set sounds
		if setting_node.is_in_group("AudioSliders"):
			var bus_idx = 0
			if setting_type in ["Sound Effects", "Music", "Ambient"]:
				bus_idx = AudioServer.get_bus_index(setting_type)
		
			AudioServer.set_bus_volume_db(bus_idx, float(setting_node.value))
		setting_node.release_focus()
			

func _line_edit_mouse_entered():
	emit_signal("line_edit_mouse_entered")

func _line_edit_mouse_exited():
	emit_signal("line_edit_mouse_exited")


########################## Load Image + Setting Data ##################################
	
# Create number images for ticket graphic
func create_images():
	var icon_size = 75
	for i in range(10):
		if i == 0:
			numbers.append(load(Globals.profile_number_path))
		else:
			var new_texture = load(Globals.profile_number_path).duplicate(true)				
			new_texture.region = Rect2(i * icon_size, 525, icon_size, icon_size)
			numbers.append(new_texture)

func set_ticket_textures(arg):
	var ticket_box = $Panel/Tickets/Box 
	var ticket_int:int = arg
	
	if ticket_box.has_meta("last_entry"):
		if ticket_box.get_meta("last_entry")==ticket_int:
			return
	
	for child in ticket_box.get_children():
		child.queue_free()
	
	var digits = Array(str(ticket_int).split())
	var i = digits.size()-1
	while i >= 0:
		var num_texture = TextureRect.new()
		var idx = int(digits[i])
		var texture = numbers[idx]
		num_texture.set_texture(texture)
		num_texture.set_stretch_mode(TextureRect.STRETCH_KEEP_CENTERED)
		ticket_box.add_child(num_texture)
		i -= 1
		
	ticket_box.set_meta("last_entry", ticket_int)

func set_settings(settings, unlocked_cursors):
	for key in settings.keys():
		var set_node = $Panel/Settings.get_node_or_null(key)
		if set_node != null:
			set_node.value = settings[key]
			if set_node.is_in_group("AudioSliders"):
				set_node.min_value = -80
				set_node.max_value = 24
		
		# Load Custom Mouse textures + tail
		if key == "Cursor":

			for node in $Panel/Settings.get_node("Custom Cursor Box").get_children():
				if node.is_in_group("CursorButtons"):
					node.queue_free()
				
			
			# Load Globals.player's last chosen cursor
			Globals.switch_mouse(settings["Cursor"])
			for i in range(Globals.mouse_cursor_count):
				var is_unlocked = i in unlocked_cursors
				var button = TextureButton.new() 
				var textures = Globals.get_mouse_icons(i)
				button.texture_normal = textures[0]
				button.texture_hover = textures[1]
				button.texture_pressed = textures[1]
				button.pressed.connect(_change_cursor_pressed.bind(i))
				button.self_modulate = [Color(0, 0, 0, 1), Color(1, 1, 1, 1)][int(is_unlocked)]
				button.disabled = !is_unlocked
				button.add_to_group("CursorButtons")
				$Panel/Settings.get_node("Custom Cursor Box").add_child(button)
	
func load_screenshot(image):
	# Load screenshot from image
	if image != null:
		var texture = ImageTexture.create_from_image(image)
		texture.set_size_override(Vector2i(640, 400))
		$Panel/LastPlace.texture_normal = texture


# Close the profile without loading a scene
func _on_tab_pressed():
	visible = false

################################################################################
########################### Icon/Button Inputs ##################################
################################################################################

########################### Mouse Cursor/Tail ##################################

func _change_cursor_pressed(idx):
	Globals.switch_mouse(idx)
	settings["Cursor"] = idx

func _on_mouse_tail_check_pressed():
	var on = $"Panel/Settings/Custom Cursor Box/MouseTailCheck".button_pressed
	var label = $"Panel/Settings/Custom Cursor Box/MouseTailLabel"
	emit_signal("toggle_mouse_tail", on)
	$Panel/Settings/MouseTailOptions.visible = on

# Change Mouse tail Variables
func _on_act_button_item_selected(index):
	emit_signal("change_mouse_tail_variables", "mouse_tail_action", index)
		
func _on_spin_box_value_changed(value):
	emit_signal("change_mouse_tail_variables", "mouse_tail_length", value+2)

func _on_mouse_tail_close_pressed():
	$Panel/Settings/MouseTailOptions.visible = false

# Save Mouse Tail Options to Settings
func _on_mouse_tail_options_hidden():
	var mouse_settings_node = $Panel/Settings/MouseTailOptions/GridContainer
	settings["mouse_tail_length"] = mouse_settings_node.get_node("SpinBox").value
	settings["mouse_tail_action"] = mouse_settings_node.get_node("ActButton").get_selected()

############################ Errors and Warnings #########################

func show_error(error_text):
	$Warning/MarginContainer/Label.text = error_text
	$Warning.set_meta("warning", "_")
	$Warning.popup_centered()

# Warning prompt confirmed
func _on_confirm_pressed():
	warning_confirmed(true)

# Warning prompt denied
func _on_warning_popup_hide():
	warning_confirmed(false)

func warning_confirmed(cont):
	var type = $Warning.get_meta("warning")
	if cont:	
		match type:
			"reload":
				emit_signal("load_game_file")
				visible = false
			"rename":
				emit_signal("rename_game_file", player_name, $Panel/PlayerName.text)
				visible = false

	else:
		if type=="rename":
			$Panel/PlayerName.text = player_name
			
	$Warning.hide()


############################### Open/Close Knapsack ######################## 

func _on_knapsack_pressed():
	$Knapsack.visible = !$Knapsack.visible

func _on_close_knapsack_pressed():
	$Knapsack.visible = false


################################# Set Styles ##################################
func _on_child_entered_tree(node):
	if node == $TAB:	
		# Set close-panel stylebox
		for type in ["normal", "hover", "pressed"]:
			var stylebox = get_theme_stylebox("small_"+type, "Button")
			$TAB.add_theme_stylebox_override(type, stylebox)

func _on_custom_cursor_box_child_entered_tree(node):
	for node_name in ["MouseTailLabel", "MouseTailCheck"]:
		var ui_node = $"Panel/Settings/Custom Cursor Box".get_node(node_name)
		$"Panel/Settings/Custom Cursor Box".move_child.call_deferred(ui_node, -1)


