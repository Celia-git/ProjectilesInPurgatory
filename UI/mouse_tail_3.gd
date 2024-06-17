extends MouseTail

signal add_to_canvas

# Star Mouse Trail:
	# line 2D connects the dots between mouse resting points
@onready var gradient = load("res://UI/mouse_tail_star_gradient.tres")
@onready var line = Line2D.new()
var distance=0

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	line.gradient = gradient
	line.gradient.reverse()
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.width = 10
	emit_signal("add_to_canvas", line)


func _input(event):

	# activate mouse trail
	if (event is InputEventMouseMotion):
		if !emitting:
			emitting = true 
			set_process(true)

		if line != null:
			line.add_point(get_global_mouse_position()+OFFSET, line.get_point_count())
			if distance > 3*amount:
				line.remove_point(0)

		mouse_velocity = event.relative
		

func _on_particle_timer_timeout():
	super._on_particle_timer_timeout()
	var line_a = line.get_point_position(0)
	var line_b = line.get_point_position(line.get_point_count()-1)
	distance = line_a.distance_to(line_b)
	
	
	
