extends TextureButton

# Arrow to scrub between overworld boardwalk maps

const BACKGROUND_PATH = "res://Assets/Backgrounds/Boardwalk/"
const ICON_PATH = "res://UI/OverworldIcons/"
var destination:int
var direction:String


# Dir is direction of arrow, Click is rect for click area, dest is destination map idx
func _init(dir:String, pos:Vector2, dest:int):
	direction=dir
	destination = dest
	position = pos
	var texture_types = direction.split("_")
	var load_texture_name = ""
	for type in texture_types:
		match type:
			"back":
				load_texture_name += "_forward"
				flip_v = true
				
			"left":
				load_texture_name += "_right"
				flip_h = true
			_:
				load_texture_name += "_" + type
				
	load_texture_name = load_texture_name.trim_prefix("_")
	
	for button_type in ["_normal.tres", "_hover.tres", "_pressed.tres"]:
		var texture = load(ICON_PATH+load_texture_name+button_type)
		
		match button_type:
			"_normal.tres":
				set_texture_normal(texture)
			"_hover.tres":
				set_texture_hover(texture)
			"_pressed.tres":
				set_texture_pressed(texture)
				
	scale = Vector2(3, 3)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
