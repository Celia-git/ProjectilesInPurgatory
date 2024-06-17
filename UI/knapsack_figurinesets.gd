extends KnapsackPocket

class_name FigurinePocket


var figurine_set_icons = {}
var icon_filename = "figurine_icon.gd"
var icon_set_filename = "figurine_set_icon.gd"

func set_container():
	self.container = $ScrollContainer/VFlowContainer


# match icons in container to player inventory, delete or add icons as needed

func _load_container_icons():
	var player_figurines=[]
	var player_figurine_sets = []
	
	# Add a new texture icon from player figurines
	for item_dict in Globals.player.figurines:
		# Add Icon to dict and container
		if !(item_dict["name"] in figurine_set_icons.keys()):
			
			var new_item = load(icon_path + icon_filename).new(item_dict["name"], item_dict["atlas_region"], item_dict["assets"], item_dict["meta_combo"], item_dict["set_name"], item_dict["set_size"], item_dict["fixed_icon_position"])
			figurine_set_icons[item_dict["name"]] = new_item
		player_figurines.append(item_dict["name"])
							
	# Remove texture icon if not in inventory
	for icon_name in figurine_set_icons.keys():
		# Remove Icon from dict
		if !(icon_name in player_figurines):
			if figurine_set_icons[icon_name] != null:
				figurine_set_icons[icon_name].queue_free()
			figurine_set_icons.erase(icon_name)
			
	
	# Add icons to container
	add_icons(figurine_set_icons.values())
	
func _scan_figurines_and_sets(icon):
	#  CHeck if another figurine or set is in position of this icon
	pass
