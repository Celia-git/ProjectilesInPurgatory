extends InventoryIcon

class_name LunchboxIcon


func _init(item_name, atlas, assets, meta_combos, color):
	super._init(item_name, atlas, assets, meta_combos)
	var top_texture = get_texture(1, color)
	texture.add_child(top_texture)

