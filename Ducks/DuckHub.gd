extends Node2D

signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited


@onready var height = 180
@onready var width = 320

@onready var data_script = load("res://Ducks/DuckScript.gd")
@onready var duckscene = load("res://Ducks/Duck.tscn")
@onready var ripples_frames = load("res://Ducks/Resources/Ripples.tres")
@onready var pool = $Pool
@onready var poolshape = $Pool/CollisionShape2D.get_shape()
@onready var whirlpool = $WhirlPool
@onready var whirlpoolshape = $WhirlPool/CollisionShape2D.get_shape()
@onready var poolwalls = $PoolWalls
@onready var CENTER = 5*Vector2(width/2, (height/2)+7)
@onready var RADIUS = (float(height/2)-20)
@onready var duck_position = [Vector2(36, 100), Vector2(width-36, 100)]
var duck_textures = {}
var t = 0
var duck_amount = 0
var combos = []
var lines = []
var ducks = []
var hands = {0:null, 1:null}
var matches = []
var level = 1

var game_states


# Called when the node enters the scene tree for the first time.
func _ready():
	
	create_images("Ducks.png")
	setup_pool()
	create_lines(level)
	setup_panel()
	
func _physics_process(delta):
	t += delta
	for l in range(lines.size()):
		var theta = lines[l].get_meta("Theta")
		var new_theta = theta + (t*lines[l].get_meta("Speed"))
		lines[l].set_rotation(new_theta)
		var duck = pool.get_node_or_null("Duck"+str(l))
		if duck:
			duck.radius = lines[l].get_meta("Length")*Vector2(cos(new_theta), sin(new_theta))
			

func check_win_condition():
	if hands[0]&&hands[1]:
		if  hands[0].get_meta("ColorShape")== hands[1].get_meta("ColorShape"):
			matches.append([hands[0], hands[1]])
			hands[0]=null
			hands[1]=null
			$MatchAlert/HBoxContainer/TextureRect.texture = $Duck0/Icon.texture
			$MatchAlert.popup_centered()
			await get_tree().create_timer(1).timeout
			$Duck0.visible=false
			$Duck1.visible=false
			$MatchAlert.visible=false
		if matches.size()==duck_amount/2:
			game_won()
		
func game_won():
	set_physics_process(false)
	for line in lines:
		line.queue_free()
	for duck in ducks:
		duck.queue_free()
	lines = []
	hands = {0:null, 1:null}
	matches = []
	t= 0
	$WinAlert.popup_centered()
	await $WinAlert/Color/Button.pressed
	$WinAlert.visible=false
	create_lines(level)
	set_physics_process(true)
		
func create_lines(level):
	randomize()
	duck_amount = data_script.get_amount(level)
	combos = data_script.get_combos(level)
	var m = 0
	for i in range(duck_amount):
		var line = Line2D.new()
		line.width = 1
		var theta = randf_range(0, 2*PI)
		var line_len = randi_range((RADIUS/5),(RADIUS-10))
		var line_pos = line_len*Vector2(cos(theta), sin(theta)) 
		line.add_point(Vector2(0,0), 0)
		line.add_point(line_pos, 1)
		line.set_meta("Index", i)
		line.set_meta("Theta", theta)
		line.set_meta("Length", line_len)
		line.set_meta("Speed", randf_range(0.2, .5))
		line.visible=false
		lines.append(line)
		pool.add_child(create_duck(i, m, line_pos, line_len*Vector2(cos(theta), sin(theta))))
		pool.add_child(line)
		if i%2!=0:
			m+=1

func create_duck(i, m, duck_pos, radius_vector):
	var duck = duckscene.instantiate()
	duck.global_position = duck_pos
	duck.add_to_group("Ducks")
	duck.z_index = 2
	duck.set_meta("Index", i)
	duck.set_meta("ColorShape", combos[m])
	duck.set_vars(radius_vector)
	duck.mouse_entered.connect(_on_mouse_entered)
	duck.mouse_exited.connect(_on_mouse_exited)
	duck.selected.connect(_on_duck_selected)
	duck.name = "Duck"+str(i)
	ducks.append(duck)
	return duck


# On setup, reference LoadDuckTextures script to get level data
func setup_pool():
	var scale_ratio = RADIUS/poolshape.radius
	pool.global_position = CENTER
	poolwalls.global_position = CENTER
	poolshape.radius = RADIUS
	whirlpool.global_position = CENTER
	whirlpoolshape.radius = RADIUS/4
	poolwalls.set_scale(Vector2(scale_ratio,scale_ratio))


func setup_panel():
	$Duck0/CollisionShape2D.shape.size = Vector2(32, 32)
	$Duck1/CollisionShape2D.shape.size = Vector2(32, 32)
	$Duck0.position = duck_position[0]
	$Duck1.position = duck_position[1]
	$Duck0/Background.texture = duck_textures["Bottom Yellow Duck"]
	$Duck1/Background.texture = duck_textures["Bottom Blue Duck"]
	$Duck0.visible = false
	$Duck1.visible = false
	
func _on_duck_selected(duck):
	
	duck.is_selected=true
	duck.set_meta("LastPos", duck.global_position)
	var idx = duck.get_meta("Index")%2
	
	# Remove current duck from this hand
	if hands[idx] != null:
		_on_free_pressed(idx)
	
	# Show ripples
	var ripple = AnimatedSprite2D.new()
	ripple.animation_finished.connect(_ripple_animation_finished.bind(ripple))
	ripple.sprite_frames = ripples_frames
	ripple.offset = Vector2(1,3)
	pool.add_child(ripple)
	ripple.z_index = 1
	ripple.position = duck.position
	ripple.play("Ripple")
	
	# Animate duck leaving pool
	var tween = create_tween()
	tween.tween_property(duck, "global_position", to_global(duck_position[idx]), .3).set_trans(tween.TRANS_SINE)
	await get_tree().create_timer(.3).timeout
	pool.remove_child(duck)
		
	# Add New duck to this hand
	hands[idx] = duck
	var panel = get_node("Duck"+str(idx%2))
	panel.get_node("Icon").texture = data_script.get_duck_shape(duck.get_meta("ColorShape"))
	panel.visible=true
	check_win_condition()

# Ripple animation doesn't play when ducks get back in pool
# Free ducks back to pool
func _on_free_pressed(idx):
	
	pool.add_child(hands[idx])
	var tween = create_tween()
#	var ripple = AnimatedSprite2D.new()
	var panel = get_node("Duck"+str(idx%2))
#
#	ripple.offset = Vector2(1, 3)
#	ripple.animation_finished.connect(_ripple_animation_finished.bind(ripple))
#	ripple.sprite_frames = ripples_frames
#	ripple.z_index = 1
#	ripple.global_position = hands[idx].get_meta("LastPos")

	panel.visible=false
	tween.tween_property(hands[idx], "global_position", hands[idx].get_meta("LastPos"), .3).from(to_global(duck_position[idx])).set_trans(tween.TRANS_SINE)
#
#	#await get_tree().create_timer(.3).timeout
#
	hands[idx].is_selected=false
	hands[idx]=null	
	
#	pool.add_child(ripple)
#	ripple.play("Ripple")
	
	
func dialog_finished():
	pass


func create_images(image_filename):
	var textures = Globals.texture_script.new()
	var item_data = textures.get_image_data(image_filename)
	for item in item_data.keys():
		var item_atlas = (textures.get_atlas(image_filename,item, item_data[item])[0])
		duck_textures[item]=item_atlas

func _on_draw():
	draw_rect(Rect2(0, 0, 320, 180), Color.BLACK, false, 2)
	draw_circle(CENTER, RADIUS, Color.REBECCA_PURPLE)

func _on_mouse_entered():
	emit_signal("mouse_entered")
	
func _on_mouse_exited():
	emit_signal("mouse_exited")

func _ripple_animation_finished(ripple):
	ripple.call_deferred("queue_free")




func _on_free_input_event(viewport, event, shape_idx, index):
	if event.is_action_pressed("click"):
		_on_free_pressed(index)
