extends StaticBody2D

signal hit_target
var speed

var first_direction
var time

# Animate ships
func _on_shelf_child_entered_tree(node):
	
	if node.is_in_group("Targets"):
		node.set_meta("direction", first_direction)
		animate_ship(node)

# Set a new amount of time for one cycle
func _reset_time():
	time = float(speed)* .08
	var randomize = time*randf_range(-.2, .2)
	time += randomize
	
func animate_ship(ship):
	
	
	var tween = create_tween()
	
	match ship.get_meta("direction"):
		"left":
			var target = ship.get_meta("left_bound")+randi_range(0, 10)
			tween.tween_property(ship, "position:x", ship.get_meta("left_bound"), time).set_trans(Tween.TRANS_CIRC)
			tween.tween_callback(animate_ship.bind(ship))
			tween.tween_interval(time)
			ship.set_meta("direction", "right")
		
		"right":
			var target = ship.get_meta("right_bound")-randi_range(0, 10)
			tween.tween_property(ship, "position:x", ship.get_meta("right_bound"), time).set_trans(Tween.TRANS_CIRC)
			tween.tween_callback(animate_ship.bind(ship))
			tween.tween_interval(time)
			ship.set_meta("direction", "left")
		

func get_ship_rects():
	var rects = []
	for node in get_children():
		if node.is_in_group("Targets"):
			var rect = node.get_node("CollisionShape2D").shape.get_rect()
			rect.position += node.position + position
			rect.position.y -= 4
			rects.append(rect)
	return rects
	
func get_ship(index):
	var idx = 0
	for node in get_children():
		if node.is_in_group("Targets"):
			if idx == index:
				return node
			idx += 1
			

