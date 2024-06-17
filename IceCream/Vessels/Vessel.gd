extends Area2D

class_name Vessel

signal select_me
signal out_of_bounds
signal overflow
signal capacity_updated
signal valid_select

# All Vessels: Inherited by Cups and Cones



# Dicts of contained flavors// {"FLAVOR":String :: AMOUNT:Int)
var ice_cream = {} 
var soda = {}
var syrup = {}
var topping = {}
var milk:float
var late:float
var blend:float
var whip:bool
var cherry:bool

var final_score
var vessel_type # Name of vessel aka cup, cone
# how much ingredients can be kept in vessel
var capacity
var remaining_capacity
# Different coordinates of vessel sprites
var atlas_regions = {"Cup": Rect2(0, 0, 32, 48),
	"BlizzieCup":Rect2(32, 0, 32, 32),
	"CakeCone":Rect2(0, 48, 32, 32),
	"WaffleCone":Rect2(32, 32,32,64)}
# amount of ice cream tiles
var ice_cream_tile_amount = 0
var ice_cream_tile_height = 11
# X-offset of vessel position over the duration of various animations
var animated_offsets = {"loop":[6,3,1,-4,-7,-9,-7,-5,-2,0], 
"ending":[3,6,3,0,-4,-9,-6,0,2,0]}


# Movement variables
var areas = {}
# Array of RECTS
var active_areas = []
# Rect
var current_area
var frame
var speed = 50
var holding_offset = Vector2(0,0)
var locked = false
@export var holding = false


func _ready():
	set_vessel_type()
	set_capacity()
	set_texture()
	set_collision_shape()
	self.ice_cream_tile_amount = 0
	
	var entry = get_node_or_null("Entry")
	if entry != null:
		if !entry.body_entered.is_connected(_on_body_entered):
			entry.body_entered.connect(_on_body_entered)
	if !input_event.is_connected(_on_input_event):
		input_event.connect(_on_input_event)
	
func _process(delta):
	if holding:
		
		var target_position = get_global_mouse_position()+holding_offset
		global_position = lerp(global_position, target_position, speed*delta)
			
		# If out of bounds
		if !frame.has_point(target_position):
			emit_signal("out_of_bounds")

		current_area = get_current_area(target_position)


func get_current_area(target_position):
		# Determine if point intersects key areas
		if current_area != null:
			if !current_area.has_point(target_position):
				return null
				
		else:
			for area in active_areas:
				if area != null:
					if area.has_point(target_position):
						return area

func get_current_area_name():
	if current_area != null:
		if current_area in areas.keys():
			return areas[current_area]
	else:
		return null


func set_area(area_name, rect):
		
	areas[rect] = area_name

func set_texture():
	var atlas = AtlasTexture.new()
	var texture = $Sprite2D.texture.duplicate()
	atlas.set_atlas(texture)
	atlas.set_region(atlas_regions[vessel_type])
	$Sprite2D.offset.y = -(atlas.region.size.y/2)
	_set_sprite_texture(atlas)
	
	
func set_collision_shape():
	$CollisionShape2D.shape = RectangleShape2D.new()
	var rect = $Sprite2D.get_rect()
	$CollisionShape2D.shape.size = rect.size 
	
func set_capacity():
	return

func set_vessel_type():
	return
	
# Calculate final score based on all given data
func set_score(seconds_late):
	late = seconds_late
	final_score = 0

func set_blend(amount:float):
	blend = amount

# Add toppings data
func add_topping(amount:float, flavor):
	
	if !(remaining_capacity - amount > 0):
		emit_signal("overflow", "topping", flavor)
		return
		
	if !flavor in topping.keys():
		topping[flavor] = amount
	else:
		topping[flavor] += amount
	
	remaining_capacity -= amount
	
	if amount > 0:
		set_blend(0)
		set_whip(false)
		set_cherry(false)

# Add syrup data
func add_syrup(amount:float, flavor=""):
	
	if !(remaining_capacity - amount > 0):
		emit_signal("overflow", "syrup", flavor)
		return
	
	if !flavor in syrup.keys():
		syrup[flavor] = amount
	else:
		syrup[flavor] += amount 

	remaining_capacity -= amount
	
	if amount > 0:
		emit_signal("overflow", "syrup", flavor)
		set_blend(0)
		set_whip(false)
		set_cherry(false)


# Add ice cream data
func add_ice_cream(amount:float, flavor=""):
	
	if !(remaining_capacity - amount > 0):
		emit_signal("overflow", "ice cream", flavor)
	
	if !flavor in ice_cream.keys():
		ice_cream[flavor] = amount
	else:
		ice_cream[flavor] += amount
	
	
	# Add a new looping ice cream tile
	
	ice_cream_tile_amount += 1
	remaining_capacity -= amount
	emit_signal("capacity_updated", get_meta("ice_cream_index"))
	
	var drip = get_node_or_null("IceCreamDrip")
	
	$IceCream.visible = true
	# Iterate flavors in ice cream dict
	var amt = 0
	for flav in ice_cream.keys():
		amt += ice_cream[flav]
	
	var ice_cream_sprite
	if amt <= 1:
		ice_cream_sprite = $IceCream
	else:
		ice_cream_sprite = $IceCream.duplicate()
		add_child(ice_cream_sprite)
		
	# Add new image for each "loop" of ice cream
	
	ice_cream_sprite.animation_finished.connect(_on_ice_cream_animation_finished.bind(ice_cream_sprite))
	ice_cream_sprite.animation_looped.connect(_on_ice_cream_animation_looped.bind(ice_cream_sprite))
	ice_cream_sprite.frame_changed.connect(_on_ice_cream_frame_changed.bind(ice_cream_sprite))
	ice_cream_sprite.add_to_group("ice_cream")
	ice_cream_sprite.position = Vector2(0,0)
	ice_cream_sprite.offset.y = -(amt * ice_cream_tile_height)
	ice_cream_sprite.offset.y += (amt)
	
	if drip != null:
		drip.offset.y = (-(amt * ice_cream_tile_height)-10)

	move_child($Sprite2D, -1)

	if amount > 0:
		set_blend(0)
		set_whip(false)
		set_cherry(false)

# Add soda data
func add_soda(amount:float, flavor=""):
	
	if !(remaining_capacity - amount > 0):
		emit_signal("overflow", "soda", flavor)
		return
	
	if !flavor in soda.keys():
		soda[flavor] = amount
	else:
		soda[flavor] += amount
		
	remaining_capacity -= amount
	emit_signal("capacity_updated")
		
	if amount > 0:
		set_blend(0)
		set_whip(false)
		set_cherry(false)

func set_whip(w):
	whip=w

func set_cherry(c):
	cherry=c
	

	

func _on_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click") and !holding:
		emit_signal("select_me", self)
		

# If node is locked: other vessels cannot be selected// Game Scene cannot be changed
func is_locked():
	return locked

# Lock a node (not holding, specific position)
func lock_position(pos, time_scale=1):
	var tween = create_tween()
	tween.tween_property(self, "global_position", pos, .5*time_scale)
	holding = false
	locked = true
	
	
func unlock():
	locked = false
	
func _set_sprite_texture(atlas):
	return

# Body entered "Enter" area
func _on_body_entered(body):
	if body.is_in_group("toppings"):
		add_topping(.06, body.flavor)
		body.call_deferred("queue_free")



func change_scale(arg):
	var new_scale = Vector2(1,1)
	match arg:
		
		# Foreground/Blender scale is relative to big frame
		"foreground":
			new_scale = Vector2(4,4)
		"blender":
			new_scale = Vector2(5,5)
		"ice cream":
			new_scale = Vector2(3, 3)
		"soda":
			new_scale = Vector2(3,3)
			
		
		# Syrups/Toppings scale is relative to pixel window size 
		"toppings":
			new_scale = Vector2(1, 1)		
		"syrups":
			new_scale = Vector2(1, 1)
			
	var tween = create_tween()
	tween.tween_property(self, "scale", new_scale, .3).set_trans(Tween.TRANS_EXPO)


# Use Ratio of remaining empty space to vessel to calculate global coordinates of ceiling			
func get_content_ceiling():
	var height = atlas_regions[vessel_type].size.y
	if ice_cream_tile_amount > 0:
		var dripper = get_node_or_null("IceCreamDrip")
		var peak = 0
		if dripper:
			peak = 16
		return global_position.y - ((ice_cream_tile_height * 3 * (ice_cream_tile_amount)) + peak)
	
	return global_position.y #- (remaining_capacity/capacity)*height

# Animation Methods

func add_ice_cream_drip(drip:AnimatedSprite2D, flavor):
	drip.name = "IceCreamDrip"
	drip.set_meta("flavor", flavor)
	add_child(drip)
	move_child($Sprite2D, -1)
	drip.position = Vector2(0,0)
	drip.offset = Vector2(0,-(ice_cream_tile_amount*ice_cream_tile_height)-8)
	drip.animation_looped.connect(_on_ice_cream_animation_looped.bind(drip))
	drip.animation_finished.connect(_on_ice_cream_animation_finished.bind(drip))
	drip.frame_changed.connect(_on_ice_cream_frame_changed.bind(drip))

func play_animation(arg):
	var animation = arg.split("//") 
	match animation[0]:
		"ice_cream":
			var ice_cream_drip = get_node_or_null("IceCreamDrip")
			if ice_cream_drip != null:
				ice_cream_drip.play(animation[1])
			if animation[1] == "ending":
				for child in get_children():
					if child.is_in_group("ice_cream"):
						child.play("ending")


func _on_ice_cream_animation_looped(sprite):
	
	if sprite.has_meta("flavor"):
		var flavor = sprite.get_meta("flavor")
		add_ice_cream(1, flavor)

func _on_ice_cream_frame_changed(sprite):
	# Change x-position of vessel sprite to match animation
	if !(sprite.animation=="default" || sprite.animation=="default_filled"):
		var frame_idx = sprite.frame
		if self.has_meta("ice_cream_position"):
			if sprite.animation in animated_offsets.keys():
				var target_pos_x = (get_meta("ice_cream_position")+ (3*animated_offsets[sprite.animation][frame_idx]))
				$Sprite2D.global_position.x = target_pos_x
		
	# Set ice cream tile children which were just added in motion
	for child in get_children():
		if child.is_in_group("ice_cream") and !child.is_playing():
			child.animation = sprite.animation
			child.frame = sprite.frame
			if child.sprite_frames.has_animation(sprite.animation):
				child.play(sprite.animation)

func _on_ice_cream_animation_finished(sprite):
	if sprite.animation == "beginning":
		# Only dripper node has metadata flavor
		if sprite.has_meta("flavor"):
			add_ice_cream(1, sprite.get_meta("flavor"))
		sprite.play("loop")
		for child in get_children():
			if child.is_in_group("ice_cream"):
				child.play("loop")
	elif sprite.animation == "ending":
		if self.has_meta("ice_cream_position"):
			var dripper = get_node_or_null("IceCreamDrip")
			if dripper != null:
				dripper.play("default_filled")
			sprite.play("default_filled")
			$Sprite2D.position.x = 0 
			emit_signal("valid_select")

