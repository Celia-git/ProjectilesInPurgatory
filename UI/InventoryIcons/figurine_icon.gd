extends InventoryIcon

class_name FigurineIcon

var set_name:String
var set_size:int
var fixed_icon_position:bool

func _init(item_name, atlas, assets, meta_combos, set_name, set_size, fixed_icon_position):
	self.set_name = set_name
	self.set_size = set_size
	self.fixed_icon_position = fixed_icon_position
	super._init(item_name, atlas, assets, meta_combos)
	
