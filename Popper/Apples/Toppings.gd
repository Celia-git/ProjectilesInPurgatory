extends Node2D


@onready var topping_scene = "res://Popper/Apples/AppleTopping.tscn"
var topping_names = []
var topping_icons = []
var topping_textures = []
var AMOUNT = 100
	
func _ready():
	
	# Load toppings images
	var all_flavors = Globals.get_inventory("apple topping")
	for flavor in all_flavors.keys():
		topping_names.append(flavor)
		topping_textures.append(all_flavors[flavor][0])
		topping_icons.append(all_flavors[flavor][1])
			
	# Add toppings to tins
	var shapes = get_shapes()
	var area_idx = 0
	for shape in shapes:
		# Create new sign for this topping
		var text = Sprite2D.new()
		text.texture = topping_icons[area_idx]
		text.scale = Vector2(.25, .25)
		get_child(area_idx).add_child(text)
		text.position = get_child(area_idx).position + shape.position
		text.position.x -= 20
				
		for i in AMOUNT:
			# Create new topping piece and set texture
			var topping = load(topping_scene).instantiate()
			get_child(area_idx).add_child(topping)
			topping.set_texture(topping_textures[area_idx])
			topping.flavor=topping_names[area_idx]
			
			# Put piece in topping tray
			var set_pos = Vector2()
			while !shape.has_point(abs(set_pos)):
				set_pos = Vector2(randf_range(shape.position.x, shape.end.x), 
				randf_range(shape.position.y, shape.end.y))
			topping.position = set_pos
		
		area_idx += 1
	
	
	
# Return Rect2 objects which cover the area 2Ds associated with toppings areas
func get_shapes():
	var shapes = []
	for child in get_children():
		var area_node = child.get_node("CollisionShape2D")
		var o = area_node.position
		var dim = area_node.shape.size 
		var pos = Vector2(o.x - (dim.x/2), o.y - (dim.y/2))
		var rect = Rect2(pos, dim)
		shapes.append(rect)
		
	return shapes


func _on_toppings_draw():
	var shape = get_shapes()
	for rect in shape:
		rect.position += Vector2(rect.size.x/3, rect.size.y/5)
		draw_rect(rect, Color(0, 0, 1, 1), false, 1)
