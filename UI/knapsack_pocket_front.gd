extends KnapsackPocket

class_name FrontPocket

signal reload_icons

# container is for item nodes, notebook_container for prompts, tips, and quests

var all_front_icon_textures = {}	#item_name:[texture_normal, texture_hovered, texture_pressed]
var icon_filename = "front_pocket_icon.gd"
var notebook_container
var front_pocket_assets = "res://Assets/knapsack_front_pocket.png"
var front_pocket_asset_file_size = Vector2(320,160)
var front_pocket_icon_size = Vector2(32, 32)
var front_pocket_items = ["Treasure Chest"]
var front_pocket_icons = {}

func set_container():
	container = $Container/Inventory/Items
	notebook_container = $Container/Notebook/ScrollContainer/PanelContainer
	load_all_all_front_icon_textures()
	
# Load all front pocket textures from file on ready
func load_all_all_front_icon_textures():
	var atlas_position = Vector2()
	
	# Load Texture for each front pocket inventory icon
	for item in front_pocket_items:
		var relative_x = 0
		all_front_icon_textures[item] = []
		
		# Create 3 button state textures per icon
		for button_state in ["normal", "hover", "pressed"]:
			var icon_region = Rect2(Vector2(atlas_position.x+relative_x, atlas_position.y), front_pocket_icon_size)
			var new_texture = AtlasTexture.new()
			new_texture.atlas = load(front_pocket_assets)
			new_texture.region =  icon_region
			
			all_front_icon_textures[item].append(new_texture)
			
			relative_x += front_pocket_icon_size.x
		
		increment_position(atlas_position, front_pocket_asset_file_size, Vector2(front_pocket_icon_size.x*3, front_pocket_icon_size.y))
		
# Load pertinent Inventory Icons
func _load_container_icons():
	
	var player_front_pocket = []
	
	# Add new texture button item if necesssary
	for item_dict in Globals.player.front_pocket:
		if !(item_dict["name"] in front_pocket_icons.keys()):
			var textures = all_front_icon_textures[item_dict["name"]]
			var icon = load(icon_path + icon_filename).new(item_dict["name"], item_dict["consumable"], textures[0], textures[1], textures[2])
			front_pocket_icons[item_dict["name"]] = icon
		player_front_pocket.append(item_dict["name"])
	
	# Remove texture icon if not in inventory
	for icon_name in front_pocket_icons.keys():
		# Remove Icon from dict
		if !(icon_name in player_front_pocket):
			if front_pocket_icons[icon_name] != null:
				front_pocket_icons[icon_name].queue_free()
			front_pocket_icons.erase(icon_name)
				
	add_icons(front_pocket_icons.values())

# Remove an item, add one or more
func _consume_item(icon):
	match icon.item_name:
		"Treasure Chest":
			# Create new prizes from consumable data and add them to player.front_pocket
			pass
			
			
			
	icon.queue_free()
	emit_signal("reload_icons")
