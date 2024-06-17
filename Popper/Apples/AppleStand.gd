extends Node2D


# Refill apples when one is taken, connect to apple signals
@onready var apple_scene = "res://Popper/Apples/Apple.tscn"
@onready var stand_size = 320

var apples_on_stand = []
var areas
# Create new apples
func add_apples(amount=9):
	for a in amount:
		var apple = load(apple_scene).instantiate()
		call_deferred("add_child", apple)
		apple.position = Vector2(-50, 0)
		apple.add_to_group("apples")
		apple.set_meta("index", a)
		apple.set_meta("last_position", Vector2(-50, 0))
		set_areas(apple)
		animate_entry(apple)
		connect_signals(apple)
		
# Removing apple from stand to place in rack on canvas
func carry_over(apple):
	apple.set_meta("last_position", apple.global_position)
	disconnect_signals(apple)
	return 0
	
# Carrying apple back to stand from rack on canvas
func _carry_back(apple, current_workspace):
	apple.holding=false
	apple.shift_to_area(current_workspace)
	connect_signals(apple)
	apple.set_physics_process(true)
	animate_entry(apple, true)
	
func set_areas(apple):
	# Set area rects in apple
	for area in areas:
		if area.name == "Toppings":
			var rects = area.get_shapes()
			var idx = 1
			for rect in rects:
				rect.position += Vector2(rect.size.x/3, (rect.size.y/5)+15)
				apple.set_area(rect, "Toppings"+str(idx))
				idx += 1
			
		elif area.name == self.name:
			var rect = $Area2D/CollisionShape2D.shape.get_rect()
			rect.position = $Area2D.position
			apple.set_area(rect, name)
		else:
			var rect = area.get_node("CollisionShape2D").shape.get_rect()
			rect.position += area.position
			apple.set_area(rect, area.name)
	apple.set_frame(Globals.pixelframe)
			

func animate_entry(apple, global_speeds=false):
	var next_open_position = get_next_open_position()
	var time
	if global_speeds:
		time = to_global(next_open_position).distance_to(apple.global_position)/(float(apple.speed)*apple.global_speed_scale)
	else:
		time = to_global(next_open_position).distance_to(apple.global_position)/(float(apple.speed)*apple.speed_scale)
	var tween = create_tween()
	if (apple.scale != Vector2(1,1)):
		tween.tween_property(apple, "scale", Vector2(1,1), (time/5)).set_trans(Tween.TRANS_SINE)
	tween.tween_property(apple, "position", next_open_position, time).set_trans(Tween.TRANS_ELASTIC)

	apples_on_stand.append(apple)
		
func connect_signals(apple):
	if !apple.select_me.is_connected(get_parent()._select_apple):
		apple.select_me.connect(get_parent()._select_apple)
	if !apple.out_of_bounds_left.is_connected(get_parent()._shift_left):
		apple.out_of_bounds_left.connect(get_parent()._shift_left)
	if !apple.out_of_bounds_right.is_connected(get_parent()._shift_right):
		apple.out_of_bounds_right.connect(get_parent()._shift_right)
	if !apple.out_of_bounds_top.is_connected(get_parent()._pass_apple_top):
		apple.out_of_bounds_top.connect(get_parent()._pass_apple_top)
	if !apple.out_of_bounds_bottom.is_connected(get_parent()._trash_apple):
		apple.out_of_bounds_bottom.connect(get_parent()._trash_apple)
	if !apple.mouse_entered.is_connected(get_parent()._mouse_entered):
		apple.mouse_entered.connect(get_parent()._mouse_entered)
	if !apple.mouse_exited.is_connected(get_parent()._mouse_exited):
		apple.mouse_exited.connect(get_parent()._mouse_exited)				
	

func disconnect_signals(apple):
	if apple.select_me.is_connected(get_parent()._select_apple):
		apple.select_me.disconnect(get_parent()._select_apple)
	if apple.out_of_bounds_left.is_connected(get_parent()._shift_left):
		apple.out_of_bounds_left.disconnect(get_parent()._shift_left)
	if apple.out_of_bounds_right.is_connected(get_parent()._shift_right):
		apple.out_of_bounds_right.disconnect(get_parent()._shift_right)
	if apple.out_of_bounds_top.is_connected(get_parent()._pass_apple_top):
		apple.out_of_bounds_top.disconnect(get_parent()._pass_apple_top)
	if apple.out_of_bounds_bottom.is_connected(get_parent()._trash_apple):
		apple.out_of_bounds_bottom.disconnect(get_parent()._trash_apple)
	if apple.mouse_entered.is_connected(get_parent()._mouse_entered):
		apple.mouse_entered.disconnect(get_parent()._mouse_entered)
	if apple.mouse_exited.is_connected(get_parent()._mouse_exited):
		apple.mouse_exited.disconnect(get_parent()._mouse_exited)				
	
func get_apple_by_index(index):
	for child in get_children():
		if child.is_in_group("apples"):
			if child.get_meta("index")==index:
				return child
			else:
				continue
				
	return -1


func _on_draw():
	var rect = $Area2D/CollisionShape2D.shape.get_rect()
	rect.position = $Area2D.position
	draw_rect(rect, Color(0, 1, 0, 1), false, 1)


func _on_apple_stand_child_exiting_tree(node):
	var apple_count = 0
	for child in get_children():
		if child.is_in_group("apples"):
			apple_count += 1
	if apple_count <5:
		add_apples(3)
		
# Return next open position from the right on stand
func get_next_open_position():
	var pos = Vector2(stand_size-16, 10)
	var step = 36
	for a in range(0, apples_on_stand.size()):
		var tween = create_tween()
		tween.tween_property(apples_on_stand[a], "position", pos, float(a*.1)).set_trans(Tween.TRANS_QUAD)
		pos.x -= step
	return Vector2(pos.x, 10)
