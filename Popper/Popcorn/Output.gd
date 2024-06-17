extends StaticBody2D

signal add_bag
signal delete_bag
signal button_mouse_exited
signal button_mouse_entered

# Tells Workspace to add bag or tells canvas to delete current bag


func _on_mouse_exited():
	emit_signal("button_mouse_exited")


func _on_mouse_entered():
	emit_signal("button_mouse_entered")


func _on_new_bag_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		emit_signal("add_bag")


func _on_trash_bag_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		emit_signal("delete_bag")
