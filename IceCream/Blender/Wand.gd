extends Node2D

var max_velocity = 8
var acceleration = .1
var animation_name = "rotation"
var rotations_achieved = 0
var rotations_required = 1
var late_step = 1.5 # 1.2: difficult, 2: easy
var value_step = 25
var blendable = false
var timer_min = 1

# Image Variables
var prog1_texture = load("res://IceCream/Resources/WandProgressOver.tres")
var prog2_texture = load("res://IceCream/Resources/WandProgressUnder.tres")
var prog_late_texture = load("res://IceCream/Resources/WandProgressLate.tres")

@onready var animator = $Head/AnimationPlayer
@onready var progress = $Head/ProgressBar

signal add_points
signal add_late_points
signal round_ended




#Set new amt of rotations to hit
func new_checkpoint():
	
	# Reset animation
	
	$LateTimer.stop()
	progress.texture_under = prog2_texture
	progress.texture_progress = prog1_texture
	animator.speed_scale = 0
	var this_anim = animator.get_animation(animation_name)
	
	# Set new progress values
	randomize()
	rotations_required = randi_range(1, 5)
	rotations_achieved = 0
	progress.value = 0
	progress.max_value = rotations_required*value_step
	this_anim.track_set_key_value(1,0,0)
	this_anim.track_set_key_value(1,1,value_step)
	this_anim.track_set_key_value(2,0,value_step)
	animator.seek(0)
	animator.play(animation_name)
	progress.value_changed.connect(_progress_bar_value_changed)
	
	randomize()
	$Timer.set_wait_time(randi_range(timer_min, timer_min+rotations_required))
	
	blendable = true
	$Timer.stop()
	
# 1 Rotation complete
func _rotation_complete():
	rotations_achieved += 1
	var this_anim = animator.get_animation(animation_name)
	this_anim.track_set_key_value(1, 0, (rotations_achieved*value_step))
	this_anim.track_set_key_value(1, 1, ((rotations_achieved+1)*value_step))
	animator.play(animation_name)


# Value Changed: If progress bar filled
func _progress_bar_value_changed(value):
	if value == progress.max_value:
		
		# If this is end of "late" progress
		if progress.texture_progress == prog_late_texture:
			disconnect_progress_signal()
			blendable = false
			$Timer.stop()
			$LateTimer.start()
		# If this is value_step progress,begin late cycle
		else:
			emit_signal("add_points", 1)
			progress.texture_progress = prog_late_texture
			progress.max_value = late_step * value
			emit_signal("round_ended")


# Disconnect progress bar "value_changed" from wand's "_progress_bar_value_changed"
func disconnect_progress_signal():
	if progress.value_changed.is_connected(_progress_bar_value_changed):
		progress.value_changed.disconnect(_progress_bar_value_changed)

func stop_timer():
	$Timer.stop()
	
func start_timer():
	$Timer.start()

func _on_timer_timeout():
	emit_signal("round_ended")


func _on_late_timer_timeout():
	emit_signal("add_late_points", $LateTimer.wait_time)
