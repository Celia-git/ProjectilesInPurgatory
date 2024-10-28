extends ParallaxLayer

var speed = 25
var direction = Vector2(-.12, 1)


func _ready():
	if !visibility_changed.is_connected(_visibility_changed):
		visibility_changed.connect(_visibility_changed)

func _process(delta):
	var x = speed*delta
	motion_offset += x*direction


func _visibility_changed():
	set_process(visible)
