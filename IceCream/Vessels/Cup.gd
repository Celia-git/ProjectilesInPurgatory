extends Vessel

# Vessel for holding ice cream, soda, milk, syrups, and/or toppings
class_name Cup


var blender_offset = Vector2(-12, 96)

	
# How many standard units the vessel can hold
func set_capacity():
	capacity = 8
	remaining_capacity = capacity
	
func set_vessel_type():
	vessel_type = "Cup"


func _set_sprite_texture(atlas):
	holding_offset = Vector2(-16,32)
	$Sprite2D.set_texture(atlas)
	$Sprite2D.offset.y = -16
	$CollisionShape2D.position.y = -16
	return

