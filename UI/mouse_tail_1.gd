extends MouseTail

var sprinkle_node
var sprinkle_timer
var rainbow_color_ramp = load("res://UI/rainbow_color_ramp.tres")

# Strawberry mouse tail:
	# on begin motion, emit explosion of sprinkles
	
# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	sprinkle_node = CPUParticles2D.new()
	sprinkle_node.explosiveness=5
	sprinkle_node.amount = pow(self.amount, 2)
	sprinkle_node.lifetime = 1.5
	sprinkle_node.lifetime_randomness = 1
	sprinkle_node.initial_velocity_min = 400
	sprinkle_node.direction = Vector2(0, -1)
	sprinkle_node.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sprinkle_node.emission_sphere_radius = 100
	sprinkle_node.spread = 180
	sprinkle_node.angle_max = 360
	sprinkle_node.angle_curve = mouse_rotational_curve
	sprinkle_node.emitting = false
	sprinkle_node.texture = load("res://Assets/custom_mouse1_effect0.png")
	sprinkle_node.color_initial_ramp = rainbow_color_ramp
	sprinkle_node.color_ramp = color_ramp_gradient
	add_child(sprinkle_node)
	
	sprinkle_timer = Timer.new()
	sprinkle_timer.timeout.connect(_on_sprinkle_timer_timeout)
	add_child(sprinkle_timer)


func _input(event):

	# activate mouse trail
	if (event is InputEventMouseMotion):
		if !emitting:
			emitting = true 
			if sprinkle_node != null:
				sprinkle_node.global_position = global_position
				sprinkle_node.emitting = true
				sprinkle_timer.start(1)
			set_process(true)

		mouse_velocity = event.relative
		
func _on_sprinkle_timer_timeout():
	sprinkle_node.emitting = false 
	sprinkle_timer.stop()
	

func set_length(len:int):
	if sprinkle_node != null:
		sprinkle_node.amount = pow(self.amount, 2)
	super.set_length(len)
