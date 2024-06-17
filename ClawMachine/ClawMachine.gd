extends Node2D

class_name ClawMachine

signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal motion_stopped

# Resource Paths
@onready var prize_path = "res://ClawMachine/Prizes%s/"
var claw_path = "res://ClawMachine/Claw%s.tscn"
var cable_texture = load("res://ClawMachine/resources/cable.tres")
var prize_texture_path = "res://ClawMachine/resources/%s.tres"
var prize_texture_1_path = "res://ClawMachine/resources/%s_1.tres"
var prize_texture_2_path = "res://ClawMachine/resources/%s_2.tres"
var prize_script = load("res://ClawMachine/resources/prize.gd")

# Shapes
@onready var height = 180.0
@onready var width = 320.0
var dropbox_shape
var expanded_toybox
var toybox
var top_size
@onready var claw_drop_rect = Rect2(0,0,50,height)


# Motion variables
@export var arm_acceleration = 10.0
@export var arm_negative_accel = 3
@export var arm_speed = 0.0
@export var max_arm_speed = 60.0
@export var lower_claw_speed = 2.0
@export var claw_bounce_speed = 5.0
@export var default_spring_stiffness = 2.2

# Nodes
@onready var arm = $Arm
var claw
var claw_cable
var arm_motion = 0# denotes whether arm is moving left or right
var is_lever_held=false
var prize_dropping = []

# Saved / Loaded variables + child specific

var machine_idx:String
var prize_type:String
var prize_taken_array:String
var prize_exceptions 
var game_states = Globals.game_states
var player = Globals.player

func _ready():
	if !$Dropbox.body_entered.is_connected(_on_dropbox_body_entered):
		$Dropbox.body_entered.connect(_on_dropbox_body_entered)
	
	$DampedSpringJoint2D.bias = 1.0
	set_shape_variables()
	set_claw()
	set_prizes()




func _physics_process(delta):
	var destination = arm.position.x + (arm_motion * arm_speed * delta)

	
	if !(destination < (top_size.x/2)  || destination > (width-(top_size.x/2))):
		arm.position.x = destination
	
	if (is_lever_held and (arm_speed < max_arm_speed)):
		arm_speed += (arm_acceleration*delta)
		
	elif (!is_lever_held and arm_speed > 0):
		arm_speed -= (arm_acceleration*delta*arm_negative_accel)
		
	elif (!is_lever_held and arm_speed <= 0):
		emit_signal("motion_stopped")
		arm_speed = 0
		
	# Adjust Spring stiffness and damp // show cable growth/shrinkage
	if claw.drop:
		if $DampedSpringJoint2D.stiffness > 0:
			$DampedSpringJoint2D.stiffness -= (lower_claw_speed*delta)
	
			
	if claw.rise:
		if $DampedSpringJoint2D.stiffness < default_spring_stiffness:
			$DampedSpringJoint2D.stiffness += (2*lower_claw_speed*delta)
		if claw.linear_damp < 1.2:
			claw.linear_damp += (delta*(height-claw.position.y))

	# Adjust linear damp
	else:
		claw.linear_damp = .2 + ((max_arm_speed-arm_speed)/max_arm_speed) 
		
	if claw.position.y >= height || claw.position.y <= -25:
		claw.linear_velocity.y *= (claw_bounce_speed*delta)


	if claw.position.x < 0 || claw.position.x > width:
		claw.linear_velocity.x *= (claw_bounce_speed*delta)
		
	# Adjust claw line 
	claw_cable.set_point_position(0, Vector2(claw.position.x, arm.position.y))
	claw_cable.set_point_position(1, (Vector2(claw.position.x, claw.position.y-5)))
	
	# If prize is dropping, score_prize once they exit frame
	if !prize_dropping.is_empty():
		
		prize_dropping.erase(null)
		for prize in prize_dropping:
			if prize != null:
				if prize.position.y > (20+height):
					_on_prize_scored(prize)

	
func _input(event):
	if event.is_action_pressed("E"):
		if claw.drop:
			claw.close()
		else:
			is_lever_held = false
			await motion_stopped
			claw.open()	
	elif event.is_action_pressed("ui_left"):
		arm_motion = -1
		is_lever_held = true
	elif event.is_action_pressed("ui_right"):
		arm_motion = 1
		is_lever_held = true
	if (event.is_action_released("ui_left")||event.is_action_released("ui_right")):
		is_lever_held = false

		
func set_claw():
	
	claw = load(claw_path % [machine_idx]).instantiate()
	claw.claw_y_position = 20
	claw.grabber_offset = [32, 30, 35, 35][int(machine_idx)]
	
	
	claw_cable = Line2D.new()
	claw_cable.width =4 
	claw_cable.texture = cable_texture
	claw_cable.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	claw_cable.texture_mode = Line2D.LINE_TEXTURE_TILE
	claw_cable.points = PackedVector2Array([Vector2(claw.position.x, 0), Vector2(claw.position.x, claw.position.y-5)])
	add_child(claw_cable)
	add_child(claw)
	
	$DampedSpringJoint2D.set_node_b(claw.get_path())
	if !claw.drop_or_stay.is_connected(_on_claw_drop_or_stay):
		claw.drop_or_stay.connect(_on_claw_drop_or_stay)
	if !claw.stop_spring_adjustment.is_connected(_on_claw_stop_spring):
		claw.stop_spring_adjustment.connect(_on_claw_stop_spring)
	if !claw.rise_begin.is_connected(_on_claw_rise_begin):
		claw.rise_begin.connect(_on_claw_rise_begin)

func set_prizes():
	return
	

func _on_claw_drop_or_stay():
	
	claw.drop = !claw_drop_rect.has_point(claw.position)
	if claw.drop:
		claw_cable.texture.speed_scale = -1
		claw_cable.texture.pause = false
	else:
		claw.close()

func _on_claw_stop_spring():
	claw_cable.texture.pause = true
	$DampedSpringJoint2D.stiffness = default_spring_stiffness
	
func _on_claw_rise_begin():
	claw_cable.texture.speed_scale = 1
	claw_cable.texture.pause = false



	
func set_shape_variables():
	
	var margin = 10
	dropbox_shape = $Dropbox/CollisionShape2D.get_shape()
	# For telling which prizes are in or out of toybox
	expanded_toybox = Rect2(Vector2(dropbox_shape.size.x, height-dropbox_shape.size.y), Vector2((width+(margin/2))-dropbox_shape.size.x, dropbox_shape.size.y+margin))
	# Spawn toybox: add margin
	toybox = Rect2(Vector2((dropbox_shape.size.x+margin), height-dropbox_shape.size.y),
			Vector2(width-(dropbox_shape.size.x+(2*margin)), dropbox_shape.size.y))		
	top_size = $Arm/Top/CollisionShape2D.get_shape().size
		

func set_prize_physical_parameters(prize):
	prize.set_meta("strength", [1.0, .2, 1.0, .5][int(machine_idx)])
	prize.set_meta("scored", false)
	prize.set_collision_layer_value(2, true)
	prize.set_collision_layer_value(1, false)
	prize.set_collision_mask_value(1, false)
	prize.set_collision_mask_value(2, true)	
	prize.add_to_group("prizes")
	for node in prize.get_children():
		if "scale" in node:
			node.scale = Vector2(3, 3)
						
	prize.set_script(prize_script)
	prize.mass = (prize.get_meta("strength")*.01)
	prize.position = Vector2(randi_range(toybox.position.x, toybox.end.x), randi_range(toybox.position.y, toybox.end.y))

	
	$Frame.add_child(prize)

func load_prize_texture(prize, prize_name):
	var prize_texture = load(prize_texture_path % [prize_name.replace(" ", "_")])
	var sprite = Sprite2D.new()
	sprite.texture = prize_texture
	
	if !FileAccess.file_exists(prize_texture_1_path % [prize_name.replace(" ", "_")]):
		prize.add_sprite(sprite)
		return

	var top_prize_texture = load(prize_texture_1_path % [prize_name.replace(" ", "_")])
	var top_sprite = Sprite2D.new()
	top_sprite.texture = top_prize_texture
	
	if !FileAccess.file_exists(prize_texture_2_path % [prize_name.replace(" ", "_")]):
		sprite.add_child(top_sprite)
		prize.add_sprite(sprite)
		return
		
	var tippy_top_prize_texture = load(prize_texture_2_path % [prize_name.replace(" ", "_")])
	var tippy_top_sprite = Sprite2D.new()
	tippy_top_sprite.texture = tippy_top_prize_texture
	
	top_sprite.add_child(tippy_top_sprite)
	sprite.add_child(top_sprite)
	prize.add_sprite(sprite)

# Prize Won
func _on_prize_scored(prize):
	if prize.get_meta("scored"):
		return
	# Set Treasure Chest (Unique prize) as won
	if prize.is_in_group("treasure_chest"):
		game_states.claw_machine["treasure_taken"] = true
	# In finite claws, (ie: 0, 2, 3), add these prizes to the exceptions 
	if prize_taken_array in game_states.claw_machine.keys():
		game_states.claw_machine[prize_taken_array].append(prize.prize_name)
	
	match prize.inventory_location:
		"Front Pocket":
			player.front_pocket.append(prize.get_prize_data())
		
		"Lunchbox":	
			player.lunchbox.append(prize.get_prize_data())
		
		"Big Pocket":
			player.big_pocket.append(prize.get_prize_data())
		
		"FigurineSets":
			player.figurines.append(prize.get_prize_data())
	
	# Prevents detecting doubles
	prize.set_meta("scored", true)
	prize.call_deferred("queue_free")


func _on_dropbox_body_entered(body):
	if body.is_in_group("prizes"):
		prize_dropping.append(body)


func _on_draw():
	if toybox != null:
		draw_rect(toybox, Color.BLACK, false, 1)
	if expanded_toybox != null:
		draw_rect(expanded_toybox, Color.RED, false, 2)

func dialog_finished():
	return
