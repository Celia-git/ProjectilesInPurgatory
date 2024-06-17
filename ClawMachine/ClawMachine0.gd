extends ClawMachine

func set_prizes():
	
	self.prize_path = prize_path % [machine_idx]
	prize_exceptions = game_states.claw_machine[prize_taken_array]
	var prize_dir = DirAccess.open(prize_path)
	var prize_names = []
	var prize_scenes = []

	
	if prize_dir:
		prize_dir.list_dir_begin()
		var file_name = prize_dir.get_next()
		while file_name != "":
			if !prize_dir.current_is_dir():
				var prize_name = file_name.trim_suffix(".tscn").replace("_", " ")
				if prize_name in prize_exceptions:
					continue
				else:
					prize_scenes.append(prize_path+file_name)
					prize_names.append(prize_name)
			file_name = prize_dir.get_next()
	
	var icon_pos = Vector2(0,0)
	var icon_size = Vector2(32, 32)
	var p = 0
	for scene in prize_scenes:
		
		var prize = load(scene).instantiate()
		super.set_prize_physical_parameters(prize)
		prize.prize_name = prize_names[p]
		prize.inventory_location = "Big Pocket"
		prize.asset_names = ["plushies.png", "plushies_click_mask.bmp"]
		prize.meta_combo.append("plushie")
		prize.atlas_region = Rect2(icon_pos, icon_size)
		prize.add_to_group("prizes")
		
		if (icon_pos.x + icon_size.x) < 160:
			icon_pos.x += icon_size.x
		else:
			icon_pos.y += icon_size.y
			icon_pos.x = 0
		p += 1
