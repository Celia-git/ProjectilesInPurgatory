extends InteriorScenes



func set_ui_color():
	ui_color = Color.GREEN_YELLOW
	
func set_sub_scenes():
	sub_scenes = ["DuckHub.tscn"]
	
func set_game_path():
	game_path = "res://Ducks/"
	


# CarryOver Node entered
func _on_nodes_child_entered_tree(node):
	pass # Replace with function body.
