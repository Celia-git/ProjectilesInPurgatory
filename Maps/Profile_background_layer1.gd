extends ParallaxLayer

signal start_timer

@export var speed = 50
var idx = 0
var height = 900
var width = 1600
var slope = 1.0
var slopes = {
	"Ducks":3.0,
	"Candy":.48,
	"Balloons":.555
}
var sign = 1


func _ready():

	if !visibility_changed.is_connected(_visibility_changed):
		visibility_changed.connect(_visibility_changed)
	idx = int(name.right(1))
	sign = [1, -1][idx-1]

func _process(delta):
	var x = speed*delta
	motion_offset += Vector2(x, sign*(slope*x))
	if abs(motion_offset.x) >= 2*width:
		if idx==2:
			sign *= -1 
			emit_signal("start_timer")
			motion_offset.x = 0


func start_cycle():
	if idx == 1:
		sign *= -1

func _on_sprite_2d_texture_changed():
	var texture_name = $Sprite2D.texture.get_meta("name")
	slope = slopes[texture_name]


func _visibility_changed():
	set_process(visible)
