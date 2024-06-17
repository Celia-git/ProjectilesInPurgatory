extends Node2D


signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_data

# Replace with cone scene
var cone_path = "res://IceCream/Vessels/CakeCone.tscn"
var area_size = Vector2(87, 165)
var areas = {"chocolate ice cream":Rect2(Vector2(690, 405), area_size),
	"strawberry ice cream":Rect2(Vector2(525, 405), area_size),
	"vanilla ice cream":Rect2(Vector2(360, 405), area_size)}

var pump_states = [false, false, false]
var locked = false

var vessels = [null, null, null]
var flow_speed = 50
var is_flowing = false

var game_states=Globals.game_states

# Flow ice cream before it makes contact with vessel
func flow(pump_idx):
	var dripper = $DripSprites.get_node("Drip%d" % pump_idx)
	var length = $DripSprites.get_node("Length%d" % pump_idx)
	dripper.animation = "beginning"
	dripper.frame = 0 
	var target_position= vessels[pump_idx].get_content_ceiling()
	var target_distance = dripper.global_position.distance_to(Vector2(dripper.global_position.x, target_position))
	var scale_target = target_distance/48
	var time = target_distance/flow_speed
	is_flowing=true
	var tween = create_tween()
	tween.tween_property(dripper, "position:y", 4, .3).as_relative()
	tween.tween_property(dripper, "global_position:y", target_distance, time).as_relative()
	tween.parallel().tween_property(length, "scale:y", scale_target, time)
	await get_tree().create_timer(time).timeout
	tween.stop()
	length.position.y = 0
	var vessel = vessels[pump_idx]
	if vessel != null:	
		var dripper2 = dripper.duplicate()
		vessel.add_ice_cream_drip(dripper2, areas.keys()[pump_idx].trim_suffix(" ice cream"))
		if !vessel.capacity_updated.is_connected(_shrink_flow):
			vessel.capacity_updated.connect(_shrink_flow)
		vessel.play_animation("ice_cream//beginning")
		dripper.animation = "default"
		dripper.frame = 0
		dripper.position.y = 0
	
# Shrink the flow of ice cream after another tile is added to cone
func _shrink_flow(pump_idx):
	var length = $DripSprites.get_node("Length%d" % pump_idx)
	var target_position= vessels[pump_idx].get_content_ceiling()
	var target_distance = $DripSprites.global_position.y - target_position
	var scale_target = abs(float(target_distance)/64)
	length.scale.y = scale_target
	if target_position <= ($DripSprites.global_position.y+48):
		abort_flow(pump_idx)
	
	
func abort_flow(index):
	var length = $DripSprites.get_node("Length%d" % index)
	var vessel = vessels[index]
	
	if vessel != null:
		var distance = $DripSprites.global_position.y - vessel.get_content_ceiling()
		var time = distance / flow_speed
		vessel.play_animation("ice_cream//ending")
		var tween = create_tween()
		tween.tween_property(length, "scale:y", 0, time)
		tween.parallel().tween_property(vessel, "global_position:y", distance, time).as_relative()
		await get_tree().create_timer(time).timeout
		is_flowing=false
	
	pump_states[index] = false
	
# Return index of area rect in which pos lies
func get_index_at_position(pos):
	
	for area in areas:
		if areas[area].has_point(pos):
			var index = areas.keys().find(area) 
			return index
	return null

# Return rest position for cups at area index
func get_position_at_index(index):
	var key = areas.keys()[index]
	return areas[key].get_center()

func is_index_occupied(position_index):
	if position_index==null:
		return false
	return (vessels[position_index] != null)
	
func insert_item_at_index(index, vessel):
	vessels[index] = vessel
	locked = true
	
func remove_item_at_index(index):
	if vessels[index] != null:
		if vessels[index].capacity_updated.is_connected(_shrink_flow):
			vessels[index].capacity_updated.disconnect(_shrink_flow)
	
	if pump_states[index]:
		abort_flow(index)
	
	vessels[index]=null
		
	for i in vessels:
		if i != null:
			return
	locked = false
	






func _on_pump_input_event(viewport, event, shape_idx, pump_idx):
	
	# Toggle pump state
	if event.is_action_pressed("click"):
		pump_states[pump_idx] = !pump_states[pump_idx]
			
		var dripper = $DripSprites.get_node("Drip%d" % pump_idx)
		var vessel = vessels[pump_idx]		
			
		match pump_states[pump_idx]:
			
			# Pump activated
			true:
				# Only play pump if a valid vessel is down
				if vessel:
					# play pump sprite 'pull_down', await finished
					vessel.global_position.x = dripper.global_position.x
					vessel.set_meta("ice_cream_position", vessel.global_position.x)
					if !is_flowing:
						if vessel.get_content_ceiling()	> ($DripSprites.global_position.y+48):
							locked = true
							flow(pump_idx)
						else:
							vessel.play_animation("ice_cream//ending")
				
			# Pump aborted
			false:
				abort_flow(pump_idx)



func _on_cones_input(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		var vessel = load(cone_path).instantiate()
		add_child(vessel)
		emit_signal("carry_over", vessel, get_global_mouse_position(), true)


func get_areas():
	return areas
	
func dialog_finished():
	pass

