extends ClawMachine

var prize_inventory_path = "res://ClawMachine/resources/Prizes_Toys.txt"

var inventory={}	#itemname:amount
var colors = []

# If toy inventory icons are meant to have different sizes, save them in file and set 
# Icon rects here
# Same with meta combos, colors, etc

func set_prizes():
	
	self.prize_path = prize_path % [machine_idx]
	prize_exceptions = game_states.claw_machine[prize_taken_array]
	
	var inventory_file = FileAccess.open(prize_inventory_path, FileAccess.READ) 
	while inventory_file.get_position() < inventory_file.get_length():
		var line = inventory_file.get_line().split("/")
		inventory[line[1]]=int(line[0])
	
	var prize_dir = DirAccess.open(prize_path)
	var prize_scenes = {}
	if prize_dir:
		prize_dir.list_dir_begin()
		var file_name = prize_dir.get_next()
		while file_name != "":
			if !prize_dir.current_is_dir():
				var prize_name = file_name.trim_suffix(".tscn")
				var prize_name_array = file_name.split("_")
				prize_name = prize_name.replace("_", " ")
					
				var trimmed_prize_name = prize_name
				if trimmed_prize_name in prize_exceptions:
					continue
				for letter in prize_name:
					if letter.is_valid_int() and letter != "8":
						trimmed_prize_name = prize_name.substr(2)
						if trimmed_prize_name in prize_scenes.keys():
							prize_scenes[trimmed_prize_name].append(prize_path+file_name)
						else:
							prize_scenes[trimmed_prize_name] = [prize_path + file_name]
						break
					else:
						prize_scenes[trimmed_prize_name] = [prize_path + file_name]
						break
			
			file_name = prize_dir.get_next()
			
	for item in inventory.keys():
		var amount = inventory[item]
		
		
		var p = 0
		for i in range(amount):
			var prize = load(prize_scenes[item][p]).instantiate()
			super.set_prize_physical_parameters(prize)
			
			prize.set_sprite_color(get_toy_color(i, amount))
			prize.prize_name = item
			prize.atlas_region = prize.get_meta("icon_region")
			prize.add_to_group("prizes")
			prize.meta_combo = get_meta_combos(prize.sprite_color, item, amount==1)
			prize.inventory_location = prize_type
			prize.asset_names = ["toys_0.png", "toys_1.png", "toys_click_mask.bmp"]

			if p < (prize_scenes[item].size()-1):
				p += 1
			else:
				p = 0
	
func get_meta_combos(shape, color, is_unique):
	return []

func get_toy_color(index, total):
	return Color()
