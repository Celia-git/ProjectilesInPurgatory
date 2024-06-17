extends InteriorScenes




@export var CAMERA_SPEED = 15

@onready var gumball_sprites = $"Gumball Machine/Animation"
@onready var gumball_sprite = $"Gumball Machine/Animation/Gumball0"
@onready var flap = $"Gumball Machine/Flap"
@onready var gumball_spawn_pos = flap.get_rect().get_center() + flap.global_position


var rainbow_color_ramp = load("res://UI/rainbow_color_ramp.tres")
var gumball_script = load("res://Gumball/Gumball.gd")
var open_flap_texture = load("res://Assets/gumball_machine_flap_open.png")
var colors = {"red":Color(), "orange":Color(), "yellow":Color(), "green":Color(), "blue":Color(), "purple":Color(), "pink":Color()}

# gumball object currently being processed 
var gumball = null
var sequence_begun = false


# Called when the node enters the scene tree for the first time.
func _ready():
	$Camera2D.offset.y = -175
	var color_values = rainbow_color_ramp.get_colors()
	var idx = 0
	for color in color_values:
		var key = colors.keys()[idx]
		colors[key] = color.lightened(.3)
		idx += 1
	



# Player uses switch
func _on_switch_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click") and !(sequence_begun || sound_effects.playing):
		sound_effects.stream = Globals.get_audio_stream("gumball_switch")
		sound_effects.play()
		await sound_effects.finished
		sound_effects.stream = Globals.get_audio_stream("gumball_drop")
		sound_effects.play()
		await sound_effects.finished
		sound_effects.stream = Globals.get_audio_stream("gumball_roll")
		sound_effects.play()
		start_gumball_roll()
		sequence_begun = true


# Start Gumball Rolling sequence		
func start_gumball_roll():

	$AnimationPlayer.play("shift_camera_down")
	
	gumball = get_random_gumball()
	gumball.add_new_item.connect(_add_new_inventory)
	gumball_sprites.modulate = gumball.color
	gumball_sprite.frame = 0
	gumball_sprite.play("roll_0")

	
# Return random color gumball
func get_random_gumball():
	var idx = randi_range(0, colors.size()-1)
	var key = colors.keys()[idx]
	return gumball_script.new(colors[key], key)



# Play gumball animation
func _on_gumball_animation_finished(next_anim_suffix):
	
			
	var new_anim = "roll_"+next_anim_suffix
	var next_node = gumball_sprites.get_node("Gumball" + next_anim_suffix)
	next_node.speed_scale = .7
	gumball_sprite.animation = ("default")
	gumball_sprite.frame = 0
	next_node.play(new_anim)
	gumball_sprite = next_node
	
# Gumball is finished with animation, open flap and spit out pixel gumball
func _on_gumball_sequence_finished():
	if sound_effects.playing:
		await sound_effects.finished
	
	for sound in ["roll_end", "latch_open", "popout", "latch_closed"]:
		sound_effects.stream = Globals.get_audio_stream("gumball_" + sound)
		sound_effects.play()
				
		
		match sound:

			"latch_open":
				flap.texture = open_flap_texture

			"popout":
				gumball.global_position = gumball_spawn_pos
				$PixelEnv.add_child(gumball)
				
			"latch_closed":
				flap.texture = null
		
		
		await sound_effects.finished
		
	gumball_sprite = gumball_sprites.get_node("Gumball0")
	sequence_begun = false


func _add_new_inventory(item):
	super._add_new_inventory(item)
	$AnimationPlayer.play("shift_camera_up")
	
func set_new_active_scene(idx):
	pass
