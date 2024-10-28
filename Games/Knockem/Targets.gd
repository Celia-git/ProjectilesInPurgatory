extends Node2D

var TARGET_RADIUS=10

var HEIGHT=0
var WIDTH=0
var ROWS=3
var COLUMNS=6
var impact_frames = load("res://Games/Resources/impact_frames.tres")




# Create targets: argument is image atlases
func create_targets(item_atlases, item_data):
	
	# Load sprite frames
	var target_images = []
	var sprite_amount = item_data["Targets"][3]
	var frame_amount = item_data["Targets"][2]
	for s in range(sprite_amount): # Iterate amount of sprites
		var frames = SpriteFrames.new()
		frames.add_animation("knockdown")
		frames.set_animation_loop("knockdown", false)
		for f in range(frame_amount): #Iterate amount of frames
			var current_index = (s*frame_amount+f)
			frames.add_frame("knockdown", item_atlases[current_index])
		target_images.append(frames)

	@warning_ignore("integer_division")
	var y_increment=HEIGHT/(ROWS+1)
	@warning_ignore("integer_division")
	var x_increment=WIDTH/(COLUMNS+1) 
	@warning_ignore("integer_division")
	var buffer = Vector2(WIDTH/25, HEIGHT/8)
	for h in range(1, ROWS+1):
		for w in range(1, COLUMNS+1):
			var area = Area2D.new()
			var collision = CollisionShape2D.new()
			collision.shape = CircleShape2D.new()
			collision.shape.radius= TARGET_RADIUS
			
			area.input_pickable=true
			area.set_meta("Row", h)
			area.set_meta("Column", w)
			area.add_child(collision)
			var animated_sprite = AnimatedSprite2D.new()
			var impact_sprite = AnimatedSprite2D.new()
			animated_sprite.name = "animated_sprite"
			impact_sprite.name= "impact_sprite"
			randomize()
			animated_sprite.frames = target_images[randi_range(0, target_images.size()-1)]
			animated_sprite.speed_scale = 5
			animated_sprite.animation = "knockdown"
			animated_sprite.frame = 0
			animated_sprite.animation_finished.connect(_on_knockdown_animation_finished.bind(area))

			impact_sprite.frames = impact_frames
			impact_sprite.visible = false
			impact_sprite.animation_finished.connect(_on_impact_animation_finished.bind(area))
			area.add_child(animated_sprite)
			area.add_child(impact_sprite)
			area.add_to_group("Targets")
			
			add_child(area)
			area.position = Vector2(buffer.x+(w*x_increment), (HEIGHT-(h*y_increment)-buffer.y))


func hit_target(hitbox):
	for child in get_children():
		if child.is_in_group("Targets"):
			if hitbox in child.get_overlapping_areas():
				play_hit_target(child)
				return Vector2(child.get_meta("Row"), child.get_meta("Column"))
	
	
	
func play_hit_target(target):
	randomize()
	target.get_node("impact_sprite").play(["impact1", "impact2"][randi_range(0,1)])
	target.get_node("impact_sprite").visible = true
	target.get_node("animated_sprite").play("knockdown")

func _on_knockdown_animation_finished(target):
	await get_tree().create_timer(1).timeout
	target.get_node("animated_sprite").frame = 0

func _on_impact_animation_finished(target):
	target.get_node("impact_sprite").visible = false

