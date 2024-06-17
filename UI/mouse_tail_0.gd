extends CPUParticles2D

class_name MouseTail

var OFFSET = Vector2(48, 32)
var previous_mouse_position:Vector2
var mouse_velocity = Vector2(0,0)
var action:int=0
var speed:float=0
var circle_velocity_curve = load("res://UI/orbital_velocity.tres")
var mouse_rotational_curve = load("res://UI/rotation_curve.tres")
var mouse_damping_curve = load("res://UI/rotation_damping_curve.tres")
var color_ramp_gradient = load("res://UI/color_ramp.tres")
var timer

func _init(length:int, actin:int, text:Texture2D):

	set_length(length)	
	set_action(actin)
	self.angle_curve = mouse_rotational_curve
	self.damping_min = 0
	self.damping_max = 10
	self.mouse_damping_curve = mouse_damping_curve
	self.texture = text
	self.position += OFFSET
	self.color_ramp = color_ramp_gradient
	self.speed_scale = .8
	
	
	
# Track + follow mouse position
func _process(delta):

	global_position = lerp(global_position, get_global_mouse_position()+OFFSET, delta*speed)
	

func _ready():
	timer = Timer.new()
	timer.timeout.connect(_on_particle_timer_timeout)
	add_child(timer)
	timer.start(.2)
	
func _input(event):

	# activate mouse trail
	if (event is InputEventMouseMotion):
		if !emitting:
			emitting = true 
			set_process(true)

		mouse_velocity = event.relative
		linear_accel_min = mouse_velocity.length()/4.0
	
# Auto-off mouse trail when mouse not moving
func _on_particle_timer_timeout():
	var estimate = Vector2(48, 48)
	var rect = Rect2(previous_mouse_position-(estimate/2), estimate)
	if rect.has_point(get_global_mouse_position()):
		emitting = false
		set_process(false)
	self.angle_max = mouse_velocity.length_squared()
	previous_mouse_position = get_global_mouse_position()
	speed = mouse_velocity.length()
	
func set_action(act:int):
	self.action = act
	match action:
		1:	# Moon
			self.gravity = -Vector2(200, 200)
			self.speed_scale = .5
			self.explosiveness=0
			self.orbit_velocity_max = 0
			self.radial_accel_max = 0
			emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
			if OFFSET.x > 0:
				OFFSET *= -1
		2:  # Circle
			self.gravity = Vector2(0, 0)
			self.speed_scale = .8
			self.orbit_velocity_max = amount
			self.orbit_velocity_curve = circle_velocity_curve
			self.explosiveness=.3
			emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE_SURFACE
			emission_sphere_radius = self.amount
			if OFFSET.x < 0:
				OFFSET *= -1
		_:	# Default
			self.gravity = Vector2(200, 450)
			self.speed_scale = 1
			self.explosiveness=0
			self.orbit_velocity_max = 0
			self.radial_accel_max = 0
			emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
			if OFFSET.x < 0:
				OFFSET *= -1

func set_length(len:int):
	self.amount = len
	self.lifetime = float(len)/15.0	
	if action == 2:
		orbit_velocity_max = self.amount
		emission_sphere_radius = self.amount

func get_action():
	return self.action
	
func get_length():
	return amount

