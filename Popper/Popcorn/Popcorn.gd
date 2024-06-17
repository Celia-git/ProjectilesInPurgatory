extends RigidBody2D

var MAX_TIME = 0
var POPPED_MASS = 0.5
var POPPED_RADIUS = 6
var kernel_texture
var popped_texture
var coated_texture
@onready var MIN_TIME = MAX_TIME-float(.4*MAX_TIME)

# Called when the node enters the scene tree for the first time.
func _ready():
	$Sprite2D.texture = kernel_texture
	set_meta("state", "kernel")
	add_to_group("Popcorn")
	var valid = randi_range(0, 20)
	if valid:
		$Timer.wait_time = randf_range(MIN_TIME, MAX_TIME) 
		$Timer.start()
	for child in get_children():
		if "scale" in child:
			child.set_scale(Vector2(3,3))

	
func _process(delta):
	if !Globals.bigframe.has_point(global_position):
		queue_free()
	
# Convert from kernel to popped corn, apply vertical impulse
func _on_timer_timeout():
	$Sprite2D.texture = popped_texture
	mass = POPPED_MASS
	$CollisionShape2D.shape = CircleShape2D.new()
	$CollisionShape2D.shape.radius = POPPED_RADIUS
	$Sprite2D.offset.y += POPPED_RADIUS
	set_meta("state", "popped")
	apply_central_impulse(Vector2(0, -150))

# Pause/unpause timer
func pause_timer(pause:bool):
	if $Timer.time_left:
		$Timer.paused = pause

# Show coated texture
func coat(flavor):
	$Sprite2D2.texture = coated_texture
	$Sprite2D2.offset.y += POPPED_RADIUS
	var new_color = Globals.get_color(flavor)
	new_color.a = 100
	var tween = create_tween()
	tween.tween_property($Sprite2D2, "self_modulate", new_color, randf_range(0,1))

