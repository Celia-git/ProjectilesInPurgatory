extends KnapsackPocket

class_name BigPocket

var big_pocket_icons = {}
var icon_filename = "big_pocket_icon.gd"

func set_container():
	container = $ScrollContainer/Container
	
# match icons in container to player inventory, delete or add icons as needed

func _load_container_icons():
	var player_big_pocket=[]
	
	# Add a new texture icon from player data
	for item_dict in Globals.player.big_pocket:
		# Add Icon to dict and container
		if !(item_dict["name"] in big_pocket_icons.keys()):
			var new_item = load(icon_path + icon_filename).new(item_dict["name"], item_dict["atlas_region"], item_dict["assets"], item_dict["meta_combo"], item_dict["color"])
			big_pocket_icons[item_dict["name"]] = new_item
		player_big_pocket.append(item_dict["name"])
							
	# Remove texture icon if not in inventory
	for icon_name in big_pocket_icons.keys():
		# Remove Icon from dict
		if !(icon_name in player_big_pocket):
			if big_pocket_icons != null:
				big_pocket_icons[icon_name].queue_free()
			big_pocket_icons.erase(icon_name)
	
	# Add icons to container
	add_icons(big_pocket_icons.values())
	
