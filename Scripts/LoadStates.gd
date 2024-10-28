extends Node

signal save_finished

var save_signal_emitted = false


var interior_setting = "res://Games/GamesInt.tscn"
var exterior_setting = "res://Maps/ExteriorScenes.tscn"
	
# Keep track of which data has been saved
var terminate_next = false
var game_data_saved = false
var player_saved = false



func new_player():
	var player = load(Globals.player_script).new()
	player.player_name = "Player"
	return player

func new_game():
	return load(Globals.game_script).new()


# Load player states based on file data
func load_player():
	player_saved = false

	# Load player saved values 
	var file_path = Globals.user_directory + Globals.player_file
	if ResourceLoader.exists(file_path):
		var load_player = ResourceLoader.load(file_path)
		if load_player is Player: # Check that the data is valid
			return load_player
	
	# If no current player file, return new one with default values
	return new_player()
	
	
func load_game_data():
	game_data_saved = false
	
	var file_path = Globals.user_directory + Globals.game_file
	if ResourceLoader.exists(file_path):
		var load_data = ResourceLoader.load(file_path)
		if load_data is GameData: # Check that the data is valid
			if load_data.esther != null: 
				return load_data
		
	# if Data is corrupted or file is missing, load new game data
	return new_game()

	

# Return filepath of active scene
func get_setting(active_map:int, map_type:String):
	var main
	
	match map_type:
		"Interior":		
			main = load(interior_setting).instantiate()
		"Exterior":
			main = load(exterior_setting).instantiate()
			main.load_map(active_map)
			
	main.setting_index = active_map
	return main
	



# Save data to file at quit

func save_player(player):
	
	var file_path = Globals.user_directory + Globals.player_file
	var result = ResourceSaver.save(player, file_path)
	assert(result == OK)
	player_saved=true
	check_saves()

func save_game_data(data):
	var file_path = Globals.user_directory + Globals.game_file
	var result = ResourceSaver.save(data, file_path)
	assert(result == OK)
	game_data_saved=true
	check_saves()
	

		
# Check if save is finished, emit signal if so
func check_saves():
	if (player_saved && game_data_saved && !save_signal_emitted):
		emit_signal("save_finished", terminate_next)
		save_signal_emitted=true
