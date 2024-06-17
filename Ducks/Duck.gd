extends RigidBody2D

signal selected

var radius = Vector2(0,0)
var trajectory = Vector2(0,0)
var velocity = Vector2(0,0)
var impulse_scalar = -.001
var centripetal_scalar = .3
var is_selected = false

# Manually scale rigid body children
func _ready():
	for child in get_children():
		if "scale" in child:
			child.set_scale(Vector2(3,3))

func _physics_process(delta):
	trajectory = radius.orthogonal()
	velocity = trajectory * centripetal_scalar
	move_and_collide(velocity*delta)
	
	
func set_vars(radius_vector):
	radius = radius_vector
	var x_coordinate = 16*(get_meta("Index")%2)
	$Sprite2D.set_region_rect(Rect2(Vector2(x_coordinate, 0), Vector2(16, 16)))
	set_rotation(randi_range(0, 360))


func _on_body_entered(_body):
	apply_central_impulse(impulse_scalar*velocity)


func _on_input_event(_viewport, event, _shape_idx):
	if event.is_action_pressed("click"):
		if !is_selected:
			emit_signal("selected", self)
