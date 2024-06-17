extends Panel


var front_pocket:Array
var lunchbox:Array
var big_pocket:Array
var texture_path = "res://UI/InventoryIcons/%s.tres"

var front_pocket_icons = []
var lunchbox_icons = []
var big_pocket_icons = []

var icons_loaded = false

func _ready():
	# Load Inventory Icons from file and save in texture_path
	pass


# Update changed inventory
func load_inventory(front, lunch, big):
	icons_loaded = (front==self.front_pocket) and (lunch==self.lunchbox) and (big==self.big_pocket)
		
	self.front_pocket = front
	self.lunchbox = lunch
	self.big_pocket = big
	
	if !icons_loaded:
		load_icons()
		
# Load Inventory icons from texture path
func load_icons():
	var tab_idx = 0
	for array in [front_pocket, lunchbox, big_pocket]:
		var node = $TabContainer.get_tab_control(tab_idx)
		var texture_array = []
		for item in array:			
			var texture = load(texture_path % [item])
			var texture_icon = TextureRect.new()
			texture_icon.set_meta("name", item)
			texture_array.append(texture_icon)
			
		node.add_icons(texture_array)
		tab_idx += 1

	icons_loaded = true

