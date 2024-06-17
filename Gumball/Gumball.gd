extends RigidBody2D

signal add_new_item


var color:Color
var color_name:String
var audio:AudioStreamPlayer
var item_name:String = "gumball_"
var gumball_sprite_texture = load("res://Games/Resources/cannonball.tres")
var phys_material = load("res://Gumball/gumball_material.tres")

func _init(color:Color, color_name):
	self.color = color
	self.color_name = color_name
	self.item_name = self.item_name + color_name
	self.contact_monitor = true
	self.max_contacts_reported = 12
	self.mass = .2
	self.input_pickable = true
	self.body_entered.connect(_on_body_entered)
	physics_material_override = phys_material

# Called when the node enters the scene tree for the first time.
func _ready():	
	var sprite = Sprite2D.new()
	sprite.texture = gumball_sprite_texture
	sprite.modulate = color
	sprite.set_scale(Vector2(3,3))

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = gumball_sprite_texture.get_height()
	collision.shape = shape
	collision.set_scale(Vector2(3, 3))
	
	audio = AudioStreamPlayer.new()
	audio.bus = "Sound Effect"
	audio.stream = Globals.get_audio_stream("gumball_bounce")
	
	add_child(sprite)
	add_child(collision)
	add_child(audio)
	apply_central_impulse(Vector2(randi_range(-50, 50), -150))


func _input(event):
	if event.is_action_pressed("click"):
		emit_signal("add_new_item", item_name)
		call_deferred("queue_free")

func _on_body_entered(body):
	if body.is_in_group("ground"):
		audio.playing = true
		audio.volume_db -= 1
	
