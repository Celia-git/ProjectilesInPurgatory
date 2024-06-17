extends RigidBody2D



################ Prize Data #####################
# Capsules
var set_name:String
var set_size:int
var set_atlas_region:Rect2
var fixed_icon_position:bool
# Prize Texture Region
var atlas_region:Rect2

# Treasure chest contains multiple figurines
var prizes = {}	# {prize_name:prize_atlas_region}

var prize_name:String
var meta_combo=[]
var inventory_location:String # locaton in knapsack

# Node data
var sprite_color:Color		# For candy and toys
var sprite_hue:float		# For dual colored capsules
var sprite:Sprite2D	# Direct child sprite

var asset_names=[]

# CLAW: Add sprite node as child of prize. Stacks sprite nodes
func add_sprite(add_sprite:Sprite2D):
	
	if self.sprite != null:
		self.sprite.add_child(add_sprite)
		return
	self.sprite = add_sprite
	self.sprite.set_scale(Vector2(3, 3))
	add_child(sprite)

	
# Set youngest sprite color modulation
func set_sprite_color(color:Color):
	
	self.sprite_color=color
	if sprite != null:
		if sprite.get_child_count()>0:
			for grandchild in sprite.get_children():
				if grandchild is Sprite2D:
					sprite.self_modulate = sprite_color.lightened(randf_range(.6, .8))
					grandchild.self_modulate = sprite_color
					return
		sprite.self_modulate = sprite_color
			
# set sprite hue through color modulation: set first two sprites to random complementary hues
func set_sprite_hue(hue=0.0):
	if hue==0.0:
		hue = float(randi_range(0, 99)) * .01
	self.sprite_hue = hue
	if sprite != null:
		var new_color = Color(1, .76, .29, 1)
		new_color.h = sprite_hue
		sprite.self_modulate = new_color
		if sprite.get_child_count()>0:
			for grandchild in sprite.get_children():
				if grandchild is Sprite2D:
					var new_new_color = Color(.25, .39, .96, 1)
					new_color.h = abs(sprite_hue-[0.3, .5, .6, .9][randi_range(0, 3)]) 
					grandchild.self_modulate = new_color
					
# Return a dict of data pertaining to this prize
func get_prize_data():
	if prize_name=="Treasure Chest":
		return {"name":prize_name, "prize_data":{"set_name":set_name,"set_size":set_size, "set_atlas_region":set_atlas_region, "fixed_icon_position":fixed_icon_position, "prize_data":prizes, "meta_combo":meta_combo}, "inventory_location":"Front Pocket"}
	return {"name":prize_name, "set_name":set_name,"set_size":set_size, "atlas_region":atlas_region, "fixed_icon_position":fixed_icon_position, "meta_combo":meta_combo, "color":sprite_color, "inventory_location":inventory_location,"assets":asset_names}
					
# Called by candy claw machine
func _stabilize(toybox):
	if toybox.has_point(global_position):
		sleeping = true
