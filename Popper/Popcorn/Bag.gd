extends StaticBody2D

signal select_me
signal out_of_bounds_left
signal out_of_bounds_right
signal out_of_bounds_bottom

@export var popcorn_count = 0

var rest_position
var rest_position_relative
var global_rest_position = Vector2(259, 650)
var local_rest_position = Vector2(64, 148)
var areas = {}
var current_area
var active_areas = []
var frozen = true

var speed = 50
var speed_scale = 10
var global_speed_scale = 25
var holding = false
var frame = Globals.bigframe

var coating = {}
var min_coating = .5
var max_coating = 1.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if holding:
		var target_position = get_global_mouse_position()
		if frame.has_point(target_position):
			global_position=lerp(global_position, target_position, speed*delta)
			
			# Move to next/prev workspace if horizontally out of bounds
		else:
			if target_position.x > frame.position.x+frame.size.x:
				emit_signal("out_of_bounds_right")	
			elif target_position.x < frame.position.x:
				emit_signal("out_of_bounds_left")	
			elif target_position.y > frame.position.y+frame.size.y:
				emit_signal("out_of_bounds_bottom")
				
		# Detect current area
		# Determine if point intersects key areas
		if active_areas:
			if current_area:
				if !current_area.has_point(position):
					reset_rest_position()
					current_area = null
			else:

				for area in active_areas:
					if area != null:
						if area.has_point(position):
							# Top Shelf z-index
							if active_areas.find(area) < 3:
								z_index=0
							elif active_areas.find(area) >= 3:
								z_index=1
							rest_position = Vector2(area.position.x+10, area.get_center().y)
							current_area = area


		
func set_area(key:Rect2, value:String):
	areas[key] = value
	
# Workspace: true- Apple Workspace in pixelworld// false-canvas layer carryover 
func shift_to_area(workspace):
	if workspace:
		rest_position_relative="LOCAL"
		set_frame(Globals.pixelframe)
		active_areas=[]
		for value in areas.values():
			if value.begins_with("Pump"):
				active_areas.append(areas.find_key(value))
	else:
		rest_position_relative="GLOBAL"
		set_frame(Globals.bigframe)
		active_areas = [areas.find_key("PopcornRack"), areas.find_key("Counter"), areas.find_key("OutputBag")]
		

	reset_rest_position()

func reset_rest_position():
	match rest_position_relative:
		"GLOBAL":
			rest_position = global_rest_position
		"LOCAL":
			rest_position=local_rest_position

func _on_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		if !holding:
			emit_signal("select_me", self)
	



func set_frame(new_frame):
	frame = Rect2(new_frame.position.x, new_frame.position.y, new_frame.size.x-20, new_frame.size.y+20)


func _on_area_2d_body_entered(body):
	if body.is_in_group("Popcorn"):
		if is_instance_valid(body):
			
			if popcorn_count > 15:
				body.call_deferred("reparent", self)
				body.call_deferred("set_process", false)
			else:
				await get_tree().create_timer(.25).timeout
				if is_instance_valid(body):			
					popcorn_count += 1
					body.call_deferred("queue_free")

func _on_child_entered_tree(node):
	if node.is_in_group("Popcorn"):
		popcorn_count += 1
		frozen=false

# Return  in an array
func formatted():
	var return_values = ["Bag of Popcorn"]
	if coating:
		for coat in coating.keys():
			if (coating[coat] < max_coating) && (coating[coat] > min_coating):
				return_values.append("with %s Sauce" % [coat])
			elif (coating[coat] > max_coating):
				return_values.append("with extra %s Sauce" % [coat])
	return return_values
	


func _coated(flavor, amount):
	
	if amount > min_coating:
		for child in get_children():
			if child.is_in_group("Popcorn"):
				child.coat(flavor)
	
	coating[flavor] = amount
	
	
	
# Freeze all popcorn children
func freeze():
	for child in get_children():
		if child.is_in_group("Popcorn"):
			child.freeze=true
			child.get_node("CollisionShape2D").call_deferred("set_disabled", true)
	frozen=true


func _on_child_exiting_tree(node):
	if node.is_in_group("Popcorn"):
		popcorn_count -= 1
