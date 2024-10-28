extends Node2D

var HORIZONTAL_SPEED = 150
var SPRING_CONSTANT=5
var MASS = .1
var MAX_COMPRESSION = 10
var BARREL_LENGTH = 7

var compression_increment = 3
var compression_distance = 0
var is_launched = false
var is_lit = false
var current_frame = 10



func set_frame(direction):
	var frames =$Sprite2D.sprite_frames
	match direction:
		"down":
			if frames.get_frame_count("move") > current_frame+1:
				$Sprite2D.set_frame(current_frame + 1)
				current_frame += 1
		"up":
			if current_frame > 0:
				$Sprite2D.set_frame(current_frame - 1)
				current_frame -= 1
			
func get_force(theta):
	var total_force = (5*(SPRING_CONSTANT * pow(compression_distance, 2)) / 2 * BARREL_LENGTH)
	return Vector2(0, -total_force*sin(theta))
	
func get_depth_velocity(theta):
	var total_force = ((SPRING_CONSTANT * pow(compression_distance, 2)) / 2 * BARREL_LENGTH)
	return total_force*cos(theta)

