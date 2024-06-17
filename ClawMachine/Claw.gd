extends RigidBody2D

signal drop_or_stay
signal stop_spring_adjustment
signal rise_begin

var width = 320
var height = 180

@export var drop = false
@export var rise = false
@export var strength = 1.0
@export var animation_accel = 1.0

var grabber_offset:float=0.0
var cluster_strength = 0.0
var claw_y_position:int
var direction = 0
var max_x_speed=300
@export var max_rise_speed = 90
@export var rise_acceleration = 6
var current_rise_speed = 0
var speed_reduction = 0.0

# Scale RigidBody Children
func _ready():
	
	
	position.y = claw_y_position
	$grab.position.y += grabber_offset
	for child in get_children():
		if "scale" in child:
			child.set_scale(Vector2(3,3))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	
	if drop:
		drop = (position.y < height)
	
	if rise:
		if current_rise_speed < max_rise_speed:
			current_rise_speed += (delta*rise_acceleration)
		rise = position.y > claw_y_position
		move_and_collide(Vector2(0, -current_rise_speed*delta))
	
	if !(rise || drop):
		emit_signal("stop_spring_adjustment")
		
	if speed_reduction > 0:
		linear_velocity.y *= (speed_reduction / (speed_reduction +1)) 
	
	if $AnimationPlayer.current_animation == "close":
		adjust_closing_speed(delta)

func open():
	if !$AnimationPlayer.is_playing():
		$AnimationPlayer.speed_scale = 1
		$AnimationPlayer.play("open")

func close():
	
	if !$AnimationPlayer.is_playing():
		drop = false
		current_rise_speed = 0
		$AnimationPlayer.play_backwards("close")
		direction = 0

func _on_animation_player_animation_finished(anim_name):
	if anim_name=="open":
		emit_signal("drop_or_stay")
		
	elif anim_name=="close":
		drop=false
		rise = true
		emit_signal("rise_begin")
		current_rise_speed = 1


func adjust_closing_speed(delta):
	
	if (cluster_strength < strength) and ($AnimationPlayer.speed_scale < 1):
		$AnimationPlayer.speed_scale += (animation_accel*delta)

	elif (cluster_strength >= strength) and ($AnimationPlayer.speed_scale > 0):
		$AnimationPlayer.speed_scale -= (animation_accel*delta)	



func _on_grab_body_entered(body):
	if body.is_in_group("prizes") and body.has_meta("strength"):
		cluster_strength += body.get_meta("strength")
		speed_reduction += .1

func _on_grab_body_exited(body):
	if body.is_in_group("prizes") and body.has_meta("strength"):
		cluster_strength -= body.get_meta("strength")
		speed_reduction -= .1
