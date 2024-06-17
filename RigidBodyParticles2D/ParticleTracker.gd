extends Node2D

var particle
var lifetime
var impulse_angle
var impulse
var force_angle
var force
var initial_rotation

## VIRTUAL METHODS

func _ready():
	$Remover.wait_time = lifetime
	$Remover.connect("timeout",Callable(self,"_on_remover_timeout"))
	$Remover.start()

	var impulse_angle_rad    = deg_to_rad(impulse_angle + global_rotation_degrees)
	var impulse_angle_vector = Vector2( cos(impulse_angle_rad), sin(impulse_angle_rad) ).normalized()
	particle.apply_impulse(impulse_angle_vector * impulse, Vector2(0,0))

	var force_angle_rad    = deg_to_rad(force_angle + global_rotation_degrees)
	var force_angle_vector = Vector2( cos(force_angle_rad), sin(force_angle_rad) ).normalized()
	particle.apply_force(force_angle_vector * force, Vector2(0,0))

	particle.rotation_degrees = initial_rotation


## PRIVATE METHODS

func _on_remover_timeout():
	particle.queue_free()
