extends Node2D

signal carry_over

var image_filename = "Popper.png"
@onready var popcorn_scene = preload("res://Popper/Popcorn/Popcorn.tscn")
@onready var compartment = $Compartment
@onready var lid = $Compartment/Lid
@onready var popcorn_out_position = Rect2(Vector2(200, 368), 3*Vector2(38, 48)).get_center() 


var popcorn_textures = []
var popcorn_coated_textures = []
var popcorn_kernel_texture

var BATCH_SIZE = 200
var MAX_TIME = 12
var output = 0 # amount of popcorn poured out the chute

# Called when the node enters the scene tree for the first time.
func _ready():
	create_images()
	
	for child in lid.get_children():
		if "scale" in child:
			child.set_scale(Vector2(3, 3))
	$Scoopable/Area2.disabled=true
	add_kernels(BATCH_SIZE)
	$Timer.wait_time = MAX_TIME + (.5*MAX_TIME)
	$Timer.start()


func add_kernels(amount):
	for i in amount:
		var popcorn = popcorn_scene.instantiate()
		popcorn.MAX_TIME = MAX_TIME
		popcorn.kernel_texture = popcorn_kernel_texture
		popcorn.popped_texture = popcorn_textures[randi_range(0, popcorn_textures.size()-1)]
		popcorn.coated_texture = popcorn_coated_textures[randi_range(0, popcorn_textures.size()-1)]
		compartment.add_child(popcorn)
		popcorn.position.x += randi_range(-10, 10)
		
		
func _on_lid_body_entered(body):
	if body.name=="Frame":
		lid.queue_free()


func _on_chute_body_entered(body):
	if body.is_in_group("Popcorn"):
		output+=1
		emit_signal("carry_over", body, popcorn_out_position, true, 3)


func _on_scoopable_body_entered(body):
	if body.is_in_group("Popcorn"):
		body.z_index = 1
		body.set_collision_mask(2)
		body.set_collision_layer(2)

func create_images():
	
	var textures = Globals.texture_script.new()
	var item_data = textures.get_image_data(image_filename)
	for item in item_data.keys():
		var item_atlases = (textures.get_atlas(image_filename,item, item_data[item]))
		match item:
			"Lid":
				lid.get_node("Sprite2D").texture = item_atlases[0]
			"Scoop":
				$Scoop/Sprite2D.texture = item_atlases[0]
			"Popcorn":
				popcorn_textures = item_atlases
			"CoatedPopcorn":
				popcorn_coated_textures = item_atlases
			"Kernel":
				popcorn_kernel_texture = item_atlases[0]

# Enable Scoopable Top Area so overflow popcorn will be scoopable
	## Causes overflow popcorn to fall to the bottom
func _on_timer_timeout():
	$Scoopable/Area2.disabled=false
	
func shift_away():
	$Timer.paused=true
	for child in compartment.get_children():
		if child.is_in_group("Popcorn"):
			child.freeze = (true) 
			child.pause_timer(true)
			child.set_process(false)
		elif child.name=="Lid":
			child.freeze=true
	return 0

func shift_toward():
	for child in compartment.get_children():
		if child.is_in_group("Popcorn"):
			child.freeze = (false)
			child.pause_timer(false)
			child.set_process(true)
		elif child.name=="Lid":
			child.freeze=false
	$Timer.paused=false
	return 0
