extends Node2D

signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_data
signal move_vessel	# Move carryover vessel up or down
signal sheild_opened


@onready var height = 180
@onready var width = 320
var areas = {"blender":Rect2(850, 250, 350, 450)}
var allowed_vessels = ["Cup", "BlizzieCup"]
var locked = false


var all_points = 0
var over_blended_points = 0
var goal_idx = 0
var aim_idx = 0
var amount_of_rounds = 0
var target_round_amount = 7
var animating = false

# Nodes
@onready var wand = $Wand	# Spinning Wand Icon
@onready var aim_box = $VerticalController 
@onready var goal = $VerticalController/PanelContainer/Goal
@onready var aim = $VerticalController/PanelContainer/Aim
@onready var wandhead = $WandStick/WandHead

var game_states=Globals.game_states

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_wand()
	set_process(false)

# Apply Wand rotational acceleration based on button press

func _process(_delta):
	
	if Input.is_action_pressed("E") && wand.blendable:
		if !wandhead.is_playing():
			wandhead.play("default")
		if wand.animator.speed_scale < wand.max_velocity:
			wand.animator.speed_scale += wand.acceleration
			wandhead.speed_scale += wand.acceleration
	else:
		if wand.animator.speed_scale > 0:
			wand.animator.speed_scale -= .5*wand.acceleration
			wandhead.speed_scale -= .5*wand.acceleration
		else:
			if wandhead.is_playing():
				var tween = create_tween()
				tween.tween_property(wandhead, "speed_scale", 0, wandhead.speed_scale)
				await get_tree().create_timer(wandhead.speed_scale).timeout
				wandhead.stop()
# Parse Input: UP/DOWN buttons  to move aim and vessel

func _input(event):
	if event.is_action_pressed("ui_up"):
		if can_move_aim(-1):
			wand.blendable = false
			wand.stop_timer()
			move_aim(-1)
			$WandStick.position.y -=5
			emit_signal("move_vessel",0)
	elif event.is_action_pressed("ui_down"):
		if can_move_aim(1):
			wand.blendable = false
			wand.stop_timer()
			move_aim(1)
			$WandStick.position.y += 5
			emit_signal("move_vessel", 0)	
			

# After Aim meets goal: Start wand 
func start_new_cycle():
	wand.disconnect_progress_signal()
	wand.new_checkpoint()
	amount_of_rounds += 1
		


# Move the goal to new index, starting blender game
func move_goal():
	# Game is over, tally score
	if amount_of_rounds >= target_round_amount:
		close_sheild()
		return
		
	# Remove goal from current parent
	aim_box.get_child(goal_idx).remove_child(goal)
	
	var new_goal_idx = goal_idx
	while (new_goal_idx == goal_idx) || (new_goal_idx==aim_idx):
		randomize()
		new_goal_idx = randi_range(0, aim_box.get_child_count()-1)
	goal_idx = new_goal_idx
	aim_box.get_child(goal_idx).add_child(goal)
	

func move_aim(direction):

	aim_box.get_child(aim_idx).remove_child(aim)
	aim_box.get_child(aim_idx + direction).add_child(aim)
	aim_idx = aim_idx+direction
	if aim_idx == goal_idx:
		start_new_cycle()


func can_move_aim(direction):
	if ((aim_idx + direction) > -1) && ((aim_idx + direction) < aim_box.get_child_count()):
		return true
	return false
	
func connect_wand():
	if !wand.add_points.is_connected(_add_points):	
		wand.add_points.connect(_add_points)	
	if !wand.add_late_points.is_connected(_add_late_points):
		wand.add_late_points.connect(_add_late_points)
	if !wand.round_ended.is_connected(move_goal):
		wand.round_ended.connect(move_goal)

# Start blender game
func open_sheild():
	if animating:
		return
	
	locked = true
	animating = true
	var tween = create_tween()
	tween.tween_property($Sheild, "position:y", -70, .5).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(.5).timeout
	emit_signal("sheild_opened")
	set_process(true)
	all_points=0
	move_goal()
	animating = false
	
# End blender game
func close_sheild():
	if animating:
		return
	animating = true
	var tween = create_tween()
	tween.tween_property($Sheild, "position:y", 0, .5).set_trans(Tween.TRANS_SINE)
	set_process(false)
	wandhead.stop()
	# Emit signal set data total points
	emit_signal("set_data", calculate_final_points())
	locked = false
	animating = false
	
func _add_points(points):
	all_points += points
	
func _add_late_points(points):
	over_blended_points += points
	
	
func calculate_final_points():
	var final_points = (all_points+over_blended_points)/float(target_round_amount)
	return final_points

func dialog_finished():
	pass

func get_areas():
	return areas
	


