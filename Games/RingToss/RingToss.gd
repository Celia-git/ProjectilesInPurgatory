extends Node2D


@onready var height = 180
@onready var width = 320

signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_value
signal set_max_value


var loaded_ring = preload("res://Games/RingToss/Ring.tscn")

var score = 0

var ring
var ring_textures
var ring_spriteframes = SpriteFrames.new()
var game_states

func _ready():
	if !$BottleStand.enter_layer.is_connected(_ring_enter_active_layer):
		$BottleStand.enter_layer.connect(_ring_enter_active_layer)
	if !$BottleStand.exit_layer.is_connected(_ring_exit_active_layer):
		$BottleStand.exit_layer.connect(_ring_exit_active_layer)
	create_images()


func _physics_process(delta):
	
	if !ring.release:
		ring.winding_x = Input.is_action_pressed("ui_right")
		ring.winding_y = Input.is_action_pressed("ui_up")
	
	# Add Impulse
	if ring.winding_x:
		ring.unwind_x = false
		if (ring.impulse.x < ring.max_impulse.x) :
			ring.impulse.x += (ring.impulse_step.x*delta)
	
	if ring.winding_y:
		ring.unwind_y = false
		if (ring.impulse.y > ring.max_impulse.y) :
			ring.impulse.y -= (ring.impulse_step.y*delta)
			
	# Remove Impulse
	if ring.unwind_x:
		if ring.impulse.x > 0:
			ring.impulse.x -= ring.impulse_step.x*delta
	
	if ring.unwind_y:
		if ring.impulse.y < 0:
			ring.impulse.y += ring.impulse_step.y*delta

	# Launch ring if at max impulse
	if ((ring.impulse.x >= ring.max_impulse.x) && (ring.impulse.y <= ring.max_impulse.y)): 
		ring.launch()

	var x_released = Input.is_action_just_released("ui_right")
	var y_released = Input.is_action_just_released("ui_up")
	
	if !ring.release:
		# Upon x or y release, lose impulse in either of those
		if x_released:
			ring.unwind_x = true
			ring.winding_x = false
		if y_released:
			ring.unwind_y = true
			ring.winding_y = false
		# Upon both key release
		if ring.unwind_x && ring.unwind_y:
			if !ring.launch():
				# If ring fails to launch because it lacks initial impulse
				progress_setup()

	# Restart if ring is outside of bounds
	if (ring.position.x>1.5*width)||(ring.position.y<(-1.5*height)):
		await get_tree().create_timer(1).timeout
		_restart_round()

	# Update progress bars
	emit_signal("set_value", "horizontal progress", ring.impulse.x)
	emit_signal("set_value", "vertical progress", -ring.impulse.y)
	
func new_round():
	# Add Ring
	ring = loaded_ring.instantiate()
	ring.connect("round_over", _restart_round)
	ring.connect("score", _set_score)
	ring.set_texture(ring_textures[randi_range(0, ring_textures.size()-1)])
	ring.enter_layer.connect(_ring_enter_active_layer)
	ring.exit_layer.connect(_ring_exit_active_layer)
	ring.add_to_group("rings")
	ring.add_animation(ring_spriteframes)
	progress_setup()
	add_child(ring)
	ring.position = Vector2(24, 24)


func progress_setup():
	ring.impulse = Vector2(0,0)
	emit_signal("set_max_value", "horizontal progress", 100)
	emit_signal("set_max_value", "vertical progress", 100)
	emit_signal("set_value", "horizontal progress", 0)
	emit_signal("set_value", "vertical progress", 0)

func _set_score(arg):
	score += arg
	emit_signal("set_value", "score", score)
	await get_tree().create_timer(1).timeout
	_restart_round()
	
# Restart Round
func _restart_round():
	if ring != null:
		ring.queue_free()
	new_round()


func dialog_finished():
	pass

func create_images():
	var image_filename = "Ringtoss.png"
	var textures = Globals.texture_script.new()
	var item_data = textures.get_image_data(image_filename)
	for item in item_data.keys():
		var item_atlases = textures.get_atlas(image_filename,item, item_data[item])
		
		match item:
			"Ring":
				ring_textures = item_atlases
			
			"RingShine":
				var frame_amount = item_data[item][2]
				ring_spriteframes.add_animation("shine")
				for f in range(frame_amount):
					ring_spriteframes.add_frame("shine", item_atlases[f])
				
			"Bottle":
				$BottleStand.set_bottle_textures(item_atlases)
			
# Enable collisions so that ring interacts with bottles on layer 2
func _ring_enter_active_layer():
	if ring != null:
		ring.set_collision_mask_value(2, true)
		ring.get_node("Hole").set_collision_mask_value(2, true)

func _ring_exit_active_layer():
	if ring != null:
		ring.set_collision_mask_value(2, false)
		ring.get_node("Hole").set_collision_mask_value(2, false)

# Leaving Ringtoss, free ring
func _on_tree_exiting():
	if ring !=null:
		ring.call_deferred("queue_free")

func transfer_carry_overs():
	pass
