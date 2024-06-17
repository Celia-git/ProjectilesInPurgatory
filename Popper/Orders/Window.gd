extends Control


signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal shift_left 
signal shift_right
signal new_customer
signal order_fulfilled
signal order_failed


var selected_node
var pending_order
var is_late
var game_states
	# In Checking Order:
	# Check if the first of each array is the same
	# is_late
	# if order is in group bags and is overcoated
	
# See how well the order has been filled
func check_order():
	if selected_node and pending_order:
		if pending_order.get_values()==selected_node.formatted():
			return true
		else:
			print(pending_order.get_values())
			print(selected_node.formatted())
			return false
	return false


func _order_submitted(order, late=false):
	pending_order=order
	is_late=late

func _order_recinded(order):
	pending_order=null
	is_late = false
	
func _on_child_entered_tree(node):
	
	if node.is_in_group("apples") or node.is_in_group("bags"):
		connect_to_signals(node)
		node.holding=false
		node.set_physics_process(true)
		node.call_deferred("reparent", $Counter)


func connect_to_signals(node):

	if !node.select_me.is_connected(_select_node):
		node.select_me.connect(_select_node)
	
	if node.is_in_group("apples"):
		if !node.out_of_bounds_top.is_connected(_carry_over):
			node.out_of_bounds_top.connect(_carry_over)
	elif node.is_in_group("bags"):
		if !node.out_of_bounds_bottom.is_connected(_carry_over):
			node.out_of_bounds_bottom.connect(_carry_over)

	
func disconnect_signals(node):
	if node.select_me.is_connected(_select_node):
		node.select_me.disconnect(_select_node)
	
	if node.is_in_group("apples"):
		if node.out_of_bounds_top.is_connected(_carry_over):
			node.out_of_bounds_top.disconnect(_carry_over)
	elif node.is_in_group("bags"):
		if node.out_of_bounds_bottom.is_connected(_carry_over):
			node.out_of_bounds_bottom.disconnect(_carry_over)
		
		
	# Selecting a node transfers all gui inputs to this class
func _select_node(node):
	if !gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)
	node.holding=true
	selected_node = node
	if check_order():
		emit_signal("order_fulfilled", pending_order.get_meta("index"))
		selected_node.call_deferred("queue_free")
		pending_order=null
		selected_node=null
	else:
		if pending_order:
			emit_signal("order_failed", pending_order.get_meta("index"))
			_deselect_node()
	
func _deselect_node():
	if gui_input.is_connected(_on_gui_input):
		gui_input.disconnect(_on_gui_input)
	selected_node.holding=false
	selected_node = null		

func _on_customer_mouse_entered():
	emit_signal("mouse_entered")


func _on_customer_mouse_exited():
	emit_signal("mouse_exited")


func _on_customer_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		emit_signal("new_customer", 1)




func _on_gui_input(event):
	
	if event.is_action_pressed("click") and selected_node != null:
		if selected_node.current_area=="Counter":
			_deselect_node()
	
	if event.is_action_pressed("right-click"):
		_carry_over()


func _carry_over():
	if selected_node != null:
		if selected_node.is_in_group("apples"):
			disconnect_signals(selected_node)
			emit_signal("carry_over", selected_node, selected_node.global_position)
			selected_node.holding=false
			selected_node = null
			

func dialog_finished():
	pass
	
