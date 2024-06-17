extends TextureButton

class_name InventoryIcon


var item_name:String
var meta_combos=[]
var icon_region:Rect2
var asset_filepath = "Assets/knapsack_"
var asset_files = []

# Child texture node
var texture

@export var drag_speed = 45

func _init(item_name, atlas, assets, meta_combos):

	self.item_name = item_name	
	self.tooltip_text = item_name
	self.icon_region = atlas
	self.asset_files.append_array(assets)
	self.meta_combos = meta_combos
	self.size = atlas.size
	self.texture = get_texture(0)
	self.texture.scale = Vector2(3, 3)
	self.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	self.mouse_filter = Control.MOUSE_FILTER_PASS
	self.custom_minimum_size = 3 * atlas.size
	
	add_child(texture)
	set_texture_click_mask()


# Create Texture2D, add atlas texture, and return
func get_texture(asset_file_idx, color=Color(0,0,0,1)):
	var icon_texture = TextureRect.new() 
	var new_texture = AtlasTexture.new()
	new_texture.atlas = load(asset_filepath+asset_files[asset_file_idx])
	new_texture.region = self.icon_region
	icon_texture.texture = new_texture
	# Set size flags
	if asset_file_idx==0:
		icon_texture.expand_mode = TextureRect.EXPAND_KEEP_SIZE
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP
		icon_texture.custom_minimum_size = 3*self.icon_region.size
			
	if color != Color(0,0,0,1):
		icon_texture.self_modulate = color
	
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon_texture

# Create a texture click mask:
func set_texture_click_mask():
	
	# Get bitmask sheet
	var bitmask_sheet = load(asset_filepath + asset_files[-1])
	
	# Create new cropped bitmap image made of boolean values
	var mask = BitMap.new()
	mask.create(self.icon_region.size)
	
	for x in range(self.icon_region.size.x):
		for y in range(self.icon_region.size.y):
			var bitval = bitmask_sheet.get_bitv(Vector2i(self.icon_region.position) + Vector2i(x,y))
			mask.set_bitv(Vector2i(x, y), bitval)
			
	
	# Resize image and set as click mask
	mask.resize(3*self.icon_region.size)
	self.texture_click_mask = mask
	
	
