extends InteriorScenes


@onready var achievement_container = $Control/Achievements/CenterContainer/GridContainer
var MATCH_X_GAP = 96
var MATCH_Y_POS = Globals.bigframe.size.y-90
var carryover_matches = []
var achievement_images = []
var tip_queue = []
var dragging_sprite = null


func _process(delta):
	if dragging_sprite != null:
		dragging_sprite.global_position = lerp(dragging_sprite.global_position, $CarryOver/Nodes.get_global_mouse_position(), 50*delta)

func set_new_active_scene(idx):
	for child in $CarryOver/Nodes/Matches.get_children():
		child.queue_free()
	carryover_matches.clear()
	$Control/StreakTracker.visible = (idx == 0)
		
	_update_prompt("")
	super.set_new_active_scene(idx)
	
	if idx==0 and open_games[idx] != null:
		if open_games[idx].achievements != null:
			open_games[idx].load_character_matches()
	


# connect subgame to Interior signals
func connect_to_signals(game, game_index):
	if game_index==0:

		if !game.update_prompt.is_connected(_update_prompt):
			game.update_prompt.connect(_update_prompt)
		if !game.update_matches.is_connected(_update_matches):
			game.update_matches.connect(_update_matches)
		if !game.new_tip.is_connected(_new_tip):
			game.new_tip.connect(_new_tip)
		if !game.update_combo_streak.is_connected(_update_streak):
			game.update_combo_streak.connect(_update_streak)
		if !game.view_achievements.is_connected(_view_achievements):
			game.view_achievements.connect(_view_achievements)
		if !game.hide_achievements.is_connected(_hide_achievements):
			game.hide_achievements.connect(_hide_achievements)
		super.connect_to_signals(game, game_index)
		game.load_data()
	else:
		super.connect_to_signals(game, game_index)

func set_ui_color():
	ui_color = Color(0,0,0,0)
	
func set_sub_scenes():
	sub_scenes = ["Game.tscn", "FortuneTeller.tscn"]
	
func set_game_path():
	game_path = "res://Esther/"
	
	
func _carry_over(node, pos, permanent=true):
	
	if node.is_in_group("matches"):
		node.set_meta("permanence", false)
		node.set_meta("index", carryover_matches.size()-1)
		carryover_matches.append(node)
		var tween = create_tween()
		var time = 1.6
		
		node.call_deferred("reparent", $CarryOver/Nodes/Matches)

		connect_match_sprites_to_signals(node)
		
		# Animate node's entry
		var target_position = Vector2(Globals.pixelframe.position.x + (MATCH_X_GAP*carryover_matches.size()), MATCH_Y_POS)

		tween.tween_property(node, "global_position", target_position, time).set_trans(Tween.TRANS_ELASTIC).from(pos)
		tween.parallel().tween_property(node, "scale", Vector2(3,3), time).set_trans(Tween.TRANS_EXPO)
		tween.parallel().tween_property(node, "modulate", Color(1, 1, 1, 1), time).from(Color(0, 0, 0, 1)).set_trans(Tween.TRANS_QUAD)
		await get_tree().create_timer(time).timeout
		update_sprite_indices()
		_update_matches()
	
	elif node.is_in_group("achievements"):
		achievement_images.insert(0, node)
		$Control/Achievements/CenterContainer/GridContainer.add_child(node)
		$Control/Achievements/CenterContainer/GridContainer.move_child(node, 0)
		
	else:
		super._carry_over(node, pos, permanent)
		
		
# Update Game Prompt
func _update_prompt(text, arg1=""):
	$Control/GamePrompts.text = text
	
# Update Sprite Matches positions to fit in the bottom row
func _update_matches():
	var x = carryover_matches.size()
	
	while x > 0:
		
		var sprite = carryover_matches[x-1]
		var target_position_x = 0
		if carryover_matches.size() >= 20:
			target_position_x = Globals.pixelframe.position.x + (float(x)/carryover_matches.size())
		else:
			target_position_x = Globals.pixelframe.position.x  + (MATCH_X_GAP*x)
		
		var tween = create_tween()
		tween.parallel().tween_property(sprite, "global_position", Vector2(target_position_x, MATCH_Y_POS), .2).set_ease(Tween.EASE_IN)
		x -= 1

# progress_icons: 2D array containing each array of textures [elements, stages, roles]
func _update_streak(progress_icons):
	var streak_type = 0
	for icon_array in progress_icons:
		var container = $Control/StreakTracker.get_node(["element", "stage", "role"][streak_type])
		for child in container.get_children():
			child.queue_free()
		for icon in icon_array:
			container.add_child(icon)
		streak_type += 1

func _new_tip(tip):
	tip_queue.append(tip)
	if !$Control/AnimationPlayer.is_playing() and tip != "":
		$Control/Tips.text = tip_queue.pop_front()
		$Control/AnimationPlayer.play("show_tip")
	
		

# Interaction with sprite matches

func _mouse_over_sprite(node):
	var idx = node.get_meta("index")
	if !dragging_sprite:
		var tween = create_tween()
		tween.tween_property(carryover_matches[idx], "scale", Vector2(4, 4), .2).set_trans(Tween.TRANS_SINE)
		super._on_button_mouse_entered()
	
func _mouse_exit_sprite(node):
	var idx = node.get_meta("index")
	if !dragging_sprite:
		var tween = create_tween()
		tween.tween_property(carryover_matches[idx], "scale", Vector2(3, 3), .2).set_trans(Tween.TRANS_SINE)
		super._on_button_mouse_exited()
	
func _sprite_input_event(viewport, event, shape_idx, node):
	
	var sprite_idx = node.get_meta("index")
	
	if event.is_action_pressed("click"):
		if !dragging_sprite:
			dragging_sprite = carryover_matches[sprite_idx]
			carryover_matches.erase(dragging_sprite)
			update_sprite_indices()
			set_process(true)
		
	elif event.is_action_released("click"):
		# iterate all sprites in carryover_matches, find the place in array that the mouse's x-pos indicates
		var x_pos = $CarryOver/Nodes.get_global_mouse_position().x
		var index = 0
		var spot_found = false
		for sprite in carryover_matches:
			
			# Put the dragging sprite before the sprite at this index
			if sprite.global_position.x > x_pos:
				
				# Change sprite position in array to new index
				var first_half = carryover_matches.slice(0, index)
				var second_half = carryover_matches.slice(index, carryover_matches.size())
				first_half.append(dragging_sprite)
				carryover_matches = first_half + second_half
				spot_found = true
				break
			
			index += 1
		
		# Else, put it at the furthest right of the row
		if !spot_found:
			carryover_matches.append(dragging_sprite)
			
		# Release sprite in this position in the array
		dragging_sprite=null
		update_sprite_indices()
		set_process(false)
		_update_matches()


func disconnect_match_sprites_from_signals(node):
	
	if node.mouse_entered.is_connected(_mouse_over_sprite):
		node.mouse_entered.disconnect(_mouse_over_sprite)
	if node.mouse_exited.is_connected(_mouse_exit_sprite):
		node.mouse_exited.disconnect(_mouse_exit_sprite)
	if node.input_event.is_connected(_sprite_input_event):
		node.input_event.disconnect(_sprite_input_event)
		

func connect_match_sprites_to_signals(node):
		
	# Connect to node signals
	if !node.mouse_entered.is_connected(_mouse_over_sprite):
		node.mouse_entered.connect(_mouse_over_sprite.bind(node))
	if !node.mouse_exited.is_connected(_mouse_exit_sprite):
		node.mouse_exited.connect(_mouse_exit_sprite.bind(node))
	if !node.input_event.is_connected(_sprite_input_event):
		node.input_event.connect(_sprite_input_event.bind(node))
		
		
		
# TRY TO GET ACHIEVEMENTS.known_Characters in the same order as carryover_matches
# carryover_match.get_meta("character")
func update_sprite_indices():
	var temp_array = []
	
	if !carryover_matches.is_empty():

		var index = 0
		for sprite in carryover_matches:
			if sprite==null:
				carryover_matches.erase(sprite)
				continue
			sprite.set_meta("index", index)
			temp_array.append(sprite.get_meta("character"))
			index += 1
			
	Globals.game_states.esther["known_characters"] = temp_array

func _on_control_animation_finished(anim_name):
	if anim_name == "show_tip" and tip_queue.size()>0:
		$Control/Tips.text = tip_queue.pop_front()
		$Control/AnimationPlayer.play("show_tip")

# Show achievements tab
func _view_achievements():
	# Load unlocked achievements
	var unlocked_achievements = open_games[active_scene_idx].achievements.unlocked_achievements
	# Set modulation/tooltip of achievemnt icons
	for child in achievement_container.get_children():
		# Known achievements
		if child.get_meta("name") in unlocked_achievements:
			child.self_modulate = Color(1, 1, 1, 1)
		# Locked achievements
		else:
			child.self_modulate = Color(0, 0, 0, 1)
			child.tooltip_text = "???"

	$Control/AnimationPlayer.play("view_achievements")
	
func _hide_achievements():
	$Control/AnimationPlayer.play("hide_achievements")
	
func _on_left_button_pressed():
	if active_scene_idx==0 && open_games[active_scene_idx] != null:
		if open_games[active_scene_idx].achievements_popped_up:
			open_games[active_scene_idx].close_achievements()
			
	super._on_left_button_pressed()

func _on_right_button_pressed():
	if active_scene_idx==0 && open_games[active_scene_idx] != null:
		if open_games[active_scene_idx].achievements_popped_up:
			open_games[active_scene_idx].close_achievements()
			
	super._on_right_button_pressed()


func _close_achievements():
	if active_scene_idx==0 && open_games[active_scene_idx] != null:
		open_games[active_scene_idx].close_achievements()
