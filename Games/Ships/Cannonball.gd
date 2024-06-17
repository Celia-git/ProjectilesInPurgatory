extends RigidBody2D

signal out_of_bounds

const MIN_SCALE = Vector2(1, 1)
const SPEED = 4

@export var dropping = false

# Scale RigidBody Children
func _ready():
	for child in get_children():
		if "scale" in child:
			child.set_scale(Vector2(3,3))
	visible = true

func _process(delta):
	if dropping:
		if !Globals.pixelframe.has_point(global_position):
			emit_signal("out_of_bounds")
		

func set_img_texture(ball_texture):
	$Sprite2D.texture = ball_texture

func drop():
	dropping = true

