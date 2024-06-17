extends MouseTail

# Eye mouse tail: 
	# Spider eye: right click, burst of eye spiders crawl away from mouse

var spider_eye
# On right click, show spider eye effect

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	spider_eye = CPUParticles2D.new()
	spider_eye.explosiveness=.8
	spider_eye.amount = 15
	spider_eye.lifetime = 1.5
	spider_eye.lifetime_randomness = 1
	spider_eye.initial_velocity_min = 300
	spider_eye.spread = 45
	spider_eye.emitting = false
	spider_eye.texture = load("res://UI/mouse_tail2_effect.tres")
	spider_eye.gravity = Vector2(0, 0)
	add_child(spider_eye)

func _input(event):
	if event.is_action_pressed("right-click"):
		if spider_eye != null:
			spider_eye.global_position = get_global_mouse_position()
			spider_eye.direction = -mouse_velocity
			spider_eye.emitting = true
	
	super._input(event)

func _on_particle_timer_timeout():
	if spider_eye.emitting:
		spider_eye.emitting = false
	super._on_particle_timer_timeout()
