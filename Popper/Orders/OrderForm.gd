extends VBoxContainer

signal submit_order
signal recind_order
signal order_failed

var ICONSIZE = Vector2(75, 75)
var TAB_SIZE = Vector2(32, 32)
var header_hbox = HBoxContainer.new()
var expand_button = TextureButton.new()
var submit_button = TextureButton.new()
var late_icon = TextureRect.new()
var labels



# values = {label:icon}
func set_values(values):

	labels = values.keys()
	
	# Header: no indent
	
	expand_button.toggle_mode=true
	expand_button.texture_normal = Globals.get_order_icon("CollapseSmall")
	expand_button.texture_pressed = Globals.get_order_icon("ExpandSmall")
	expand_button.toggled.connect(_on_expand_pressed)
	
	var heading_label = Label.new()
	heading_label.set_label_settings(load(Globals.order_label_settings))
	heading_label.text = labels[0]+":\n"
	
	late_icon.texture = Globals.get_order_icon("Late")
	late_icon.visible = get_meta("late")
	
	submit_button.texture_normal = Globals.get_order_icon("Submit")
	submit_button.texture_hover = Globals.get_order_icon("SubmitFocused")
	submit_button.texture_pressed = Globals.get_order_icon("SubmitPending")
	submit_button.toggle_mode = true
	submit_button.toggled.connect(_submit_order)
	
	var trash_button = TextureButton.new()
	trash_button.texture_normal= Globals.get_order_icon("Trash")
	trash_button.pressed.connect(_trash_order)
	
	if values[labels[0]]:
		var icon_texture = Globals.get_inventory("")
		var heading_texture = TextureRect.new()
		heading_texture.texture = values[labels[0]]
		heading_texture.set_stretch_mode(TextureRect.STRETCH_KEEP)
		header_hbox.add_child(heading_texture)
		
	header_hbox.add_child(expand_button)
	header_hbox.add_child(heading_label)
	header_hbox.add_child(submit_button)
	header_hbox.add_child(late_icon)
	header_hbox.add_child(trash_button)
	header_hbox.set_meta("header", true)
	add_child(header_hbox)
	

	for i in range(1, values.size()):
		var hbox = HBoxContainer.new()
		hbox.add_child(get_spacer_label())
		var lab = Label.new()
		lab.set_label_settings(load(Globals.order_label_settings))
		lab.text = labels[i]
		if values[labels[i]]:
			var texture = TextureRect.new()
			texture.texture = values[labels[i]]
			texture.set_stretch_mode(TextureRect.STRETCH_KEEP)
			hbox.add_child(texture)
		hbox.add_child(lab)
		hbox.set_meta("header", false)
		add_child(hbox)
	set_size(Vector2(400, TAB_SIZE.y*get_child_count()))
	
			
func get_values():
	return labels

func _collapse():
	for child in get_children():
		if child is Timer:
			continue
		if child.has_meta("header"):
			child.visible = child.get_meta("header")
		else:
			child.visible = false
	expand_button.set_pressed_no_signal(true)
			
func _expand():
	for child in get_children():
		if child is Timer:continue
		child.visible = true
	expand_button.set_pressed_no_signal(false)

func _on_expand_pressed(toggle_on):
	if toggle_on:
		_collapse()
	else:
		_expand()

func _submit_order(toggle_on):
	if toggle_on:
		emit_signal("submit_order")
	else:
		_recind_order()
	
func _recind_order():
	emit_signal("recind_order")

func _trash_order():
	if submit_button.button_pressed:
		_recind_order()
	emit_signal("order_failed")
	call_deferred("queue_free")

func get_spacer_label():
	var label = Label.new()
	label.custom_minimum_size = TAB_SIZE
	return label

func _on_timer_timeout():
	set_meta("late", true)
	late_icon.visible=true
