extends KnapsackPocket

class_name Lunchbox

var icon_filename = "lunchbox_icon.gd"
var lunchbox_icons = {}

func set_container():
	container = $ScrollContainer/Container

# match icons in container to player inventory, delete or add icons as needed

func _load_container_icons():
	var player_lunchbox=[]
	
	# Add a new texture icon from player data
	for item_dict in Globals.player.lunchbox:
		# Add Icon to dict and container
		if !(item_dict["name"] in lunchbox_icons.keys()):
			var new_item = load(icon_path + icon_filename).new(item_dict["name"], item_dict["atlas_region"], item_dict["assets"], item_dict["meta_combo"], item_dict["color"])
			lunchbox_icons[item_dict["name"]] = new_item
		player_lunchbox.append(item_dict["name"])
							
	# Remove texture icon if not in inventory
	for icon_name in lunchbox_icons.keys():
		# Remove Icon from dict
		if !(icon_name in player_lunchbox):
			if lunchbox_icons[icon_name] != null:
				lunchbox_icons[icon_name].queue_free()
			lunchbox_icons.erase(icon_name)
	
	# Add icons to container
	add_icons(lunchbox_icons.values())
	
	
