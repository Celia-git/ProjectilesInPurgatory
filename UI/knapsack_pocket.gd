extends Control

class_name KnapsackPocket

var icon_path = "res://UI/InventoryIcons/"
var held_icon = null
var container

func _ready():
	set_container()


func _process(delta):
	if held_icon != null:
		
		if held_icon.pressed:
			held_icon.global_position.lerp(get_global_mouse_position(), held_icon.drag_speed * delta)
		else:
			drop(held_icon)	

# Add Player inventory icons to tab
func add_icons(icon_array):
	if container==null:
		set_container()
	for icon in icon_array:
		icon.add_to_group("prize_icons")
		if !(icon in container.get_children()):
			container.add_child(icon)
		
		if !icon.pressed.is_connected(_pick_up):
			icon.pressed.connect(_pick_up.bind(icon))

# Set Container variable to relative container node which holds inventory icons 
func set_container():
	return

# Called each time player toggles inventory open OR gains/uses an item while knapsack open  
func _load_container_icons():
	return
	
func increment_position(atlas_position:Vector2, image_size:Vector2, image_step:Vector2):
	# Increment position
	if (atlas_position.x + image_step.x) > image_size.x:
		atlas_position.y += image_size.y
		atlas_position.x = 0
	else:
		atlas_position.x += image_step.x
		
	return atlas_position
	
# Remove icon from container, set as held icon
func _pick_up(icon_node):
	if icon_node.get_parent()==container:
		icon_node.reparent(self)
		held_icon = icon_node
	
# Add icon to container, set held icon as null
func drop(icon_node):
	if icon_node != null:
		if icon_node.get_parent()==self:
			icon_node.reparent(container)
		if held_icon==icon_node:
			held_icon=null

