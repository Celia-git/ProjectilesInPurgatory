extends Node2D


signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_data


var width = 320
var height = 180

var current_vessel
var all_vessels = []		# Includes selected vessel
var max_vessel_amount = 7
var horizontal_shift_speed = 1.5
var syrups_left_bound = 0
var syrups_right_bound = 64
var shift_target

# areas[pump.flavor+" syrup"] = Rect2
var areas = {}
var all_flavors = {}
var pumps = []
var pump_scene = load("res://Popper/Popcorn/Pump.tscn")
var locked = false

var allowed_vessels = ["Cup", "WaffleCone", "BlizzieCup"]
var game_states

# RECTS spaced by x + 64 px

func _ready():
	
	set_process(false)
	
	# Load flavor array
	if all_flavors.is_empty():
		load_flavors()
		
	# Add Pumps as Syrups children
	if pumps.is_empty():
		load_pumps()

# Shifting the Syrups
func _process(delta):
	$Syrups.position = lerp($Syrups.position,shift_target, horizontal_shift_speed*delta)
	


func load_flavors():
	all_flavors = Globals.get_inventory("syrup")

# Return new rect with size and position set
func new_body_rect(pump, flavor):
	
	var rect = Rect2()
	rect.position = pump.global_position - (3 * Vector2(40, 32))
	rect.size = pump.get_node("Body").get_rect().size*3
	rect.size.x *= .75
	rect.size.y *= 1.15
	return rect
	

func load_pumps():
	for i in range(all_flavors.keys().size()):
		var pump = pump_scene.instantiate()
		var rect = Rect2()
		pump.position.x = i * 64
		pump.z_index = -1
		pump.set_flavor(all_flavors.keys()[i])
		pump.icon_texture = all_flavors[pump.flavor][1]
		pump.mouse_entered.connect(_mouse_entered)
		pump.mouse_exited.connect(_mouse_exited)
		pump.coat.connect(_coat.bind(i))
		$Syrups.add_child(pump)
		
		areas[pump.flavor+" syrup"] = new_body_rect(pump, pump.flavor)
		pumps.append(pump)

		if (i == all_flavors.size()-1):
			syrups_left_bound = -(i-4)*64

	
# coat: 
func _coat(flavor, amount, pump_index):
	
	# Get vessel at index
	for vessel in all_vessels:
		if !vessel.has_meta("syrups_index"):
			continue
		if !vessel.get_meta("syrups_index") == pump_index:
			continue
		# Coat vessel in syrup
		vessel.add_syrup(amount, flavor)
		return
	print("Method _coat didn't resolve.\n pump index = %d, not found in any vessel" % [pump_index])

			
### PICK UP//PUT DOWN VESSEL ###
			
			
func _select_vessel(node):
	if current_vessel !=null:
		await _deselect_vessel()
		
	current_vessel = node
	current_vessel.unlock()
	current_vessel.holding = true
	current_vessel.call_deferred("reparent",self)
			
func _deselect_vessel():
	if current_vessel !=null:
		
		# Update moved areas in node
		for area in areas:
			current_vessel.set_area(area, areas[area])
		current_vessel.active_areas = areas.values()
		
		var target_area = current_vessel.get_current_area(get_global_mouse_position()) 
		if target_area != null:
			
			# Index of the pump at which the vessel is set
			var index = current_vessel.active_areas.find(target_area)
			
			# Return if a vessel is already at that index
			for vessel in all_vessels:
				if vessel.has_meta("syrups_index"):
					if vessel.get_meta("syrups_index")==index:
						return
			
			# Find target area in dictionary
			if areas.find_key(target_area) == null:
				for key in areas.keys():
					# Get closest match
					if target_area.is_equal_approx(areas[key]):
						target_area = areas[key]
						break
				# If no closest match, abort method
				return
			var target_position =Vector2(target_area.position.x+(.25*target_area.size.x), target_area.position.y+(target_area.size.y))
			if "syrups_offset" in current_vessel:
				target_position += current_vessel.syrups_offset
			current_vessel.lock_position(target_position, .1)
			current_vessel.set_meta("syrups_index", index)
			current_vessel.call_deferred("reparent", $Syrups)
			await $Syrups.child_entered_tree
			current_vessel = null
	return
			

			
### MOVE SYRUPS LEFT/RIGHT ####   
			
func _shift_left():
	if $Syrups.position.x > syrups_left_bound:
		shift_target = Vector2(syrups_left_bound, $Syrups.position.y)
		set_process(true)
	

func _shift_right():
	if $Syrups.position.x < syrups_right_bound:
		shift_target = Vector2(syrups_right_bound, $Syrups.position.y)
		set_process(true)
	

func _on_shift_workspace_mouse_shape_entered(shape_idx):
	match shape_idx:
		0:
			$ShiftWorkspace/Left.visible = true
			_shift_right()
		1:
			$ShiftWorkspace/Right.visible = true
			_shift_left()

func _on_shift_workspace_mouse_shape_exited(shape_idx):
	$ShiftWorkspace/Left.visible = false
	$ShiftWorkspace/Right.visible = false
	# Add area rects
	for pump in pumps:
		var flavor = pump.flavor
		areas[flavor+" syrup"] = new_body_rect(pump, flavor)
	set_process(false)


func connect_vessel(node):
	if node.is_in_group("vessels"):
		if all_vessels.size() == max_vessel_amount:
			emit_signal("carry_back", node)
			return
		locked = true
		node.active_areas = areas.values()
		node.frame = Globals.pixelframe
		node.z_index = 2
		if !node.out_of_bounds.is_connected(_vessel_out_of_bounds):
			node.out_of_bounds.connect(_vessel_out_of_bounds)
		if !node.select_me.is_connected(_select_vessel):
			node.select_me.connect(_select_vessel)
		all_vessels.append(node)
		_select_vessel(node)
			
func disconnect_vessel(node):
	if node.is_in_group("vessels"):
		
		
		if node.out_of_bounds.is_connected(_vessel_out_of_bounds):
			node.out_of_bounds.disconnect(_vessel_out_of_bounds)
		if node.select_me.is_connected(_select_vessel):
			node.select_me.disconnect(_select_vessel)
			
		# Unlock map if no more vessels in map
		node.z_index = 0
		if node == current_vessel:
			current_vessel=null
		all_vessels.erase(node)
		locked = !all_vessels.is_empty()

			
func _vessel_out_of_bounds():
	var margin = 10
	if current_vessel:
		if current_vessel.global_position.y > (Globals.pixelframe.position.y+Globals.pixelframe.size.y-margin):
			emit_signal("carry_over", current_vessel, current_vessel.global_position, true)
		elif current_vessel.global_position.y < (Globals.pixelframe.position.y+margin):
			emit_signal("carry_over", current_vessel, current_vessel.global_position, true)
			
			

func get_areas():
	
	return areas

func _mouse_entered():
	emit_signal("mouse_entered")
	
func _mouse_exited():
	emit_signal("mouse_exited")
	

func dialog_finished():
	pass
