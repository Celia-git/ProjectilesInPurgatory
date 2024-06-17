extends InteriorScenes


var claw_machine_script = "res://ClawMachine/ClawMachine%d.gd"

func set_ui_color():
	ui_color = Color.BLUE
	
func set_sub_scenes():
	sub_scenes = ["ClawMachine.tscn", "ClawMachine.tscn", "ClawMachine.tscn", "ClawMachine.tscn"]
	
func set_game_path():
	game_path = "res://ClawMachine/"
	
func set_new_active_scene(idx):
	open_games[idx].set_script(load(claw_machine_script%[idx]))
	open_games[idx].machine_idx = str(idx)
	open_games[idx].prize_type = ["Big Pocket", "Lunchbox", "FigurineSets", "Big Pocket"][idx]
	open_games[idx].prize_taken_array = ["plushies_taken", "", "capsules_taken", "toys_taken"][idx]
	super.set_new_active_scene(idx)

