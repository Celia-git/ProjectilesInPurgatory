extends Vessel

# Vessel for holding ice cream, soda, milk, syrups, and/or toppings
class_name BlizzieCup


var blender_offset = Vector2(-8, 48)
var syrups_offset = Vector2(0, -16)
	
# How many standard units the vessel can hold
func set_capacity():
	capacity = 4
	remaining_capacity = capacity
	
func set_vessel_type():
	vessel_type = "BlizzieCup"


func _set_sprite_texture(atlas):
	holding_offset = Vector2(-16,16)
	$Sprite2D.set_texture(atlas)
	$Sprite2D.offset.y = -8
	$CollisionShape2D.position.y = -8
	return

