extends InventoryIcon

class_name BigPocketIcon


func _init(item_name, atlas, assets, meta_combos, color):
	super._init(item_name, atlas, assets, meta_combos)
	if assets.size()>1:
		var top_texture = get_texture(1, color)
		texture.add_child(top_texture)


