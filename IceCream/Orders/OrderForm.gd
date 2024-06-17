extends VBoxContainer

var TAB_SIZE = 48
var expanded = true

# Displays one order
		
func set_form(order_form):
	

	var textures = Globals.texture_script.new()
	
	
	# Header: no indent
	var expand_button = Button.new()
	expand_button.text = "*"
	expand_button.pressed.connect(_on_expand_pressed)
	var heading_label = Label.new()
	var heading_texture = TextureRect.new()
	heading_label.set_label_settings(load(Globals.order_label_settings))
	heading_label.text = order_form.item_type+":\n"
	heading_texture.texture = textures.get_atlas_all_args("iconsheet.png", order_form.icon_positions[0], order_form.ICONSIZE)
	heading_texture.set_stretch_mode(TextureRect.STRETCH_KEEP)
	
	var header_hbox = HBoxContainer.new()
	header_hbox.add_child(heading_texture)
	header_hbox.add_child(heading_label)
	header_hbox.add_child(expand_button)
	header_hbox.set_meta("header", true)
	add_child(header_hbox)
	
	var image_idx = 1

	# Main Ingredients: Indent 1
	for i in range(len(order_form.main_ingredients)):
		var new_image = TextureRect.new() 
		new_image.texture = textures.get_atlas_all_args("iconsheet.png", order_form.icon_positions[image_idx], order_form.ICONSIZE)
		new_image.set_stretch_mode(TextureRect.STRETCH_KEEP)
		var new_label = Label.new()
		new_label.set_label_settings(load(Globals.order_label_settings))
		new_label.text = order_form.main_ingredients[i] + " " + order_form.main_types[i] + " \n"		
		
		var hbox = HBoxContainer.new()
		hbox.add_child(get_spacer_label())
		hbox.add_child(new_image)
		hbox.add_child(new_label)
		hbox.set_meta("header", false)
		add_child(hbox)
		
		image_idx += 1
	
	# Milk: Indent 2
	if order_form.milk:
		var new_image = TextureRect.new() 
		new_image.texture = textures.get_atlas_all_args("iconsheet.png", order_form.icon_positions[image_idx], order_form.ICONSIZE)
		new_image.set_stretch_mode(TextureRect.STRETCH_KEEP)
		var new_label = Label.new()
		new_label.set_label_settings(load(Globals.order_label_settings))
		new_label.text = ("\t+ Milk\n")
		
		var hbox = HBoxContainer.new()
		hbox.add_child(get_spacer_label())
		hbox.add_child(get_spacer_label())
		hbox.add_child(new_image)
		hbox.add_child(new_label)
		hbox.set_meta("header", false)
		add_child(hbox)
		
		image_idx += 1
	
	# Syrups: Indent 1
	for i in range(len(order_form.syrups)):
		var new_image = TextureRect.new() 
		new_image.texture =  textures.get_atlas_all_args("iconsheet.png", order_form.icon_positions[image_idx], order_form.ICONSIZE)
		new_image.set_stretch_mode(TextureRect.STRETCH_KEEP)
		var new_label = Label.new()
		new_label.set_label_settings(load(Globals.order_label_settings))
		new_label.text = "\t+ %s Syrup\n" % order_form.syrups[i]
		
		var hbox = HBoxContainer.new()
		hbox.add_child(get_spacer_label())
		hbox.add_child(new_image)
		hbox.add_child(new_label)
		hbox.add_child(get_spacer_label())
		hbox.set_meta("header", false)
		add_child(hbox)
		
		image_idx += 1

	# Toppings: Indent 1
	for i in range(len(order_form.toppings)):
		var new_image = TextureRect.new() 
		new_image.texture = textures.get_atlas_all_args("iconsheet.png", order_form.icon_positions[image_idx], order_form.ICONSIZE)
		new_image.set_stretch_mode(TextureRect.STRETCH_KEEP)
		var new_label = Label.new()
		new_label.set_label_settings(load(Globals.order_label_settings))
		if order_form.toppings[i].ends_with("s"):
			new_label.text = "\t+ %s \n" % order_form.toppings[i]
		else:
			new_label.text = "\t+ %ss \n" % order_form.toppings[i]
		
		var hbox = HBoxContainer.new()
		hbox.add_child(get_spacer_label())
		hbox.add_child(new_image)
		hbox.add_child(new_label)
		hbox.add_child(get_spacer_label())
		hbox.set_meta("header", false)
		add_child(hbox)
			
		image_idx += 1		

	# Whip/Cherry Indent 2
	if order_form.whip:
		var new_image = TextureRect.new() 
		new_image.texture = (textures.get_atlas_all_args("iconsheet.png", order_form.icon_positions[image_idx], order_form.ICONSIZE))
		new_image.set_stretch_mode(TextureRect.STRETCH_KEEP)
		var new_label = Label.new()
		new_label.set_label_settings(load(Globals.order_label_settings))
		new_label.text = "With Whipped Cream\n"
		
		var hbox = HBoxContainer.new()
		hbox.add_child(get_spacer_label())
		hbox.add_child(get_spacer_label())
		hbox.add_child(new_image)
		hbox.add_child(new_label)
		hbox.set_meta("header", false)
		add_child(hbox)
		
		image_idx += 1
		
		if order_form.cherry:
			var new_new_image = TextureRect.new() 
			new_new_image.texture = (textures.get_atlas_all_args("iconsheet.png", order_form.icon_positions[image_idx], order_form.ICONSIZE))
			new_new_image.set_stretch_mode(TextureRect.STRETCH_KEEP)
			var new_new_label = Label.new()
			new_new_label.set_label_settings(load(Globals.order_label_settings))
			new_new_label.text = ("And A Cherry\n")
			
			var hbox_new = HBoxContainer.new()
			hbox_new.add_child(get_spacer_label())
			hbox_new.add_child(get_spacer_label())
			hbox_new.add_child(get_spacer_label())
			hbox_new.add_child(new_new_image)
			hbox_new.add_child(new_new_label)
			hbox.set_meta("header", false)
			add_child(hbox_new)
			
			image_idx += 1
			
func get_spacer_label():
	var label = Label.new()
	label.custom_minimum_size = Vector2(TAB_SIZE, TAB_SIZE)
	return label

func _collapse():
	for child in get_children():
		if child.has_meta("header"):
			child.visible = child.get_meta("header")
		else:
			child.visible = false
	expanded=false
			
func _expand():
	for child in get_children():
		child.visible = true
	expanded=true

func _on_expand_pressed():
	if expanded:
		_collapse()
	else:
		_expand()
