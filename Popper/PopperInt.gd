extends InteriorScenes

var COUNTER_RECT = Rect2(320, 500, 960, 150)
var APPLE_RACK_RECT = Rect2(160, 135, 1280, 155)
var BAGS_RECT = Rect2(400, 750, 960, 100) 
var OUTPUT_BAG_RECT = Rect2(140, 550, 192, 192)
@export var popcorn_queued = []
var apples_queued = []
var output_bag # bag which is currently lined up in output spot
var MAX_APPLE_RACK = 9
var MAX_POPCORN_BAGS = 5
var trashed_bags = 0

var current_scene
var order_tracker_scene = preload("res://Popper/Orders/OrderTracker.tscn")
var order_tracker=null
var selected_node=null

func set_ui_color():
	ui_color = Color.CRIMSON
	
func set_sub_scenes():
	sub_scenes = ["Popcorn/PopcornWorkspace.tscn", "Apples/AppleWorkspace.tscn", "Orders/Window.tscn"]
	
func set_game_path():
	game_path = "res://Popper/"
	

func set_backgrounds():
	backgrounds = ["PopperIntMachineBackground.png",
		"PopperIntPotsBackground.png",
		"PopperIntWindowBackground.png",
		"PopperIntSaucesBackground.png",
		"PopperIntToppingsBackground.png"]

func set_current_background(idx):
	$Background/Sprite2D.texture = load(Globals.backgrounds_path+backgrounds[idx])
		
		

func set_new_active_scene(idx):
	super.set_new_active_scene(idx)
	match idx:
		0:	# If subgame is PopcornWorkspace
			current_scene = "Popcorn"
			open_games[idx].transfer_carry_overs()
		1: #if subgame is apples
			current_scene = "Apples"
		2:	# If subgame is Window
			current_scene="Window"
			# Create new order tracker
			if order_tracker == null:
				order_tracker = order_tracker_scene.instantiate()
				pixel_world.get_sub_game().new_customer.connect(order_tracker._generate_order)
				pixel_world.get_sub_game().order_fulfilled.connect(order_tracker._order_fulfilled)
				pixel_world.get_sub_game().order_failed.connect(order_tracker._order_failed)
				order_tracker.order_submitted.connect(pixel_world.get_sub_game()._order_submitted)
				order_tracker.order_recinded.connect(pixel_world.get_sub_game()._order_recinded)
				order_tracker.mouse_entered.connect(_on_button_mouse_entered)
				order_tracker.mouse_exited.connect(_on_button_mouse_exited)
				$CarryOver.add_child(order_tracker)

# Override connect subgame to methods
func connect_to_signals(game, game_index):
	if !game.shift_left.is_connected(_animate_background_change.bind(0)):
		game.shift_left.connect(_animate_background_change.bind(0))
	
	if !game.shift_right.is_connected(_animate_background_change.bind(1)):
		game.shift_right.connect(_animate_background_change.bind(1))
	
	super.connect_to_signals(game, game_index)


# Carry node over to carryover canvas layer
func _carry_over(node, pos, delay=false, new_collision=false, permanent=true):
	if delay:
		await get_tree().create_timer(.3).timeout
		if node==null: return
	# Enable collisions on new layer and disable on old layer
	if new_collision:
		node.set_collision_layer_value(new_collision, true)
		node.set_collision_mask_value(new_collision, true)
		node.set_collision_layer_value(new_collision-1, false)
		node.set_collision_mask_value(new_collision-1, false)
	if node.is_in_group("apples"):
		node.set_area(APPLE_RACK_RECT, "AppleRack")
		node.set_area(COUNTER_RECT, "Counter")

		node.set_frame(Globals.bigframe)
		node.shift_to_area("Window", false)
		animate_entry(node)
		node.holding = false
		node.set_physics_process(true)
	
	elif node.is_in_group("bags"):
		node.set_area(BAGS_RECT, "PopcornRack")
		node.set_area(COUNTER_RECT, "Counter")
		node.set_area(OUTPUT_BAG_RECT, "OutputBag")
		node.shift_to_area(false)
		
		# Add Collision Exceptions to bag
		for bag in popcorn_queued:
			if !(bag in node.get_collision_exceptions()):
				node.add_collision_exception_with(bag)
			if !(node in bag.get_collision_exceptions()):
				bag.add_collision_exception_with(node)
		
		if !output_bag:
			output_bag=node
			if node.scale != Vector2(4,4):
				var tween = create_tween()
				tween.tween_property(node, "scale", Vector2(4,4), (.2)).set_trans(Tween.TRANS_SINE)
			
		else:
			if !(output_bag in node.get_collision_exceptions()):
				node.add_collision_exception_with(output_bag)  
			if !(node in output_bag.get_collision_exceptions()):
				output_bag.add_collision_exception_with(node)
			_return_to_rack(node)
		node.set_physics_process(true)
		
	elif node.is_in_group("output"):
		if !node.delete_bag.is_connected(_delete_bag):
			node.delete_bag.connect(_delete_bag)
	
	connect_signals(node)
	super._carry_over(node, pos, permanent)
	
	

func _carry_back(node):
	if selected_node==node:
		deselect_node()
	if node.is_in_group("bags"):
		if node.select_me.is_connected(_select_bag):
			node.select_me.disconnect(_select_bag)
		if node.out_of_bounds_left.is_connected(_shift_popcorn_left):
			node.out_of_bounds_left.disconnect(_shift_popcorn_left)
		if node.out_of_bounds_right.is_connected(_carry_bag_back):
			node.out_of_bounds_right.disconnect(_carry_bag_back)
		if node.out_of_bounds_bottom.is_connected(_return_to_rack):
			node.out_of_bounds_bottom.disconnect(_return_to_rack)
	elif node.is_in_group("apples"):
		# Only allow carry back in apple or window subgame
		if (current_scene != "Apples")&&(current_scene!="Window"):
			return
		node.active_areas = [APPLE_RACK_RECT, COUNTER_RECT]
		node.set_meta("last_position", node.get_global_position)
		if node.select_me.is_connected(_select_apple):
			node.select_me.disconnect(_select_apple)
		if node.out_of_bounds_bottom.is_connected(_carry_back):
			node.out_of_bounds_bottom.disconnect(_carry_back)
		node.set_physics_process(false)
	super._carry_back(node)

# connect carryover node signals
func connect_signals(node):
	if node.is_in_group("bags"):
		
		if !node.select_me.is_connected(_select_bag):
			node.select_me.connect(_select_bag)
		if !node.out_of_bounds_left.is_connected(_shift_popcorn_left):
			node.out_of_bounds_left.connect(_shift_popcorn_left)
		if !node.out_of_bounds_right.is_connected(_carry_bag_back):
			node.out_of_bounds_right.connect(_carry_bag_back)
		if !node.out_of_bounds_bottom.is_connected(_return_to_rack):
			node.out_of_bounds_bottom.connect(_return_to_rack.bind(node))
			
	elif node.is_in_group("apples"):
		if !node.out_of_bounds_bottom.is_connected(_carry_back):
			node.out_of_bounds_bottom.connect(_carry_back.bind(node))
		if !node.select_me.is_connected(_select_apple):
			node.select_me.connect(_select_apple)



# Selecting a node transfers all gui inputs to this class
func select_node(node):
	if selected_node:
		deselect_node()
		
	if !$Control.gui_input.is_connected(_on_control_gui_input):
		$Control.gui_input.connect(_on_control_gui_input)
	node.holding=true
	selected_node = node
	
func deselect_node():
	
	if $Control.gui_input.is_connected(_on_control_gui_input):
		$Control.gui_input.disconnect(_on_control_gui_input)
	if selected_node:
		selected_node.holding=false

		# Move bag back to rest position
		if selected_node.is_in_group("bags"):
			
			match selected_node.rest_position_relative:
				"GLOBAL":
					# If output_bag; send it to output position
					if (selected_node==output_bag && selected_node.global_position != selected_node.global_rest_position):
						var tween = create_tween()
						var time = selected_node.global_rest_position.distance_to(selected_node.global_position)/(float(selected_node.speed)*selected_node.global_speed_scale)
						tween.tween_property(selected_node, "global_position", selected_node.global_rest_position, time)
						await get_tree().create_timer(time)
						
		
			
	selected_node = null		


# Remove apple from rack
func _select_apple(apple):
	select_node(apple)
	apples_queued.erase(apple)
	var pos_arg = Vector2(APPLE_RACK_RECT.position.x+APPLE_RACK_RECT.size.x, APPLE_RACK_RECT.position.y)
	get_next_open_position(pos_arg, apples_queued, -140)

func _select_bag(bag):
	
	if !bag.frozen:
		bag.freeze()
	select_node(bag)
	popcorn_queued.erase(bag)
	get_next_open_position(BAGS_RECT.position, popcorn_queued, 200)
	
	
# Return node to rack
func _return_to_rack(node):
	if node==output_bag:
		output_bag=null
	deselect_node()
	animate_entry(node)



# Show node entering rack	
func animate_entry(node):
	var position_arg1
	var position_arg2
	var position_arg3
	if node.is_in_group("apples"):
		position_arg1=Vector2(APPLE_RACK_RECT.position.x+APPLE_RACK_RECT.size.x, APPLE_RACK_RECT.position.y)
		position_arg2=apples_queued
		apples_queued.append(node)
		position_arg3=-140
	elif node.is_in_group("bags"):
		position_arg1=BAGS_RECT.position
		position_arg2=popcorn_queued
		popcorn_queued.append(node)
		position_arg3=200

	
	var next_open_position = get_next_open_position(position_arg1, position_arg2, position_arg3)
	var time = next_open_position.distance_to(node.position)/(float(node.speed)*node.global_speed_scale)
	var tween = create_tween()
	tween.tween_property(node, "scale", Vector2(4,4), (time/4)).set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "position", next_open_position, time).set_trans(Tween.TRANS_SINE)

	

# Return next open position on apple rack
func get_next_open_position(initial_pos, array, step):
	var pos = initial_pos
	for a in range(0, array.size()):
		pos.x += step
		var tween = create_tween()
		tween.tween_property(array[a], "position", pos, float((array.size()-a)*.5)).set_trans(Tween.TRANS_QUAD)
		
	return pos

	


func _on_nodes_draw():
	$CarryOver/Nodes.draw_rect(APPLE_RACK_RECT, Color.CORNFLOWER_BLUE)
	$CarryOver/Nodes.draw_rect(BAGS_RECT, Color.CHARTREUSE)
	$CarryOver/Nodes.draw_rect(OUTPUT_BAG_RECT, Color.MAGENTA)
	$CarryOver/Nodes.draw_rect(COUNTER_RECT, Color.LAVENDER_BLUSH)


# Release selected node
func _on_control_gui_input(event):
	
	if event.is_action_pressed("click") && selected_node!=null:
		if selected_node.is_in_group("apples"):
			var area = selected_node.current_area
			
			# Place apple on counter
			if area=="Counter" and current_scene=="Window":
				_carry_back(selected_node)
			
			# Return apple to Stand in workspace
			elif current_scene=="Apples" and Globals.pixelframe.has_point(selected_node.global_position):
				_carry_back(selected_node)
								
			# Return to rack
			elif area == "AppleRack":
				_return_to_rack(selected_node)
			
		elif selected_node.is_in_group("bags"):
			var area = selected_node.current_area
			# Place bag on counter
			if area ==COUNTER_RECT and current_scene == "Window" :
				_carry_back(selected_node)
			
			# Carry back to Popcorn workshop if permitted
			elif current_scene=="Popcorn" and Globals.pixelframe.has_point(selected_node.global_position):
				_carry_bag_back()
				
			elif area == "PopcornRack":
				_return_to_rack(selected_node)

	if event.is_action_pressed("right-click") and selected_node!=null:
		if selected_node.is_in_group("apples") or selected_node.is_in_group("bags"):
			
			var area
			if selected_node.is_in_group("apples"):
				area = selected_node.current_area_rect
			elif selected_node.is_in_group("bags"):
				area = selected_node.current_area
			if area==OUTPUT_BAG_RECT:
				if !output_bag:
					output_bag = selected_node
					deselect_node()
			else:
				_return_to_rack(selected_node)

func _on_carryover_nodes_child_entered_tree(node):
	
	if(node.is_in_group("apples") and apples_queued.size() >= MAX_APPLE_RACK):
		
		_select_apple(node)
		_carry_back(node)
	
	elif (node.is_in_group("bags") and popcorn_queued.size() >= MAX_POPCORN_BAGS):
		_select_bag(node)
		_carry_back(node)


# Check if workspace is set to recieve carryback
func _carry_bag_back():
	var workspace = pixel_world.get_sub_game()
	if selected_node:
		if selected_node.is_in_group("bags") and current_scene=="Popcorn":
			workspace._shift_right()
			_carry_back(selected_node)

func _shift_popcorn_left():
	var workspace = pixel_world.get_sub_game()
	if selected_node:
		if selected_node.is_in_group("bags") and current_scene=="Popcorn":
			workspace._shift_left()
			
# Delete bag which is currently in output spot
func _delete_bag():
	if output_bag:
		output_bag.call_deferred("queue_free")
		trashed_bags += 1
		
# Animate a shift in relative background position
func _animate_background_change(direction):
	# 2D array of popcorn backgrounds, then apple backgrounds, left to right
	var background_texture = [[backgrounds[0], backgrounds[3]], [backgrounds[1], backgrounds[4]]][active_scene_idx][direction]
	$Background/Transition.texture = load(Globals.backgrounds_path+background_texture) 
	if direction==0:
		$Background/Transition.position.x -= (direction*pixel_world.size.x)
	else:
		$Background/Transition.position.x += (direction*pixel_world.size.x)
	$Background/Transition.visible = true
	var tween = create_tween()
	tween.tween_property($Background/Transition, "position", Vector2(0,0), 1).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property($Background/Transition, "modulate", Color(1, 1, 1, 1), 1).set_trans(Tween.TRANS_SINE).from(Color(1, 1, 1, 0))
	await get_tree().create_timer(1).timeout
	$Background/Sprite2D.texture = load(Globals.backgrounds_path+background_texture) 
	$Background/Transition.visible = false	
