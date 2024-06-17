extends InteriorScenes

var open_shop = false

var current_vessel
# Vessels aligned on canvas
@export var lineup = []
var LINEUP_RECT = Rect2(200, 750, 1200, 120)
var MAX_VESSELS = 7

# Vessels relative position based on workspace
var workspace_vessels = []

var alert_labels = {'trash':"Send to Trash?"}
var refresh = 0

func set_ui_color():
	ui_color = Color.PINK
	
func set_sub_scenes():
	sub_scenes = ["Blender/Blender.tscn", "Orders/Window.tscn", "Toppings/ToppingsHub.tscn", "IceCream/Dispenser.tscn", "Soda/Dispenser.tscn", "Syrups/SyrupsHub.tscn"]
	
func set_game_path():
	game_path = "res://IceCream/"
	

# connect subgame to Ice Cream Int methods
func connect_to_signals(game, game_index):
	var callable = 	[_set_vessel_blend_data, _set_vessel_customer_data, _set_vessel_toppings_data, _set_ice_cream_data, _set_soda_data, _set_syrup_data][game_index]
	if !game.set_data.is_connected(callable):
		game.set_data.connect(callable)
	# In blender : move vessel up/down
	if game_index == 0:
		if !game.move_vessel.is_connected(_move_vessel_y):
			game.move_vessel.connect(_move_vessel_y)	
	
	super.connect_to_signals(game, game_index)
	
# Add Active areas based on current scene
func set_new_active_scene(idx):
	
	
	var sub_game = pixel_world.get_sub_game()
	
	# Do not switch scene while it is locked
	if sub_game!=null:
		if sub_game.locked:
			return
	
	# Do not switch scene while there is a locked vessel on canvas
	if current_vessel != null:
		if current_vessel.is_locked():
			return
	super.set_new_active_scene(idx)
	set_active_areas()
	# For Toppings Hub: Start new round
	if idx == 2:
		pixel_world.get_sub_game().new_round()
		
	
	
func _carry_over(node, pos, permanent=true):
	
	var sub_game = pixel_world.get_sub_game()

	match active_scene_idx:
		2:
			# Free topping Icon in same Carryover space
			for child in $CarryOver/Nodes.get_children():
				if child.global_position.is_equal_approx(pos):
					child.queue_free()
		
		5:
			# If syrups hub: disconnect carryover node from game signals
			if active_scene_idx==5:
				sub_game.disconnect_vessel(node)

	# If CarryOver is vessel, set active areas
	if node.is_in_group("vessels"):
		set_all_areas(node)
		node.change_scale("foreground")
		# Connect to signals
		if !node.select_me.is_connected(_select_vessel):
			node.select_me.connect(_select_vessel)
		if !node.out_of_bounds.is_connected(_vessel_out_of_bounds):
			node.out_of_bounds.connect(_vessel_out_of_bounds)
		if current_vessel==null:
			_select_vessel(node)
		else:
			_animate_entry(node)
	super._carry_over(node, pos, permanent)
	
func _carry_back(node):
	if node.is_in_group("vessels"):
		if node.select_me.is_connected(_select_vessel):
			node.select_me.disconnect(_select_vessel)
		if node.out_of_bounds.is_connected(_vessel_out_of_bounds):
			node.out_of_bounds.disconnect(_vessel_out_of_bounds)
		
		if node==current_vessel:
			current_vessel=null
		if node in lineup:
			lineup.erase(node)
			
	
		if active_scene_idx==5:
			# If syrups hub: connect carryback node to game signals
			pixel_world.get_sub_game().connect_vessel(node)
			
	super._carry_back(node)

# Set all area values from subgames in node
func set_all_areas(node):
	node.set_area("lineup", LINEUP_RECT)
	var i = 0
	while i < sub_scenes.size():
		var area_dict = open_games[i].get_areas()
		for key in area_dict.keys():
			node.set_area(key, area_dict[key])
		i += 1

# Set active areas for current subgame in current vessel
func set_active_areas():
	if current_vessel != null:
		current_vessel.frame = Globals.bigframe
		current_vessel.active_areas.clear()
		current_vessel.active_areas = [LINEUP_RECT]
		var areas = pixel_world.get_sub_game().areas.values()
		for area in areas:
			current_vessel.active_areas.append(area)

func _animate_entry(node):
	var arg1 = Vector2(LINEUP_RECT.position.x + LINEUP_RECT.size.x, LINEUP_RECT.position.y+LINEUP_RECT.size.y)
	var arg2 = lineup
	var arg3 = -140
	
	node.change_scale("foreground")
	var next_open_position = get_next_open_position(arg1, arg2, arg3)
	var time = next_open_position.distance_to(node.position)/float(10*node.speed)
	var tween = create_tween()
	tween.tween_property(node, "position", next_open_position, time).set_trans(Tween.TRANS_ELASTIC)
	
	lineup.append(node)
	if node==current_vessel:
		current_vessel=null


# Return next open position on apple rack
func get_next_open_position(initial_pos, array, step):
	var pos = initial_pos
	for a in range(0, array.size()):
		pos.x += step
		var tween = create_tween()
		tween.tween_property(array[a], "position", pos, float((array.size()-a)*.5)).set_trans(Tween.TRANS_QUAD)
	pos.x += step
	return pos

func _move_vessel_y(pos):
	if current_vessel != null:
		current_vessel.position.y += pos
		


# Selecting a node transfers all gui inputs to this class
func _select_vessel(node):
	if !$Control.gui_input.is_connected(_on_control_gui_input):
		$Control.gui_input.connect(_on_control_gui_input)
	if lineup == null:
		lineup = []

	if current_vessel != null:
		# Do not select another vessel if current one is locked
		if current_vessel.is_locked():
			return

		deselect_vessel()

	# select vessel which is placed at index in subgame
	if (node in workspace_vessels):
		if active_scene_idx==3||active_scene_idx==4:
			var sub_game = pixel_world.get_sub_game()
			var meta_index = "ice_cream"
			if active_scene_idx==4: 
				meta_index = "soda"
			node.play_animation(meta_index+"//ending")
			await node.valid_select
			sub_game.remove_item_at_index(node.get_meta(meta_index+"_index"))
		workspace_vessels.erase(node)


	current_vessel = node
	if current_vessel in workspace_vessels:
		workspace_vessels.erase(current_vessel)
	set_active_areas()
	node.holding=true
	if node in lineup:
		lineup.erase(node)
		
func deselect_vessel():
	
	if $Control.gui_input.is_connected(_on_control_gui_input):
		$Control.gui_input.disconnect(_on_control_gui_input)
	if current_vessel:
		current_vessel.holding=false
		# If node is meant to be lined up on canvas, animate its entry
		if !(current_vessel in workspace_vessels):
			_animate_entry(current_vessel)
	current_vessel = null


func _set_vessel_blend_data(amount):
	if current_vessel:
		current_vessel.set_blend(amount)
		if current_vessel.is_locked():
			current_vessel.unlock()
		deselect_vessel()
		


func _set_vessel_customer_data(late:float):
	if current_vessel:
		current_vessel.set_score(late)
		
# Syrups and toppings handled in map because vessel is child of current game
func _set_vessel_toppings_data(amount, flavor=""):
	pass
		
func _set_syrup_data(amount, flavor=""):
	pass

func _set_ice_cream_data(amount, flavor, vessel):
	pass

func _set_soda_data(amount, flavor, vessel):
	vessel.add_soda(amount, flavor)
	await vessel.capacity_updated
	pixel_world.get_sub_game().shrink_flow(vessel.get_meta("soda_index"))

func _on_control_gui_input(event):
	
	var sub_game = pixel_world.get_sub_game()
	
	# Handle inputs for items not on canvas
	if current_vessel==null and (event.is_action_pressed("click")||event.is_action_pressed("right-click")): 
		match active_scene_idx:
			5:	# In Syrups:
				sub_game._deselect_vessel()
			2:	# In Toppings:
				sub_game._carry_vessel_over(null)


	# Handle inputs for canvas items
	elif event.is_action_pressed("click") and current_vessel != null:
		# Check Area
		var area = current_vessel.get_current_area_name()
		var rect = current_vessel.areas.find_key(area)
		
		if area == null:
			enter_game()
			return
		
		if area == "blender":
			if current_vessel.vessel_type in sub_game.allowed_vessels:				
				sub_game.open_sheild()
				await sub_game.sheild_opened
				if !(current_vessel == null):
					current_vessel.change_scale(area)
					current_vessel.lock_position(rect.get_center()+current_vessel.blender_offset)
		
					
	# Handle "Deselect" in canvas
	elif event.is_action_pressed("right-click") and current_vessel != null:
		
		
		# Close blender sheild
		if active_scene_idx==0:
			if !sub_game.animating:
				if sub_game.locked:
					sub_game.close_sheild()
				if current_vessel != null:
					current_vessel.unlock()
					
							
		elif (active_scene_idx==3 || active_scene_idx==4):
			if !(current_vessel == null):
				
				var area_name = "ice cream"
				var meta_name = "ice_cream_index"
				if active_scene_idx==4:
					area_name = "soda"
					meta_name = "soda_index"
				var position_index = sub_game.get_index_at_position($CarryOver/Nodes.get_global_mouse_position())
				if !sub_game.is_index_occupied(position_index) and position_index != null:
					current_vessel.change_scale(area_name)
					await current_vessel.lock_position(sub_game.get_position_at_index(position_index))
					current_vessel.set_meta(meta_name, position_index)
					sub_game.insert_item_at_index(position_index, current_vessel)
					workspace_vessels.append(current_vessel)
					current_vessel.unlock()
	
		# Deselect vessel
		deselect_vessel()
	



func _on_nodes_draw():
	$CarryOver/Nodes.draw_rect(LINEUP_RECT, Color.BLUE, false, 2)
	var area_dict = pixel_world.get_sub_game().areas
	for area in area_dict.keys():
		$CarryOver/Nodes.draw_rect(area_dict[area], [Color.RED, Color.YELLOW][refresh%2], false, 2)
	refresh += 1

# On input click
# If no area, but vessel is hovering game screen
func enter_game():

	if Globals.pixelframe.has_point(current_vessel.global_position):

		# Syrups and Toppings hub: Carry vessel back into game
		match active_scene_idx:
			2:
				current_vessel.change_scale("toppings")
				_carry_back(current_vessel)
			5:
				if current_vessel.vessel_type in pixel_world.get_sub_game().allowed_vessels:
					current_vessel.change_scale("syrups")
					_carry_back(current_vessel)

# Called when selected vessel goes out of the boundaries of its frame			
func _vessel_out_of_bounds():
	if current_vessel != null:
		
		var new_vessel_position = current_vessel.global_position
		# RIGHT
#		if current_vessel.global_position.x > (Globals.bigframe.size.x):
#			_on_right_button_pressed()
		# LEFT
#		elif current_vessel.global_position.x < 10:
#			_on_left_button_pressed()
		
		# BOTTOM
		if current_vessel.global_position.y > (Globals.bigframe.size.y):
			$Popup/Container/Label.text = alert_labels["trash"]
			$Popup.popup_centered()
			
	
# POPUP ALERT METHODS
		
	
func _on_confirm_pressed():
	if $Popup/Container/Label.text == alert_labels["trash"]:
		if current_vessel:
			current_vessel.queue_free()
	$Popup.hide()


func _on_reject_pressed():
	$Popup.hide()

func _on_tree_exiting():
	open_shop = false
	super._on_tree_exiting()

func _on_open_shop_pressed():
	open_shop = true
	var tween = create_tween()
	tween.tween_property($Frame/CloseFrame, "position:y", -900, 2.5)
