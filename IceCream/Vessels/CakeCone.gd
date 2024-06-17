extends Vessel

class_name Cakecone



# How many standard units the vessel can hold
func set_capacity():
	capacity = 3
	remaining_capacity = capacity
	
func set_vessel_type():
	vessel_type = "CakeCone"

func _set_sprite_texture(atlas):
	holding_offset = Vector2(-24,32)
	$Sprite2D.set_texture(atlas)
	$Sprite2D.offset.y = -8
	$CollisionShape2D.position.y = -16
	return
