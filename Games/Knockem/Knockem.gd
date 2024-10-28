extends Node2D

signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_value
signal set_max_value
signal cannon_launch_over

@onready var height = 180
@onready var width = 320

var cannon
var cannon_scene = load("res://Games/Knockem/Cannon.tscn")
var cannonball_scene = load("res://Games/Knockem/Cannonball.tscn")
var angle_visualizer = Line2D.new()

var ball_img
var theta = PI/4
var MIN_THETA = 0
var MAX_THETA = PI/2
var RADIAL_SPEED = PI/4
var cannonball
var score = 0
var detecting = false

var game_states

# Called when the node enters the scene tree for the first time.
func _ready():
	
	
	$Targets.HEIGHT=height
	$Targets.WIDTH=width
	create_images()
	add_angle_visualizer(Vector2(width/15, height-10))
	
func transfer_carry_overs():
	cannon = cannon_scene.instantiate()
	add_child(cannon)
	cannon.add_to_group("Cannon")
	emit_signal("carry_over", cannon, Vector2(800,750))

func new_round(): 
	$HitBox.monitorable = false
	$HitBox.position = Vector2(0,0)
	detecting = false
	progress_setup()
	_update_radial_progress()

func _physics_process(delta):
	
	# Radial motion
	if cannon != null:
		if Input.is_action_pressed("ui_up")&& theta>MIN_THETA:
			if int(theta*100)%6==0:
				cannon.set_frame("up")
			theta -= RADIAL_SPEED*delta
			_update_radial_progress()
		elif Input.is_action_pressed("ui_down")&& theta<MAX_THETA:
			if int(theta*100)%6==0:
				cannon.set_frame("down")
			theta += RADIAL_SPEED*delta
			_update_radial_progress()
		
	if cannon != null:
		if cannon.is_launched:
			emit_signal("set_value", "horizontal progress", 100*cannonball.depth)


func launch_cannonball(pos):
	cannonball = cannonball_scene.instantiate()
	cannonball.set_img_texture(ball_img)
	add_child(cannonball)
	cannonball.global_position = pos
	cannonball.detect_target.connect(_detect_target)
	cannonball.hit_wall.connect(_hit_wall)
	cannonball.out_of_bounds.connect(_out_of_bounds)
	emit_signal("set_max_value", "horizontal progress", 100*cannonball.MAX_DEPTH)
	cannonball.depth_velocity = cannon.get_depth_velocity(theta)
	cannonball.time_interval = 100/cannonball.depth_velocity
	cannonball.GROUND = height
	cannonball.MAX_HEIGHT = -height
	cannonball.apply_impulse(cannon.get_force(theta), Vector2(0, -1))
	cannonball.start_animation()
	
func _detect_target():
	
	if !detecting:
		$HitBox.position = cannonball.position
		$HitBox.monitorable = true
		var hit_pos = $Targets.hit_target($HitBox)
		if hit_pos:

			cannonball.smash()
			await get_tree().create_timer(1).timeout
			score += 1
			emit_signal("set_value", "score", score)
			emit_signal("set_value", "win")
			detecting= true

func _hit_wall():
	cannonball.smash()
	
func _out_of_bounds():
	emit_signal("cannon_launch_over")
	cannonball.queue_free()
	await get_tree().create_timer(1).timeout
	new_round()
	
func add_angle_visualizer(position_arg):
	angle_visualizer.width = 1
	angle_visualizer.add_point(Vector2(0,0), 0)
	angle_visualizer.add_point(Vector2(40,0), 1)

	add_child(angle_visualizer)
	angle_visualizer.position = position_arg
	$SideCannon.position = position_arg
	$SideCannon.offset = Vector2(30, 0)


	
		
func progress_setup():
	
	emit_signal("set_max_value", "vertical progress", 100*cannon.MAX_COMPRESSION)
	emit_signal("set_max_value", "radial progress", 100*MAX_THETA)
	emit_signal("set_value", "horizontal progress", 0)
	emit_signal("set_value", "vertical progress", 0)
	emit_signal("set_value", "radial progress", 0)

	


func _update_radial_progress():
	emit_signal("set_value", "radial progress", 100*theta)
	angle_visualizer.set_rotation(-theta)
	$SideCannon.rotation = (-theta)
	
func dialog_finished():
	pass
	

func create_images():
	var image_filename = "Knockem.png"
	var textures = Globals.texture_script.new()
	var item_data = textures.get_image_data(image_filename)
	for item in item_data.keys():
		var item_atlases = textures.get_atlas(image_filename,item, item_data[item])
		
		match item:
			"Targets":
				$Targets.create_targets(item_atlases, item_data)
				
			"KnockemCannonball":
				ball_img = item_atlases[0]
			
			"KnockemSideCannon":
				$SideCannon.set_texture(item_atlases[0])


