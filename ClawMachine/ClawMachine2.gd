extends ClawMachine

var inventory_path = "res://ClawMachine/resources/Prizes_Capsules.txt"


var meta_combos = ["musicians", "athletes", "clowns", "best_in_show", "rides"]

var all_sets = [] # Array of sets containing image data: each set is a dictionary
var prize_scenes = []
var prize_scene_names = []


func set_prizes():
	if prize_scenes.is_empty():	
		load_prize_scenes()
	if all_sets.is_empty():
		load_set_data()

	generate_capsules()
	
func load_prize_scenes():
	
	self.prize_path = prize_path % [machine_idx]
	prize_exceptions = game_states.claw_machine[prize_taken_array]
	
	var prize_dir = DirAccess.open(prize_path)
	if prize_dir:
		prize_dir.list_dir_begin()
		var file_name = prize_dir.get_next()
		while file_name != "":
			if !prize_dir.current_is_dir():
				prize_scenes.append((prize_path+file_name))
				prize_scene_names.append(file_name.trim_suffix(".tscn"))
			file_name = prize_dir.get_next()
	
func load_set_data():
	var p = 0
	var inventory_file = FileAccess.open(inventory_path, FileAccess.READ)
	var skip_next_qualifier = false
	while inventory_file.get_position() < inventory_file.get_length():
		
		var line = inventory_file.get_line().split("/")
		
		if line[0]=="":
			continue
		# Add all nodes in Previous set to group
		if line[0].begins_with("+") and !skip_next_qualifier:			
			all_sets[-1]["meta_combo"].append(line[0].trim_prefix("+"))
			continue
		
		
		# Read Atlas data for prizes and sets from file
		var amt = line[0]
		var set_name = line[1]
		var prize_size_array = Array(line[2].split(","))
		var prize_size = Vector2(int(prize_size_array[0]), int(prize_size_array[1]))
		var fixed_position = (line[-1]=="true")
		var base_rect = Rect2(0,0,0,0)
		var base_idx = -1
		if fixed_position:
			base_idx = -2
		var base_rect_array = Array(line[base_idx].trim_prefix("base:").split(","))
		for i in range(base_rect_array.size()):
			var entry = base_rect_array[i]
			match i:
				0:
					base_rect.position.x = int(entry)
				1:
					base_rect.position.y = int(entry)
				2:
					base_rect.size.x = int(entry)
				3:
					base_rect.size.y = int(entry)
		
		
	
		# Add A new set
		var this_set = {}
		this_set["set_size"] = int(amt)
		this_set["set_name"] = set_name
		this_set["atlas"] = base_rect
		this_set["prizes"] = {} # Name, Icon Position
		this_set["fixed_position"] = fixed_position
		this_set["meta_combo"] = []
		var j = 0

		# Iterate toys in set
		while j < this_set["set_size"]:
			var full_entry = Array(line[3+j].split(":"))
			var prize_name = full_entry[0]
			var prize_coor = full_entry[1]
			if !(prize_name in prize_exceptions):
				var prize_atlas = Rect2(base_rect.position, prize_size)
				var pos_data = Array(prize_coor.split(","))
				for i in range(pos_data.size()):
					match i:
						0:
							prize_atlas.position.x += int(pos_data[i])
						1:
							prize_atlas.position.y += int(pos_data[i])
						2:
							prize_atlas.size.x = int(pos_data[i])
						3: 
							prize_atlas.size.y = int(pos_data[i])

				this_set["prizes"][prize_name] = prize_atlas

			j += 1
			
		if this_set["prizes"].is_empty():
			skip_next_qualifier = true
			continue
			
		all_sets.append(this_set)
		skip_next_qualifier = false
		
		
func generate_capsules():
	# Assign prize capsule scenes to prizes; 1 lucky set in treasure chest
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var lucky_number = -1
	if !game_states.claw_machine["treasure_taken"]:	
		lucky_number = randi_range(0, all_sets.size())
	# Iterate all sets
	var capsule_index = 0
	for i in range (all_sets.size()):
		var set = all_sets[i]
		
		# Treasure chest
		if i == lucky_number:
			add_new_treasure_chest(prize_scenes[7], set)
			
		else:
			# Add new scene for each prize in set
			for prize_name in set["prizes"].keys():
				add_new_prize(prize_scenes[capsule_index], prize_scene_names[capsule_index], prize_name, set["set_name"], set["set_size"], set["atlas"], set["prizes"][prize_name], set["fixed_position"], set["meta_combo"])
		
		if capsule_index < prize_scenes.size()-2:
			capsule_index+=1
		else:
			capsule_index=0	
		
# Add a new Prize
func add_new_prize(prize_scene:String, prize_scene_name:String, prize_name:String, set_name:String, set_size:int, set_atlas:Rect2, atlas:Rect2, fixed_position:bool, meta_combo=[]):
	var prize = load(prize_scene).instantiate()		
	super.set_prize_physical_parameters(prize)
	prize.prize_name = prize_name	
	prize.add_to_group("prizes")
	prize.add_to_group("capsules")
	prize.set_name = set_name
	prize.set_size = set_size
	prize.set_atlas_region = set_atlas
	prize.atlas_region = atlas
	prize.fixed_icon_position = fixed_position
	prize.meta_combo = meta_combo
	prize.inventory_location = prize_type
	prize.asset_names = ["figurines_0.png", "figurines_1.png", "figurines_click_mask.bmp"]
	load_prize_texture(prize, prize_scene_name)
	prize.set_sprite_hue()


func add_new_treasure_chest(prize_scene:String, set:Dictionary):
	var chest = load(prize_scene).instantiate()
	super.set_prize_physical_parameters(chest)
	chest.prize_name = "Treasure Chest"
	chest.add_to_group("prizes")
	chest.add_to_group("capsules")
	chest.set_name = set["set_name"]
	chest.set_size = set["set_size"]
	chest.set_atlas_region = set["atlas"]
	chest.fixed_icon_position = set["fixed_position"]
	chest.meta_combo = set["meta_combo"]
	chest.inventory_location = "Front Pocket"
	for prize in set["prizes"].keys():
		chest.prizes[prize] = set["prizes"][prize]

	load_prize_texture(chest, prize_scene_names[7])
	
