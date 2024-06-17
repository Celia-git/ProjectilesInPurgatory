extends Node2D


signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_value
signal set_max_value
signal cannon_launch_over
signal shift_cannon_up
signal shift_cannon_down

# cannon related variables
const BURN_TIME = 1.6
const CANNON_POSITION = Vector2(800, 700)
	
var score = 0
var rects
var hit_pos

@onready var height = 180
@onready var width = 320

var cannon_scene = load("res://Games/Ships/Cannon.tscn")
var cannonball_scene = load("res://Games/Ships/Cannonball.tscn")
var angle_visualizer = Line2D.new()
@onready var shelf_shape = $Shelves/Shelf1/CollisionShape2D.get_shape()
var ship_scene = "res://Games/Ships/Ship.tscn"
@onready var shelves = $Shelves.get_children()

var target_shelf = 1
var max_t_shelf = 1
var min_t_shelf = 1
var total_ship_amount = 16
var time_scale = 40
var cannonball
var cannonball_img
var ship_images = []
var target_hit = false

var game_states

# Called when the node enters the scene tree for the first time.
func _ready():
	
	create_images()
	load_ships()
	

func transfer_carry_overs():
	var cannon = cannon_scene.instantiate()
	add_child(cannon)
	cannon.add_to_group("Cannon")
	cannon.BURN_TIME = BURN_TIME
	emit_signal("set_max_value", "horizontal progress", 100*BURN_TIME)
	emit_signal("carry_over", cannon, Vector2(800,750))

	

func launch_cannonball(cannonball_position):
	cannonball = cannonball_scene.instantiate()
	cannonball.set_img_texture(cannonball_img)
	cannonball.visible = false
	add_child(cannonball)
	cannonball.out_of_bounds.connect(_out_of_bounds)
	cannonball.global_position = cannonball_position
	
	var tween = create_tween()
	var time = float(1/float(1+target_shelf))/cannonball.SPEED	# The higher the shelf, the more time it takes
	var target_pos = Vector2(cannonball.position.x, shelves[target_shelf].position.y)
	tween.tween_property(cannonball, "position", target_pos, time).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(cannonball.get_node("Sprite2D"), "scale", cannonball.MIN_SCALE, time).set_trans(Tween.TRANS_QUAD)
	await get_tree().create_timer(time).timeout
	hit_pos = target_pos
	rects = shelves[target_shelf].get_ship_rects()
	cannonball.freeze = true
	queue_redraw()
	for rect in rects:
		if rect.has_point(hit_pos):
			await _hit_target(shelves[target_shelf].get_ship(rects.find(rect)))
	_hit_wall()
	

func load_ships():
	var new_shelves = []
	var shelf_size = abs(shelf_shape.a - shelf_shape.b).x
	var ship_amt = total_ship_amount/shelves.size()
	var interval = float(shelf_size/ship_amt)
	for shelf in shelves:
		# Get Index (Higher->0, Lower->2)		
		var shelf_idx = int(String(shelf.name).right(1))
		# Set First Motion direction: Oddly numbered shelves:: ships start going left
		if shelf_idx%2!=0:
			shelf.first_direction = "left"
		else:
			shelf.first_direction = "right"
			
		# Set speed: The highter the shelf, the lower the speed of the ships
		shelf.speed = time_scale / (1+shelf_idx)
		shelf._reset_time()
			
		for i in ship_amt:
			var ship = load(ship_scene).instantiate()
			# Set initial position: Oddly numbered shelves:: ships start at right of shelf
			var x_pos = (i+ shelf_idx%2)*interval
			var sprite_frames = ship_images[randi_range(0, ship_images.size()-1)].duplicate(true)
			ship.position = Vector2(x_pos, 0)
			ship.set_meta("shelf", shelf_idx)
			ship.set_meta("index", i)
			ship.set_meta("down", false)
			ship.set_meta("left_bound", i*interval)
			ship.set_meta("right_bound", (i+1)*interval)
			ship.get_node("AnimatedSprite2D").sprite_frames = sprite_frames
			ship.get_node("AnimatedSprite2D").speed_scale = 5
			ship.get_node("AnimatedSprite2D").animation = "knockdown"
			ship.get_node("AnimatedSprite2D").frame = 0
			ship.get_node("AnimatedSprite2D").animation_finished.connect(_on_ship_knockdown_animation_finished.bind(ship))
			ship.get_node("Impact").animation_finished.connect(_on_ship_impact_animation_finished.bind(ship))
			ship.add_to_group("Targets")
			shelf.add_child(ship)
		if shelf_idx < min_t_shelf:
			min_t_shelf = shelf_idx
		if shelf_idx > max_t_shelf:
			max_t_shelf = shelf_idx

func new_round(): 
	target_hit = false
	emit_signal("set_value", "horizontal progress", BURN_TIME)

# Aim cannon up or down
func shift_cannon(direction):
	match direction:
		"down":
			target_shelf -= 1
			if target_shelf >= min_t_shelf:
				emit_signal("shift_cannon_up")
			else:
				target_shelf +=1
				
		"up":
			target_shelf += 1
			if target_shelf <= max_t_shelf:
				emit_signal("shift_cannon_down")
			else:
				target_shelf -= 1

func _hit_wall():
	if !target_hit:
		var tween = create_tween()
		tween.tween_property(cannonball, "position", Vector2(randi_range(-2, 3), -6), .03).as_relative().set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(cannonball.get_node("Sprite2D"), "scale", cannonball.MIN_SCALE * 1.25, .03).set_ease(Tween.EASE_OUT)
		
		cannonball.freeze = false
		cannonball.drop()
		
func _hit_target(target):
	target.get_node("Impact").visible=true
	randomize()
	target.get_node("Impact").play(["impact1", "impact2"][randi_range(0,1)])
	target.get_node("AnimatedSprite2D").play("knockdown")
	target.set_meta("down", true)
	score += (3-target.get_meta("shelf"))
	emit_signal("set_value", "score", score)
	cannonball.freeze = false
	cannonball.drop()
	target_hit = true
	return
	
func _out_of_bounds():
	cannonball.queue_free()
	emit_signal("cannon_launch_over")
	new_round()
	

func dialog_finished():
	pass

func _mouse_entered():
	emit_signal("mouse_entered")
	
func _mouse_exited():
	emit_signal("mouse_exited")

func create_images():
	
	var image_filename = "Ships.png"
	var textures = Globals.texture_script.new()
	var item_data = textures.get_image_data(image_filename)
	for item in item_data.keys():
		var item_atlases = textures.get_atlas(image_filename,item, item_data[item])
		
		match item:
			"Ship":
				var sprite_amount = item_data[item][3]
				var frame_amount = item_data[item][2]
				for s in range(sprite_amount): # Iterate amount of sprites
					var frames = SpriteFrames.new()
					frames.add_animation("knockdown")
					frames.set_animation_loop("knockdown", false)
					for f in range(frame_amount): #Iterate amount of frames
						var current_index = (s*frame_amount+f)
						frames.add_frame("knockdown", item_atlases[current_index])
					ship_images.append(frames)
				
			"ShipsCannonball":
				cannonball_img = item_atlases[0]
			
		
						

func _on_ship_knockdown_animation_finished(ship):
	await get_tree().create_timer(1).timeout
	ship.get_node("AnimatedSprite2D").frame = 0
	ship.set_meta("down", false)
	
func _on_ship_impact_animation_finished(ship):
	ship.get_node("Impact").visible = false




func _on_draw():
	if rects:
		for rect in rects:
			draw_rect(rect, Color.BLUE, false, 1)
	if cannonball != null and hit_pos:
		draw_circle(hit_pos, cannonball.get_node("CollisionShape2D").shape.radius, Color.PURPLE)






