extends Node

signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal set_data


var areas = {"counter":Rect2(320, 500, 960, 150)}
var locked = false
var game_states

# Called when the node enters the scene tree for the first time.
func _ready():
	print("hi")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func dialog_finished():
	pass
	

func get_areas():
	return areas
