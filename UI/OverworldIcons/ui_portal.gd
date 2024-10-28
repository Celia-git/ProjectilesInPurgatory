extends TextureButton



var portals_path = "res://Assets/portals_%d_%d"		#	% map_index, portal_index 
var click_mask_path = "_click_mask.bmp"
var shine_frame_count = 5

var map_index:int		# index of boardwalk map this poral is on
var overworld_index:int	# index of this portal among others on the map (l->r)


func _init(map_idx, overworld_idx):

	self.overworld_index = overworld_idx
	self.map_index = map_idx
	set_textures()
	
	scale = Vector2(3, 3)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func set_textures():
	var prefix = portals_path % [map_index, overworld_index]
	var hover_anim = AnimatedTexture.new()
	hover_anim.speed_scale = 6
	hover_anim.frames = shine_frame_count
	for i in range(shine_frame_count):
		var texture = load(prefix + "_shine%d.png" % [i])
		hover_anim.set_frame_texture(i, texture)
	
	self.texture_pressed = load(prefix+".png")	
	self.texture_hover = hover_anim
	self.texture_click_mask = load(prefix+"_click_mask.bmp")
