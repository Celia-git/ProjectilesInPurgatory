extends Node2D


signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_data

var areas = {}
var rect_size = Vector2(87, 165)
var all_flavors = []
var path = "res://IceCream/Vessels/"
var scenes = ["WaffleCone.tscn", "BlizzieCup.tscn", "CakeCone.tscn", "Cup.tscn"]
var path_idx = 0
var locked = false

var allowed_vessels = ["Cup"]

var game_states

func _ready():
	if all_flavors.is_empty():
		all_flavors = Globals.get_inventory("soda")
	var x_pos = 30
	for flavor in all_flavors:
		areas[flavor] = Rect2(Vector2(320, 180) + Vector2(x_pos*3, 225), rect_size)
		x_pos += 50


func dialog_finished():
	pass

func get_areas():
	return areas


func _on_area_2d_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		if !(path_idx < scenes.size()):
			path_idx = 0
		
		var vessel = load(path + scenes[path_idx]).instantiate()
		add_child(vessel)
		emit_signal("carry_over", vessel, get_global_mouse_position(), true)
		
		path_idx += 1
