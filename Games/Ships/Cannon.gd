extends Node2D

signal launch
signal lit_progress
const TOTAL_FORCE = 1000.0
const HORIZONTAL_SPEED =150
var BURN_TIME 
var MASS = 1
var OFFSETS = [28, 24, 20]

var is_launched = false
var is_lit = false



func _on_timer_timeout():
	$Light.visible = false
	is_lit = false
	emit_signal("launch")
	is_launched = true

func start_timer():
	$Light.visible = true
	$Light.play("default")
	$Timer.start()
	
func get_time():
	return $Timer.time_left 

func move_down():
	$Sprite2D.frame += 1
	$Light.offset.y = OFFSETS[$Sprite2D.frame]
	
func move_up():
	$Sprite2D.frame -= 1
	$Light.offset.y = OFFSETS[$Sprite2D.frame]
