extends RigidBody2D


var flavor

# Scale RigidBody Children
func _ready():
	for child in get_children():
		child.set_scale(Vector2(3,3))
	await get_tree().create_timer(.05).timeout
	visible = true

func set_texture(texture):
	$Sprite2D.texture = texture
