extends RigidBody2D

signal detect_target
signal hit_wall
signal out_of_bounds

var MAX_DEPTH = 800
var MAX_HEIGHT = 0
var HIT_DEPTH = [600, 750]
var MIN_SCALE = Vector2(1, 1)
var GROUND=0

var is_dropping = false
var time_interval = 0
var depth = 0
var depth_velocity = 0
var t = 0

# Scale RigidBody Children
func _ready():
	for child in get_children():	
		if "scale" in child:
			child.set_scale(Vector2(3,3))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	# Track cannonball depth
	depth += depth_velocity*t 
	t+=delta
	
	# Detect Out of Bounds
	if is_dropping and (position.y > GROUND) || (position.y < MAX_HEIGHT):
		emit_signal("out_of_bounds")
	
	# Detect target hit
	if (depth >= HIT_DEPTH[0]&&depth <= HIT_DEPTH[1]):
		emit_signal("detect_target")
	elif (depth >= MAX_DEPTH):
		emit_signal("hit_wall")

		

func set_img_texture(ball_texture):
	$Sprite2D.texture = ball_texture


func start_animation():
	var animation = $AnimationPlayer.get_animation("Scaler")
	animation.length = time_interval
	animation.track_insert_key(0, 0, Vector2(3,3))
	animation.track_insert_key(0, time_interval, MIN_SCALE)
	$AnimationPlayer.play("Scaler")



func smash():
	freeze = true
	randomize()
	var tween = create_tween()
	tween.tween_property(self, "position", Vector2(randi_range(-3, 3), 10), .1).as_relative()
	tween.parallel().tween_property($Sprite2D, "scale", MIN_SCALE*1.25, .1)
	await get_tree().create_timer(.1).timeout
	freeze = false
	$CollisionShape2D.disabled=true
	is_dropping=true
	
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Scaler":
		$Sprite2D.scale=MIN_SCALE
	elif anim_name == "Drop":
		emit_signal("out_of_bounds")
