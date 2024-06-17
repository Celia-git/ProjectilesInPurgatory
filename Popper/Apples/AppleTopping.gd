extends Area2D

signal add_me
@onready var self_image = Image.create(10, 10, false, Image.FORMAT_RGBA8)
var flavor

func _ready():
	set_rotation(randi_range(0, 360))

		
func set_texture(atlas):
	
	$Sprite2D.texture = atlas
	var image = atlas.get_image()
	for x in image.get_size().x:
		for y in image.get_size().y:
			# Copy only values in the bottom-center
			if (3 < x and x < 13) and (6 < y and y < 16):
				self_image.set_pixelv(Vector2i(x-3, y-6), image.get_pixelv(Vector2i(x,y)))

				
func _on_body_entered(body):
	if body.is_in_group("sticky"):
		#var offset = Vector2i(global_position - body.global_position)
		var offset = Vector2i(randi_range(-16, 16), randi_range(0, 32))
		if !is_connected("add_me", body.add_to_self):
			add_me.connect(body.add_to_self)
		emit_signal("add_me", self_image, offset, self)
