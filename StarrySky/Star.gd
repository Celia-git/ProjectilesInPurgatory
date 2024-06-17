extends Node2D

signal star_entered
signal self_select
signal self_deselect
signal overlap

var max_width
var max_height
var speed = 30
var selected = false
var rest_point
var index_line1
var index_line2  #the star's position in line 1 or 2 of the constellation

var stabilize = false
var stabilize_speed = 50

func _ready():
	var o = $Area2D.has_overlapping_areas()
	emit_signal("overlap", o)
		
func _physics_process(delta):
	if selected && !stabilize:
		global_position = lerp(global_position, get_global_mouse_position(), speed*delta)
	
	elif selected && stabilize:
		if global_position.x>max_width:
			global_position.x -= stabilize_speed*delta
		elif global_position.x<16:
			global_position.x += stabilize_speed*delta
		
		if global_position.y>max_height:
			global_position.y -= stabilize_speed*delta
		elif global_position.y<16:
			global_position.y += stabilize_speed*delta
			
	else:
		@warning_ignore("integer_division")
		global_position = lerp(global_position, rest_point, (speed/4)*delta)

	var out_of_bounds = (global_position.x>max_width||global_position.x<0||global_position.y>max_height||global_position.y<0)
	if out_of_bounds:
		stabilize = true
		emit_signal("self_select", self)
	elif !out_of_bounds and stabilize==true:
		rest_point = global_position
		emit_signal("self_deselect", self)
		stabilize = false



func get_star_index(arg):
	if arg==0:
		return index_line1
	elif arg==1:
		return index_line2

func set_star_index(arg1, arg2):
	index_line1 = arg1
	index_line2 = arg2

func _on_area_2d_input_event(_viewport, _event, _shape_idx):
	emit_signal("star_entered", self)



