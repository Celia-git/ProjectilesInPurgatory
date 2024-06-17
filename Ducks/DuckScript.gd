extends Node


static func get_amount(level:int):
	return [18, 24, 32][level-1]

static func get_combos(level:int):	#match_idx: max half the amount
	var colors = ["red", "yellow", "green", "blue"]
	var shapes = ["square", "circle", "triangle", "diamond"]
	var combos_amount = [Vector2(3, 3), Vector2(4,3), Vector2(4,4)][level-1]
	var combos = []
	for x in range(combos_amount.x):
		for y in range(combos_amount.y):
			combos.append([colors[x], shapes[y]])
	return combos

static func get_duck_shape(color_shape:Array):
	var image_file = "res://Assets/Ducks.png"
	var atlas = AtlasTexture.new()
	atlas.atlas = load(image_file)
	var x_value = 48 + (16*["red", "yellow", "green", "blue"].find(color_shape[0]))
	var y_value = 16 * ["square", "circle", "triangle", "diamond"].find(color_shape[1])
	atlas.set_region(Rect2(Vector2(x_value, y_value), Vector2(16,16)))
	return atlas
