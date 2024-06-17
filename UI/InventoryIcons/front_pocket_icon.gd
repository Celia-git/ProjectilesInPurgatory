extends TextureButton

class_name FrontPocketIcon

signal consume_me

var item_name
# Data related to consumable items: ie prizes for treasure chest, pictures for envelopes, etc
var item_data = {}

func _init(item_name:String, consumable:Dictionary, normal:Texture2D, hover:Texture2D, pressed:Texture2D):
	self.item_name = item_name
	self.consumable_data = consumable
	self.texture_normal = normal
	self.texture_hover = hover
	self.texture_pressed = pressed
	self.size_flags_horizontal = Control.SIZE_EXPAND
	self.size_flags_vertical = Control.SIZE_EXPAND
	self.scale = (Vector2(3,3))


func _on_self_pressed():
	emit_signal("consume_me", self)
