extends Node2D

signal coat

var flavors = []

func _ready():
	if flavors.is_empty():
		flavors = Globals.get_inventory("popcorn sauce").keys()
	var i = 0
	for node in get_children():
		node.mouse_entered.connect(get_parent().get_parent()._mouse_entered)
		node.mouse_exited.connect(get_parent().get_parent()._mouse_exited)
		node.coat.connect(_coated)
		node.set_flavor(flavors[i])
		i += 1
		
func _coated(flavor, amount):
	emit_signal("coat", flavor, amount)




