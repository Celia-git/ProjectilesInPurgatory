extends Node2D

signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited

@onready var height = 180
@onready var width = 320
@onready var starscene = "res://StarrySky/Star.tscn" 
@onready var segment_scene = "res://StarrySky/Segment.tscn"
@onready var gradient = load("res://StarrySky/Gradient.tres")

var level = 2

var lines = []
var min_distance = Vector2(100, 500)
var star_amount = 10
var stars_overlapping = false
var segments_overlapping = false
var check_win = false
var selected_star
var automove_star
var win = false
var game_states=Globals.game_data

# Called when the node enters the scene tree for the first time.
func _ready():
	new_level(level)
	
func _physics_process(delta):
	var star_idx1
	var star_idx2	
	if selected_star:
		star_idx1 = selected_star.get_star_index(0)
		star_idx2 = selected_star.get_star_index(1)
		line_movement(delta, star_idx1, star_idx2, get_global_mouse_position(), selected_star.speed)
	if automove_star:
		star_idx1 = automove_star.get_star_index(0)
		star_idx2 = automove_star.get_star_index(1)
		line_movement(delta, star_idx1, star_idx2, automove_star.global_position, automove_star.stabilize_speed)
		
	if check_win && segments_overlapping:
		win = false	
	elif check_win && !segments_overlapping:
		win = true	
	
	check_win = false
	if win: win_game()
		
func _input(event):
	# Left mouse button released
	if event is InputEventMouseButton and selected_star:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			check_win_condition()
			# Deselect Star
			selected_star.rest_point = get_global_mouse_position()
			selected_star.selected = false
			selected_star = null
		
# Move lines by physics process functon
func line_movement(delta, star_idx1, star_idx2, goal_pos, speed):
	# If moving first joint, also move last joint
	if star_idx1 == 0:
		lines[0].set_point_position(star_amount, lerp(lines[0].get_point_position(star_idx1), goal_pos, speed*delta))
	if star_idx2==0:
		@warning_ignore("integer_division")
		lines[1].set_point_position(star_amount/2, lerp(lines[1].get_point_position(star_idx2), goal_pos, speed*delta))
	# Move Joints
	lines[0].set_point_position(star_idx1, lerp(lines[0].get_point_position(star_idx1), goal_pos, speed*delta))
	if star_idx2 != null:
		lines[1].set_point_position(star_idx2, lerp(lines[1].get_point_position(star_idx2), goal_pos, speed*delta))
	
		
# Resets constellation; difficulty: 1-easy||2-medium||3-difficult
func new_level(difficulty:int):
	win = false
	$Label.visible = false
	$Button.visible = false
	remove_constellation()
	star_amount = difficulty*10
	var line1 = Line2D.new()
	var line2 = Line2D.new()
	line1.width = 1
	line2.width = 1
	line1.set_gradient(gradient)
	line2.set_gradient(gradient)
	add_child(line1)
	add_child(line2)
	lines = [line1, line2]
	set_constellation()
			
func set_constellation():
	var first_star_first_line = Vector2(0,0)
	var first_star_second_line = Vector2(0,0)
	var previous_pos = Vector2(0,0)
	for s in star_amount:
		var this_pos = previous_pos
		var difference = abs(previous_pos-this_pos)
		while difference < min_distance:
			this_pos = Vector2(randi_range(0,width), randi_range(0,height))
			difference = abs(previous_pos-this_pos)
		var idx1 = s
		var idx2 = null
		if s%2!=0:
			@warning_ignore("integer_division")
			idx2 = s/2
		add_star(this_pos, idx1, idx2)
		
		if stars_overlapping:
			remove_star(s)
			s-=1
		else:
			lines[0].add_point(this_pos, s)
			if s%2 != 0:
				@warning_ignore("integer_division")
				lines[1].add_point(this_pos, s/2)
					
			previous_pos = this_pos
			if s==0: first_star_first_line = this_pos
			elif s==1: first_star_second_line = this_pos
			
	lines[0].add_point(first_star_first_line, star_amount)
	lines[1].add_point(first_star_second_line, star_amount-1)
	@warning_ignore("integer_division")
	
		
func remove_constellation():
	for child in get_children():
		if child.is_in_group("Stars"):
			child.queue_free()
		elif child is Line2D:
			child.queue_free()
	remove_collision()	
			

func add_star(star_position, idx1, idx2):
	var star = load(starscene).instantiate()
	add_child(star)
	star.position = star_position
	star.rest_point = star_position
	star.set_star_index(idx1, idx2)
	star.max_width = width-16
	star.max_height = height-16
	star.add_to_group("Stars")
	star.connect("star_entered", _on_star_entered)
	star.connect("self_select", _star_self_select)
	star.connect("self_deselect", _star_self_deselect)
	star.connect("overlap", _do_stars_overlap)
	await star.overlap
	
func remove_star(idx):
	for child in get_children():
		if child.is_in_group("Stars"):
			if child.index_line1 == idx:
				child.queue_free()
	
# Check if line segments intersect each other
func check_win_condition():
	# Get array of segments
	var segments = []
	var points = lines[0].get_points()
	for p in points.size()-1:	
		if p == points.size()-2:
			segments.append([points[p], points[p+1], p, 0])
		else:
			segments.append([points[p], points[p+1], p, p+1])
	points = lines[1].get_points()
	for p in points.size()-1:
		if p == points.size()-2:
			segments.append([points[p], points[p+1], (2*p)+1, 1])
		else:
			segments.append([points[p], points[p+1], (2*p)+1, (2*p)+3])
				
	# Add segments
	for segment in segments:
		# Create Area 2D
		var area = load(segment_scene).instantiate()
		var seg_shape = area.get_node("CollisionShape2D").get_shape().duplicate()
		seg_shape.set_a(segment[0])
		seg_shape.set_b(segment[1])
		area.anchor_point1=segment[2]
		area.anchor_point2=segment[3]
		area.get_node("CollisionShape2D").set_shape(seg_shape)
		area.add_to_group("Segments")
		area.monitoring = true
		add_child(area)
		area.no_segment_entered.connect(_no_segments_overlap)
		area.segment_entered.connect(_segments_overlap)
		
func win_game():
	$Label.visible=true
	$Button.visible = true
	await $Button.pressed
	new_level(level)
	return
		
func remove_collision():
	for child in get_children():
		if child.is_in_group("Segments"):
			child.queue_free()
	segments_overlapping = false
	check_win = false
	
# Input entered star
func _on_star_entered(star):
	if Input.is_action_just_pressed("click"):
		remove_collision()
		selected_star = star
		selected_star.selected = true
		
func _star_self_select(star):
	automove_star = star
	star.selected = true

func _star_self_deselect(star):
	automove_star = null
	star.selected = false
	if star == selected_star:
		selected_star = null
	
func _do_stars_overlap(overlap):
	stars_overlapping = overlap

func _no_segments_overlap():
	check_win = true

@warning_ignore("unused_parameter")
func _segments_overlap(area):
	check_win = true
	segments_overlapping=true



func _on_button_pressed():
	pass # Replace with function body.


func dialog_finished():
	pass

