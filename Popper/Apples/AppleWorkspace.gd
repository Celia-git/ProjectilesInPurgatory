extends Node2D


signal add_player_inventory
signal add_player_tickets
signal display_text
signal carry_over
signal carry_back
signal mouse_entered
signal mouse_exited
signal shift_right
signal shift_left


var current_workspace = "Pots"
@onready var areas = [$Pots/CaramelPot, $Pots/CandyPot, $AppleStand, $Toppings]
@onready var candy_ripples = $Pots/CandyPot/Ripples
@onready var caramel_ripples = $Pots/CaramelPot/Ripples
var image_filename = "Popper.png"
var selected_apple

var game_states=Globals.game_states

func _ready():
	$AppleStand.areas = areas
	$AppleStand.add_apples()

func _input(event):
	
	# Prevent deselecting when an animation is currently happening
	if event.is_action_pressed("right-click") && selected_apple:
		if selected_apple.can_be_released():
			selected_apple.holding=false
			$AppleStand.animate_entry(selected_apple)
			selected_apple=null
		
		elif selected_apple.rolling:
			selected_apple.cancel_roll()
			await selected_apple.roll_over
			selected_apple.holding=true
			selected_apple.rolling=false
		
	if event.is_action_pressed("click") && selected_apple && !selected_apple.dipping && !selected_apple.rolling:
		var area = selected_apple.current_area
		match area:
			"CandyPot":
				if selected_apple.coating:
					return
				candy_ripples.visible = true
				candy_ripples.set_animation("RipplesCandy")
				candy_ripples.set_frame(0)
				candy_ripples.offset = selected_apple.position-$Pots/CandyPot.position + Vector2(0, 40)
				candy_ripples.play()
				selected_apple.dip()
				await candy_ripples.animation_finished
				selected_apple.undip("Candy")
				candy_ripples.play_backwards("RipplesCandy")
				await selected_apple.dip_over
				selected_apple.add_to_group("sticky")
				candy_ripples.set_animation("default")
				candy_ripples.visible=false
			"CaramelPot":
				if selected_apple.coating:
					return
				caramel_ripples.visible = true
				caramel_ripples.set_animation("RipplesCaramel")
				caramel_ripples.set_frame(0)
				caramel_ripples.offset = selected_apple.position-$Pots/CaramelPot.position + Vector2(0, 40)
				caramel_ripples.play()
				selected_apple.dip()
				await caramel_ripples.animation_finished
				selected_apple.undip("Caramel")
				caramel_ripples.play_backwards("RipplesCaramel")
				await selected_apple.dip_over
				selected_apple.add_to_group("sticky")
				caramel_ripples.set_animation("default")
				caramel_ripples.visible=false
				
			"AppleStand":
				if selected_apple.can_be_released():
					selected_apple.holding=false
					$AppleStand.animate_entry(selected_apple)
					selected_apple=null
			null:
				pass
			_:
				if area.begins_with("Toppings"):
					if selected_apple.coating:
						selected_apple.toppings()
						await selected_apple.roll_over
			
				
	# Roll apple with up/down scroll controls
	elif event.is_action_pressed("scroll_up") && selected_apple:
		if selected_apple.rolling:
			selected_apple.roll("up")
	elif event.is_action_pressed("scroll_down") && selected_apple:
		if selected_apple.rolling:
			selected_apple.roll("down")

func _select_apple(apple, select=true):
	if select and selected_apple==null:
		$AppleStand.apples_on_stand.erase(apple)
		selected_apple = apple
		selected_apple.shift_to_area(current_workspace)
		selected_apple.holding=true
		
		
func _shift_left():
	if current_workspace=="Toppings":
		emit_signal("shift_left")
		var tween = create_tween()
		tween.tween_property($Pots, "modulate", Color(1, 1, 1, 1), 1).set_trans(Tween.TRANS_SINE).from(Color(1, 1, 1, 0))
		$AnimationPlayer.play("shift_to_pots")
		await $AnimationPlayer.animation_finished
		if selected_apple:
			selected_apple.shift_to_area("Pots")
		current_workspace="Pots"
	
func _shift_right():
	if current_workspace=="Pots":
		emit_signal("shift_right")
		var tween = create_tween()
		tween.tween_property($Toppings, "modulate", Color(1, 1, 1, 1), 1).set_trans(Tween.TRANS_SINE).from(Color(1, 1, 1, 0))
		$AnimationPlayer.play("shift_to_toppings")
		await $AnimationPlayer.animation_finished
		if selected_apple:
			selected_apple.shift_to_area("Toppings")
		current_workspace="Toppings"
	
func _pass_apple_top():
	if selected_apple:
		selected_apple.set_physics_process(false)
		await $AppleStand.carry_over(selected_apple)
		emit_signal("carry_over", selected_apple, selected_apple.get_meta("last_position"))
		selected_apple=null
		
func dialog_finished():
	pass


func _mouse_entered():
	emit_signal("mouse_entered")

func _mouse_exited():
	emit_signal("mouse_exited")



func _trash_apple():
	if selected_apple:
		$TrashWarning.popup_centered()
		

func _on_trash_confirm_pressed():
	selected_apple.queue_free()
	selected_apple = null
	$TrashWarning.visible=false

func _on_trash_cancel_pressed():
	$TrashWarning.visible=false


func _on_child_entered_tree(node):
	if node.is_in_group("apples"):
		node.call_deferred("reparent", $AppleStand)
		$AppleStand._carry_back(node, current_workspace)

		
	
func _on_shift_workspace_mouse_shape_entered(shape_idx):
	match shape_idx:
		0: #(left)
			$ShiftWorkspace/Left.visible=true
		1: #Right
			$ShiftWorkspace/Right.visible=true
	emit_signal("mouse_entered")		

func _on_shift_workspace_mouse_shape_exited(shape_idx):
	
	match shape_idx:
		0: #(left)
			$ShiftWorkspace/Left.visible=false
		1: #Right
			$ShiftWorkspace/Right.visible=false
	emit_signal("mouse_exited")


func _on_left_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		_shift_left()
	

func _on_right_input_event(viewport, event, shape_idx):
	if event.is_action_pressed("click"):
		_shift_right()



func _on_animation_player_animation_finished(anim_name):
	$ShiftWorkspace/Left.visible = false
	$ShiftWorkspace/Right.visible = false
