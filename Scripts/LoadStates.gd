extends Node

signal save_finished

var save_signal_emitted = false
var exterior_settings = "res://Maps/ExteriorScenes.tscn"


var interior_settings = [
	"res://ClawMachine/ClawMachineInt.tscn",
	"res://Ducks/DucksInt.tscn",
	"res://Esther/MadameEstherInt.tscn",
	"res://Games/GamesInt.tscn",
	"res://IceCream/IceCreamInt.tscn",
	"res://Popper/PopperInt.tscn",
	"res://StarrySky/TelescopeInt.tscn",
	"res://PortaPotty/PortaPottyInt.tscn",
	"res://FerrisWheel/FerrisWheel.tscn",
	"res://Gumball/GumballMachine.tscn"
	]
	
# Keep track of which data has been saved
var terminate_next = false
var player_saved = false
var game_data_saved = false
var image_saved = false


func new_player(username):
	var player = load(Globals.player_script).new()
	player.player_name = username
	return player
	

func new_game():
	return load(Globals.game_script).new()

# Load player states based on file data
func load_player(file_name):
	player_saved = false

	# Load player saved values 
	var file_path = Globals.user_directory + file_name + Globals.player_file
	if ResourceLoader.exists(file_path):
		var load_player = ResourceLoader.load(file_path)
		if load_player is Player: # Check that the data is valid
			return load_player
	
	# If no current player file, return new one with default values
	return new_player(file_name)
	
func load_game_data(file_name):
	game_data_saved = false
	
	var file_path = Globals.user_directory + file_name + Globals.game_file
	if ResourceLoader.exists(file_path):
		var load_data = ResourceLoader.load(file_path)
		if load_data is GameData: # Check that the data is valid
			return load_data

	# if Data is corrupted or file is missing, load new game data
	return new_game()

func load_image(file_name):
	image_saved = false
	save_signal_emitted=false
	var file_path =Globals.user_directory + file_name + Globals.image_file

	if FileAccess.file_exists(file_path):
		var image = Image.load_from_file(file_path)
		if image is Image:
			return image
	
	var default_image = Image.create(512, 512, false, 5)
	default_image.fill(Color.BLUE_VIOLET)
	return default_image
	
	

# Return filepath of active scene
func get_setting(active_map:int, map_type:String):
	var main
	
	match map_type:
		"Interior":		
			var scene = interior_settings[active_map]
			main = load(scene).instantiate()
		"Exterior":
			main = load(exterior_settings).instantiate()
			main.load_map(active_map)
			
	main.setting_index = active_map
	return main
	


# Save data to file at quit

func save_player(player, file_name):
	
	validate_user(file_name)
	var file_path = Globals.user_directory +file_name+ Globals.player_file
	var result = ResourceSaver.save(player, file_path)
	assert(result == OK)
	player_saved=true
	check_saves()
	
func save_game_data(data, file_name):
	validate_user(file_name)
	var file_path = Globals.user_directory + file_name + Globals.game_file
	var result = ResourceSaver.save(data, file_path)
	assert(result == OK)
	game_data_saved=true
	check_saves()
	
func save_image(image, file_name):
	validate_user(file_name)
	var error = image.save_png(Globals.user_directory+file_name+Globals.image_file)
	
	if !(error==OK):
		print("error saving image")
	else:
		image_saved = true	
		check_saves()
		
# Checks if user folder exists, if not, creates one
func validate_user(username):
	if !DirAccess.dir_exists_absolute(Globals.user_directory+username+"/"):
		# User not in Directories: create new user folder
		DirAccess.make_dir_absolute(Globals.user_directory+username+"/")
		
# Check if save is finished, emit signal if so
func check_saves():
	if (player_saved && game_data_saved && image_saved && !save_signal_emitted):
		emit_signal("save_finished", terminate_next)
		save_signal_emitted=true
