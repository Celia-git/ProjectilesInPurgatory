extends Vessel

class_name WaffleCone

var syrups_offset = Vector2(-8, -8)

# How many standard units the vessel can hold
func set_capacity():
	capacity = 4
	remaining_capacity = capacity
	
func set_vessel_type():
	vessel_type = "WaffleCone"

func _set_sprite_texture(atlas):
	holding_offset = Vector2(-24,32)
	$Sprite2D.set_texture(atlas)
	$Sprite2D.offset.y = -16
	$CollisionShape2D.position.y = -16
	return
