extends CharacterBody2D

signal out_of_bounds_left
signal out_of_bounds_right
signal out_of_bounds_top
signal out_of_bounds_bottom


signal select_me
signal animation_over
signal dip_over
signal roll_over

const MAX_TOPPINGS = 35

var animation_frames_caramel = load("res://Popper/Resources/CaramelAppleAnimation.tres")
var animation_frames_candy = load("res://Popper/Resources/CandyAppleAnimation.tres")
@onready var toppings_image = $Toppings.get_texture().get_image()

var frame
var areas = {}
var active_areas
var current_area 
var current_area_rect

var speed = 45 # Speed at which apple follows cursor when holding==true
var speed_scale = 15.0 # Scalar for determining speed at which apple moves on its own relative to distance
var global_speed_scale = 25.0
var roll_speed = 5
var delta_roll_step = .125
var target_roll_position = null

@export var holding = false
var rolling = false
var dipping = false
var coating
var topping_count = 0
var topping_data = {}# Dict of how many of each type of topping contribute

func _ready():
	$Apple/Sprite.set_animation("Default")
	$Apple/Sprite.set_frame(0)
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	if holding:
		# Travelling
		if !rolling:
			# Calculate new position
			
			# Exclude out_of_bounds travel
			var target_position = get_global_mouse_position()+Vector2(-10, 50)
			if frame.has_point(target_position):
				global_position = lerp(global_position, target_position, speed*delta)
				
			# If out of bounds
			else:
				# Move to next/prev workspace if horizontally out of bounds
				if target_position.x > frame.position.x+frame.size.x:
					emit_signal("out_of_bounds_right")	
				elif target_position.x < frame.position.x:
					emit_signal("out_of_bounds_left")			
				# Move to outer Apple Rack or trash if vertically out of bounds
				elif target_position.y < frame.position.y:
					emit_signal("out_of_bounds_top")
				elif target_position.y > frame.position.y+frame.size.y:
					emit_signal("out_of_bounds_bottom")
					
			# Determine if point intersects key areas
			if current_area:
				if !current_area_rect.has_point(position+Vector2(0, 20)):
					current_area_rect = null
					current_area = null
					
			else:
				for area in active_areas:
					if area != null:
						if area.has_point(position+Vector2(0, 20)):
							current_area_rect = area
							current_area = areas[area]
						
						
	elif rolling && target_roll_position:
		if  position == target_roll_position:
			target_roll_position=null
		position = position.lerp(target_roll_position, roll_speed*delta)
			
		
func set_area(key:Rect2, value:String):
	areas[key] = value
	
# Workspace: true- Apple Workspace in pixelworld// false-canvas layer carryover 
func shift_to_area(area, workspace=true):
	if workspace:
		active_areas = [areas.find_key("AppleStand")]
	else:
		active_areas = [areas.find_key("AppleRack")]
	match area:
		"Toppings":
			for value in areas.values():
				if value.begins_with("Toppings"):
					active_areas.append(areas.find_key(value))
		"Pots":
			for value in areas.values():
				if value.ends_with("Pot"):
					active_areas.append(areas.find_key(value))
		"Window":
			for value in areas.values():
				if value=="Counter":
					active_areas.append(areas.find_key(value))


	
			
func dip():
	holding = false
	dipping = true
	$Apple/Sprite.set_animation("Dipping")
	$Apple/Sprite.play()
	
func undip(dip_type):
	
	if dip_type=="Caramel":
		$Apple/Sprite.set_sprite_frames(animation_frames_caramel)
	elif dip_type=="Candy":
		$Apple/Sprite.set_sprite_frames(animation_frames_candy)
	
	coating = dip_type
	$Apple/Sprite.set_animation("Undipping")
	$Apple/Sprite.play()
	await $Apple/Sprite.animation_finished
	$Apple/Sprite.set_animation("DefaultCoated")
	$Apple/Sprite.play()
	holding = true
	dipping = false
	emit_signal("dip_over")
	
func toppings():
	
	rolling = true
	holding = false
	target_roll_position=null
	$AnimationPlayer.play("rotate")
	await $AnimationPlayer.animation_finished
	set_rolling_collisions()
	$AnimationPlayer.set_current_animation("roll")
	$AnimationPlayer.pause()

func roll(direction):
	var t = $AnimationPlayer.current_animation_position
	$AnimationPlayer.play()
	match direction:
		"down":
			if (t - delta_roll_step) > 0:
				$AnimationPlayer.seek(t-delta_roll_step, true)
			else:
				$AnimationPlayer.seek($AnimationPlayer.current_animation_length)
			
			target_roll_position = position+Vector2(0, 5)
		"up":
			if (t + delta_roll_step) < $AnimationPlayer.current_animation_length:
				$AnimationPlayer.seek(t+delta_roll_step, true)
			else:
				$AnimationPlayer.seek(0)
			
			target_roll_position = position-Vector2(0, 5)
			
	$AnimationPlayer.pause()

			
func cancel_roll():
	remove_rolling_collisions()
	$AnimationPlayer.play_backwards("rotate")
	await $AnimationPlayer.animation_finished
	emit_signal("roll_over")


# If rolling the apple in toppings
func set_rolling_collisions():
	$Coating.disabled = false
	$Apple/Collision.disabled = true
	set_collision_layer_value(1, true)
	set_collision_mask_value(1, true)
	
func remove_rolling_collisions():
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	$Apple/Collision.call_deferred("set_disabled", false)
	$Coating.call_deferred("set_disabled",true)
	

func can_be_released():
	return (holding && !dipping && !rolling && !$AnimationPlayer.is_playing())


func _on_apple_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		if !holding:
			emit_signal("select_me", self)
			
# replace topping nodes with textures
func add_to_self(image, offset, topping_node):
	# draw image to Toppings texture
	var max_size = toppings_image.get_size()
	random_change(image)
	var origin = Vector2i(offset.x+16, offset.y)
	var size = image.get_size()
	
	if !Rect2(Vector2(0,0), max_size).encloses(Rect2(origin, size)):
		return
	elif (origin.y > 24) && (origin.x < 8 || origin.x>24):
		return
		
	for x in range(size.x):
		for y in range(size.y):
			var current_pos = origin+Vector2i(x,y)
			var pixel_value = image.get_pixelv(Vector2i(x, y))
			if pixel_value.a !=0:
				toppings_image.set_pixelv(current_pos, pixel_value)
	topping_node.queue_free()
	if topping_node.flavor in topping_data.keys():
		topping_data[topping_node.flavor] += 1
	else:
		topping_data[topping_node.flavor] = 1
	topping_count+=1
	$Toppings.set_texture(ImageTexture.create_from_image(toppings_image))
	if topping_count>=MAX_TOPPINGS:
		remove_from_group("sticky")

func random_change(image):
	var i = randi_range(0, 4)
	match i:
		0:
			image.rotate_180()
		1:
			image.rotate_90(CLOCKWISE)
		2:
			image.rotate_90(COUNTERCLOCKWISE)
		3:
			pass

func set_frame(new_frame):
	frame = Rect2(new_frame.position, Vector2(new_frame.size.x,new_frame.size.y+30)) 

# Return coating and toppings in an array
func formatted():
	var topping_final = ""
	if topping_count > MAX_TOPPINGS*.8:
		# Express the amount of toppings as ratios of all toppings
		var highest_ratio=0
		for key in topping_data.keys():
			var ratio = float(topping_data[key])/float(topping_count)
			topping_data[key]=ratio
			if ratio > highest_ratio:
				highest_ratio=ratio
		return ["%s Apple" % [coating], topping_data.find_key(highest_ratio)]
	
	return ["%s Apple" % [coating]]
