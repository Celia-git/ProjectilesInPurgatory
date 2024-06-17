extends Node2D


signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_data

var speed = 200
var colors = [[0,1,1,1], [1,0,1,1], [0,1,0,1], [1,0,0,1], [1,1,0,1]]
var particle_generator_scene = load("res://addons/RigidBodyParticles2D/RigidBodyParticles2D.tscn")
# Spatial coordinate of partical generator
var generator_idx = 0
var locked = false
var game_states


func _ready():
	# Create x new particle generators
	for x in range(0, colors.size()):
		_create_new(x)

	$PointTracker.set_winning_colors([roll_winner()])
	$PointTracker.set_display()
	$Timer.start()

# Determine winning particle color
func roll_winner():
	randomize()
	var x = randi_range(0, colors.size()-1)
	return Color(int(colors[x][0]), int(colors[x][1]), int(colors[x][2]), int(colors[x][3]))

# Create new particle generator || x is index in colors list
func _create_new(x):
	# Create new generator
	var particle_generator = particle_generator_scene.instantiate()
	
	# Set particle attributes
	var this_color = Color(int(colors[x][0]), int(colors[x][1]), int(colors[x][2]),
	int(colors[x][3]))
	particle_generator.particle_color = this_color
	# Create new point tracker variable for this color
	$PointTracker.set_points(this_color, 0)

	# Connect signals
	randomize()
	particle_generator.connect("particle_caught",Callable($Player,"_on_RigidBodyParticles2D_particle_caught"))
	particle_generator.connect("shot_ended",Callable(self,"_create_new").bind(randi_range(0, colors.size()-1)))
	
	# Add particle generator and set position
	$ParticleGenerators.add_child(particle_generator)
	particle_generator.position.x = (generator_idx*(1600/colors.size()))
	if generator_idx < colors.size():
		generator_idx += 1
	else: generator_idx = 0


func _Timeout():
	for child in $ParticleGenerators.get_children():
		child.queue_free()

func dialog_finished():
	pass
