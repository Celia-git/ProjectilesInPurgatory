extends RigidBody2D

signal round_over
signal score
signal enter_layer
signal exit_layer

var score_color = Color.WHITE
var size = Vector2(24,4)	
var unwind_x = false
var unwind_y = false
var winding_x = false
var winding_y = false
var release = false
var min_impulse = Vector2(25, -25)
var max_impulse = Vector2(100, -120)
var impulse = Vector2(0, 0)
var impulse_step = Vector2(60, 80)
var hooked = false


# Scale RigidBody Children
func _ready():
	visible = false
	for child in get_children():		
		if "scale" in child:
			child.set_scale(Vector2(3,3))
	visible = true

		
func launch():
	# Launch ring
	if ((impulse.x > min_impulse.x) && (impulse.y < min_impulse.y)): 
		apply_central_impulse(10*impulse)
		
		release = true
		winding_x = false
		winding_y = false
		unwind_x = false
		unwind_y = false
		return true
	else:
		return false
	
	
func set_texture(text):
	$Sprite2D.texture = text


# Ring Hit Wall: Round over
func _on_body_entered(body):
	if ((body.name == "Walls"||body.name == "Ground"\
	||body.name=="Ceiling"||body.is_in_group("Stand")) && release && !hooked):
		await get_tree().create_timer(.7).timeout
		if release && !hooked:
			emit_signal("round_over")


# Hole Area entered/Exited

func _on_area_entered(area):
	if area.is_in_group("Bottle"):
		hooked = true
		# Get target bottle position
		var target = area.get_parent().get_parent().get_target_position(area.get_meta("index"))
		# Adjust target position for ring height
		target.y -= 2
		await get_tree().create_timer(.2).timeout
		if hooked:
			if $Hole.area_exited.is_connected(_on_area_exited):
				$Hole.area_exited.disconnect(_on_area_exited)
			_saddle_on(target, area.get_meta("index"), .3)
		

func _on_area_exited(area):
	if area.is_in_group("Bottle"):
		hooked = false
		emit_signal("exit_layer")

	
# Settle on to target
func _saddle_on(target, index, time):		
	var tween = create_tween()
	tween.tween_property(self, "global_position", target, time).set_trans(Tween.TRANS_BOUNCE)
	await get_tree().create_timer(time*2).timeout
	$Shine.play("shine")
	await get_tree().create_timer(time*2).timeout
	emit_signal("score", 1+index)
	$Hole.set_deferred("monitoring",false)


func _change_color(color, time):
	var tween = create_tween()
	tween.tween_property($Sprite2D, "modulate", color, time)

func add_animation(frames):
	$Shine.frames = frames
	
