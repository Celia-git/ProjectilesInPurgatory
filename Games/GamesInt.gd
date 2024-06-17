extends InteriorScenes

@onready var radial_progress = $Control/RadialBox/ProgressPie
@onready var hori_progress = $Control/HorizontalBox/ProgressBar
@onready var vert_progress = $Control/VerticalBox/ProgressBar
@onready var alert = $Control/PopupPanel
@onready var score = $Control/Score/Label

var cannon=null
var label_path = "res://Assets/GamesInt"
var labels = ["KnockemLabel.png", "RingtossLabel.png", "ShipyardLabel.png"]

func set_ui_color():
	ui_color = Color.DARK_RED
	
func set_sub_scenes():
	sub_scenes = ["Knockem/Knockem.tscn", "RingToss/RingToss.tscn", "Ships/Shipyard.tscn"]
	
func set_game_path():
	game_path = "res://Games/"

func set_backgrounds():
	backgrounds = ["GamesIntKnockemBackground.png",
		"GamesIntRingtossBackground.png",
		"GamesIntShipyardBackground.png"]

func set_current_background(idx):
	$Background/Sprite2D.texture = load(Globals.backgrounds_path + backgrounds[idx])

func connect_to_signals(game, game_index):
	if !game.set_value.is_connected(_set_game_value):
		game.set_value.connect(_set_game_value)
	if !game.set_max_value.is_connected(_set_max_value):
		game.set_max_value.connect(_set_max_value)
	# For knockem and shipyard signals
	if game_index==2 or game_index==0:
		if !game.cannon_launch_over.is_connected(_cannon_launch_over):
			game.cannon_launch_over.connect(_cannon_launch_over)
	
	# For shipyard signals
	if game_index == 2:
		if !game.shift_cannon_up.is_connected(_shift_ship_cannon_up):
			game.shift_cannon_up.connect(_shift_ship_cannon_up)
		if !game.shift_cannon_down.is_connected(_shift_ship_cannon_down):
			game.shift_cannon_down.connect(_shift_ship_cannon_down)
	super.connect_to_signals(game, game_index)
	
func set_new_active_scene(idx):
	# Set game label
	$Frame/Frame/Label.texture = load(label_path+labels[idx])
	
	# Set visible controls based on active scene
	reset_control_nodes()
	if cannon != null:
		cannon.call_deferred("queue_free")
	match idx:
		0: # Knockem
			radial_progress.visible = true
			hori_progress.visible = true
			vert_progress.visible = true
			vert_progress.fill_mode = 2 # Fill top to bottom
		
		1: # Ringtoss
			hori_progress.visible = true
			vert_progress.visible = true
			vert_progress.fill_mode = 3 # Fill bottom to top
			
		2: # Shipyard
			hori_progress.visible = true

	super.set_new_active_scene(idx)
	if idx==0 or idx==2:
		pixel_world.get_sub_game().transfer_carry_overs()
	pixel_world.get_sub_game().new_round()
	
# Set game variables on the control level
func _set_game_value(setting:String, value:Variant=""):
	
	match setting:
		"vertical progress":
			vert_progress.value = value
		"horizontal progress":
			hori_progress.value = value
		"radial progress":
			radial_progress.value = value
		"score":
			score.text = str(value)
		"win":
			# Show win alert
			alert.get_node("Label").text = "You WIN!"
			#alert.get_node("Button").visible = false
			alert.popup_centered()
			await get_tree().create_timer(1).timeout
			alert.popup_centered()
			alert.get_node("Label").text = "Go Again?"
		#	alert.get_node("Button").visible = true
			# New game alert popup

# Set max values in control nodes
func _set_max_value(setting:String, value:Variant):
	
	match setting:
		"vertical progress":
			vert_progress.max_value = value
		"horizontal progress":
			hori_progress.max_value = value
		"radial progress":
			radial_progress.max_value = value
		
# Reset all control node values and set invisible
func reset_control_nodes():
	for node in [radial_progress, hori_progress, vert_progress, alert]:
		if node is TextureProgressBar:
			node.value = 0
		node.visible = false

# Start new game
func _on_button_pressed():
	pixel_world.get_sub_game().new_round()
	$Control/PopupPanel.visible = false

# Cannon enter carryover nodes: connect to signals
func _on_carryover_nodes_child_entered_tree(node):
	if node.is_in_group("Cannon"):
		if cannon != null:
			cannon.queue_free()
		cannon = node
		
		# Connect shipyard cannon to signals		
		if active_scene_idx==2:
			if !node.launch.is_connected(_launch_cannon):
				cannon.launch.connect(_launch_cannon)

func _launch_cannon():
	# If ships cannon
	if active_scene_idx==2 and cannon:
		pixel_world.get_sub_game().launch_cannonball(cannon.global_position)

func _cannon_launch_over():
	if cannon:
		cannon.is_launched = false

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#Update cannon lit progress bar
	if ( (active_scene_idx==0||active_scene_idx==2) and (cannon != null) ):
		if cannon.is_lit:
			_set_game_value("horizontal progress", 100*cannon.get_time())
		elif !(cannon.is_launched or cannon.is_lit):
			
			# Move Cannon Horizontally
			var move_cannon_left = Input.is_action_pressed("ui_left")
			var move_cannon_right = Input.is_action_pressed("ui_right")
			if move_cannon_left and (cannon.position.x > Globals.pixelframe.position.x):
				cannon.position.x -= cannon.HORIZONTAL_SPEED*delta
			elif move_cannon_right and (cannon.position.x < Globals.pixelframe.position.x+Globals.pixelframe.size.x):
				cannon.position.x += cannon.HORIZONTAL_SPEED*delta
				
			# In knockem, spring compressed cannon
			if active_scene_idx == 0:
				# Compress spring or launch
				if (Input.is_action_pressed("E") && cannon.compression_distance<cannon.MAX_COMPRESSION):
					cannon.compression_distance += cannon.compression_increment*delta
					# Adjust compression increment
					if cannon.compression_increment > .01:
						cannon.compression_increment -= delta
					_set_game_value("vertical progress", 100*cannon.compression_distance)
				
				elif (Input.is_action_just_released("E") || cannon.compression_distance>=cannon.MAX_COMPRESSION):
					pixel_world.get_sub_game().launch_cannonball(cannon.global_position)	
					cannon.compression_distance=0
					cannon.compression_increment = 3
					cannon.is_launched = true
		

						
#Handling Input
func _input(event):
	
	if event.is_action_pressed("ui_down"):
		if active_scene_idx==2 and cannon:
			pixel_world.get_sub_game().shift_cannon("down")
		
	elif event.is_action_pressed("ui_up"):
		if active_scene_idx==2 and cannon:
			pixel_world.get_sub_game().shift_cannon("up")
	
	if event.is_action_pressed("E"):
		if active_scene_idx==2 and cannon!=null:
			if !cannon.is_lit:
				cannon.start_timer()
				cannon.is_lit = true

func _shift_ship_cannon_down():
	if cannon:
		cannon.move_down()
		
func _shift_ship_cannon_up():
	if cannon:
		cannon.move_up()
