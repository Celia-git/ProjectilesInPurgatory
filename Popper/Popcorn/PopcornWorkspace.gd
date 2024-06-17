extends Node2D


signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal shift_left
signal shift_right


@onready var output_scene = preload("res://Popper/Popcorn/Output.tscn")
@onready var bag_scene = preload("res://Popper/Popcorn/Bag.tscn")

const OUT_GLOBAL_POS = Vector2(200, 368)
const BAG_GLOBAL_POS = Vector2(266, 694)

var current_workspace = "Machine"
var output
var selected_bag
var game_states
	

func _ready():
	$PopcornMachine.position = Vector2(0,0)
	$PumpSide.position = Vector2(320, 0)

func _input(event):
	
	# Prevent deselecting when an animation is currently happening
	if event.is_action_pressed("right-click") && selected_bag && !$AnimationPlayer.is_playing():
		selected_bag.holding=false
		
	
		if selected_bag.is_in_group("bags"):
			match selected_bag.rest_position_relative:

				"LOCAL":
					# Else; send bag to local positon
					if selected_bag.position != selected_bag.rest_position:
						var tween = create_tween()
						var time = selected_bag.rest_position.distance_to(selected_bag.position)/(float(selected_bag.speed)*selected_bag.speed_scale)
						tween.tween_property(selected_bag, "position", selected_bag.rest_position, time)
						await get_tree().create_timer(time)

		
		selected_bag=null		

# Shift game toward popcorn machine
func _shift_left():
	if current_workspace=="Pumps" && !$AnimationPlayer.is_playing():
		
		emit_signal("shift_left")
		$AnimationPlayer.play("shift_to_machine")
		await $AnimationPlayer.animation_finished
		await $PopcornMachine.shift_toward()
		
		current_workspace="Machine"
		
		emit_signal("carry_over", output, OUT_GLOBAL_POS, false, false, false)
		if selected_bag:
			_carry_over_bag(selected_bag, selected_bag.global_position)
	
# Shift game toward pumps
func _shift_right():
	if current_workspace=="Machine" && !$AnimationPlayer.is_playing():
		
		emit_signal("shift_right")
		emit_signal("carry_back", output)
		await $PopcornMachine.shift_away()
		$AnimationPlayer.play("shift_to_pumps")
		await $AnimationPlayer.animation_finished
		
		current_workspace="Pumps"

# Carry over to Canvas--Popcorn rack
func _shift_bottom():
	if selected_bag:
		_carry_over_bag(selected_bag, selected_bag.global_position)
	

# Instantiate bag and output scenes, carry over
func transfer_carry_overs():
	
	output=output_scene.instantiate()
	output.add_to_group("output")
	output.add_bag.connect(_new_bag)
	output.button_mouse_exited.connect(_mouse_exited)
	output.button_mouse_entered.connect(_mouse_entered)
	add_child(output)
	emit_signal("carry_over", output, OUT_GLOBAL_POS, false, false, false)
	_new_bag()


func _new_bag():
	var bag = bag_scene.instantiate()
	bag.add_to_group("bags")
	set_areas(bag)
	add_child(bag)
	_carry_over_bag(bag, BAG_GLOBAL_POS)

# Set areas for reference in bag
func set_areas(bag):
	var rects = get_pump_areas()
	var idx = 0
	for rect in rects:
		bag.set_area(rect, "Pump"+str(idx))
		idx += 1

# Return global rects for identifying bag position
func get_pump_areas():
	
	var width = 192
	var height = 50
	var top_shelf_pos = Vector2(80, 56)
	var bottom_shelf_pos = Vector2(40, 66)
	var rects = []
	# Add top shelf rects
	for r in range(3):
		@warning_ignore("integer_division")
		rects.append(Rect2(top_shelf_pos.x + r*width/3, top_shelf_pos.y, width/3, height)) 
	# Add bottom shelf rects
	for r in range(3):
		@warning_ignore("integer_division")
		rects.append(Rect2(bottom_shelf_pos.x + r*width/3, bottom_shelf_pos.y + height, width/3, height))
	return rects


# carry over popcorn from machine
func _on_popcorn_machine_carry_over(node, pos, delay, collision):
	emit_signal("carry_over", node, pos, delay, collision)
	

func _select_bag(bag):
	selected_bag=bag
	if !selected_bag.frozen:
		selected_bag.freeze()
	selected_bag.holding=true

func _carry_over_bag(bag, pos):
	bag.set_physics_process(false)
	disconnect_signals(bag)
	emit_signal("carry_over", bag, pos)
	selected_bag=null

func _on_child_entered_tree(node):
	if node.is_in_group("bags"):
		if current_workspace=="Pumps":
			# Keep Bag
			connect_signals(node)
			node.shift_to_area(true)
			if node.scale != Vector2(1,1):
				var tween = create_tween()
				tween.tween_property(node, "scale", Vector2(1,1), .2).set_trans(Tween.TRANS_SINE)
			if node.position != node.rest_position:
				var tween = create_tween()
				tween.tween_property(node, "position", node.rest_position, .2).set_trans(Tween.TRANS_SINE)
			node.set_physics_process(true)
				
		else:
			# Destroy bag
			await get_tree().create_timer(1).timeout
			if node in get_children():
				node.call_deferred("queue_free")
# Connect bag signals to workspace methods
func connect_signals(bag):
	if !bag.select_me.is_connected(_select_bag):
		bag.select_me.connect(_select_bag)
	if !bag.out_of_bounds_left.is_connected(_shift_left):
		bag.out_of_bounds_left.connect(_shift_left)
	if !bag.out_of_bounds_bottom.is_connected(_shift_bottom):
		bag.out_of_bounds_bottom.connect(_shift_bottom)
	if !bag.mouse_entered.is_connected(_mouse_entered):
		bag.mouse_entered.connect(_mouse_entered)
	if !bag.mouse_exited.is_connected(_mouse_exited):
		bag.mouse_exited.connect(_mouse_exited)		
		
	if !$PumpSide/Pumps.coat.is_connected(bag._coated):
		$PumpSide/Pumps.coat.connect(bag._coated)		


func disconnect_signals(bag):
	if bag.select_me.is_connected(_select_bag):
		bag.select_me.disconnect(_select_bag)
	if bag.out_of_bounds_left.is_connected(_shift_left):
		bag.out_of_bounds_left.disconnect(_shift_left)
	if bag.out_of_bounds_bottom.is_connected(_shift_bottom):
		bag.out_of_bounds_bottom.disconnect(_shift_bottom)
	if bag.mouse_entered.is_connected(_mouse_entered):
		bag.mouse_entered.disconnect(_mouse_entered)
	if bag.mouse_exited.is_connected(_mouse_exited):
		bag.mouse_exited.disconnect(_mouse_exited)				
	if $PumpSide/Pumps.coat.is_connected(bag._coated):
		$PumpSide/Pumps.coat.disconnect(bag._coated)		

		
func _mouse_entered():
	emit_signal("mouse_entered")

func _mouse_exited():
	emit_signal("mouse_exited")
	

func _on_shift_workspace_mouse_shape_entered(shape_idx):
	if (selected_bag==null and !$AnimationPlayer.is_playing()):
		
		match shape_idx:
			0: #(left)
				$ShiftWorkspace/Left.visible=true
			1: #Right
				$ShiftWorkspace/Right.visible=true
	emit_signal("mouse_entered")		

func _on_shift_workspace_mouse_shape_exited(shape_idx):
	if (selected_bag==null and !$AnimationPlayer.is_playing()):
		
		match shape_idx:
			0: #(left)
				$ShiftWorkspace/Left.visible=false
			1: #Right
				$ShiftWorkspace/Right.visible=false
		

func dialog_finished():
	pass
	
func _on_sprite_2d_draw():
	
	var rects = get_pump_areas()
	for r in rects:
		$Sprite2D.draw_rect(r, Color.CORNFLOWER_BLUE, false, 3)




func _on_left_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		_shift_left()

func _on_right_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		_shift_right()


func _on_draw():
	
	var rects = get_pump_areas()
	for r in rects:
		$PumpSide.draw_rect(r, Color.CORNFLOWER_BLUE, false, 3)


func _on_animation_player_animation_finished(anim_name):
	$ShiftWorkspace/Left.visible = false
	$ShiftWorkspace/Right.visible = false
