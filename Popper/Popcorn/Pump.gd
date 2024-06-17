extends Node2D

signal mouse_entered
signal mouse_exited
signal coat

@onready var max_y = 30
var y = 0
var MAX_COMPRESSION_INC = 40
var COMPRESSION_CHANGE = 30.0
const FLOW = 5
@onready var compression_increment = MAX_COMPRESSION_INC
var is_focused = false
var is_pressed = false
@export var flavor:String
var icon_texture

# Whether or not pump is compressed
var compressed = false
var flow_begin = false
var syrup_quantity = 0


func _ready():
	if icon_texture != null:
		$Icon.texture = icon_texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	is_pressed=is_focused
	if is_focused:
		is_pressed = Input.is_action_pressed("click")
	
	if flow_begin:
		syrup_quantity += FLOW*delta
	
	if is_pressed:
		if Input.is_action_pressed("click") && y < max_y:
			# Compress
			y += compression_increment*delta
			# Adjust compression increment
			if compression_increment > .01:
				compression_increment -= (COMPRESSION_CHANGE*delta)
				
	elif !is_pressed && y >0:
		# Decompress
		y -= compression_increment*delta
		if compression_increment < MAX_COMPRESSION_INC:
			compression_increment += (COMPRESSION_CHANGE*delta)
			

	compressed = $PumpingAnimation.frame > 15
	var pframe = $PumpingAnimation.frame
	# if compressed: play syrup animation
	if compressed && !$Syrup.is_playing():
		$Syrup.play("start_drip")
	elif compressed==false && flow_begin==true:
		$Syrup.play("end_drip")
		flow_begin=false
	
	$PumpingAnimation.frame = int(y)

func set_flavor(flavor):
	self.flavor = flavor
	$Syrup.set_self_modulate(Globals.get_color(flavor))



func _on_area_2d_mouse_entered():
	is_focused=true
	emit_signal("mouse_entered")


func _on_area_2d_mouse_exited():
	is_focused=false
	emit_signal("mouse_exited")



func _on_syrup_animation_finished():
	if $Syrup.animation=="start_drip":
		$Syrup.play("flow")
		flow_begin=true	
	elif $Syrup.animation=="end_drip":
		emit_signal("coat", flavor, syrup_quantity/10.0)
		$Syrup.animation = "default"
