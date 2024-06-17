extends CharacterBody2D


@onready var height = 180
@onready var width = 320

var speed = 75
var min_rotation = -2*PI/3
var max_rotation = PI/6
var rotation_speed = 2*PI

# Free Movement controls
func _physics_process(delta):
	
	if Input.is_action_pressed("left") && position.x>0:
		position.x -= (speed*delta)
	if Input.is_action_pressed("up") && position.y>0:
		position.y -= (speed*delta)
	if Input.is_action_pressed("down") && position.y<height:
		position.y += (speed*delta)
	if Input.is_action_pressed("right") && position.x<width:
		position.x += (speed*delta)

	if Input.is_action_pressed("ui_left") && rotation < max_rotation:
		rotation += rotation_speed*delta
	elif Input.is_action_pressed("ui_right") && rotation > min_rotation:
		rotation -= rotation_speed*delta
		
