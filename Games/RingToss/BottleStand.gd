extends Node2D
signal enter_layer
signal exit_layer

@onready var stand_children = $Stand0.get_children()+$Stand1.get_children()+$Stand2.get_children()


func _ready():
	var idx=0
	for node in stand_children:
		if node.is_in_group("Bottle"):
			node.set_meta("index", idx)
			# connect to signals
			if !node.get_node("Clear").body_entered.is_connected(_body_entered_clear):
				node.get_node("Clear").body_entered.connect(_body_entered_clear)
			if !node.body_exited.is_connected(_body_exited_clear):
				node.body_exited.connect(_body_exited_clear)
			idx += 1

func get_bottles():
	var bottles = []
	for node in stand_children:
		if node.is_in_group("Bottle"):
			bottles.append(node)
	return bottles

func set_bottle_textures(bottle_textures):
	for node in stand_children:
		if node.is_in_group("Bottle"):
			randomize()
			var texture = bottle_textures[randi_range(0, bottle_textures.size()-1)]
			node.get_node("Sprite2D").set_texture(texture)

func get_target_position(index):
	
	for child in stand_children:
		if child.is_in_group("Bottle"):
			if child.get_meta("index")==index:
				return child.get_global_position()

func _body_entered_clear(body):
	if body.is_in_group("rings"):
		emit_signal("enter_layer")
		
func _body_exited_clear(body):
	if body.is_in_group("rings"):
		emit_signal("exit_layer")
