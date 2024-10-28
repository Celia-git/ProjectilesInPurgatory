extends Scenes

class_name ExteriorScenes

signal change_overworld_setting

#Overworld map

var background_path = "res://Assets/Backgrounds/"
var icon_texture_path = "res://UI/OverworldIcons/"

var map_data=null
var arrow_data = null
var portal_data = null
var mouse_moving

func _input(event):
	if event is InputEventMouseMotion and event.relative:
		$Control.visible = true
		mouse_moving = true
		$ToggleControlsTimer.stop()
	else:
		mouse_moving = false
		$ToggleControlsTimer.start()

# Set data for this map
func load_map(index):
	
	clear_ui_nodes()
	
	map_data = Globals.boardwalk_script.new(index)
#	arrow_data = map_data.get_arrow_data() 
	portal_data = map_data.get_portal_data()
	
#	# create arrows on boardwalk map
#	for dict in arrow_data:
#		# Create Texture buttons and attach arrow script, connect to arrow signals
#		var arrow_node = Globals.boardwalk_arrow_script.new(dict["direction"], dict["position"], dict["destination"])
#		arrow_node.add_to_group("ui_nodes")
#		$Control.add_child(arrow_node)
#		arrow_node.mouse_entered.connect(_on_button_mouse_entered)
#		arrow_node.mouse_exited.connect(_on_button_mouse_exited)
#		arrow_node.pressed.connect(_on_arrow_pressed.bind(dict["destination"]))

	# Add portals to map
	for dict in portal_data:			
		if !(dict.is_empty() || index==2):
			var portal_node = Globals.boardwalk_portal_script.new(index, dict["overworld_index"])
			portal_node.add_to_group("ui_nodes")
			portal_node.mouse_entered.connect(_on_button_mouse_entered)
			portal_node.mouse_exited.connect(_on_button_mouse_exited)
			portal_node.pressed.connect(_on_portal_pressed.bind(dict["destination"], dict["subgame"]))
			
			$Control.add_child(portal_node)

	# Load Background Image
	$ParallaxLayer/Background.texture = map_data.get_background_texture()
	
	
#
#func _on_arrow_pressed(destination:int):
#	emit_signal("change_overworld_setting", destination)

func _on_portal_pressed(destination:int, subgame:int):
	emit_signal("enter_portal", destination, subgame)
		
		
		
	

func clear_ui_nodes():
	for child in $Control.get_children():
		if child.is_in_group("ui_nodes"):
			child.queue_free()


func _on_toggle_controls_timer_timeout():
	$Control.visible = mouse_moving
