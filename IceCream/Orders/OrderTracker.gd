extends Control


class_name OrderTracker


const ORDER_POS = Vector2(200, 100)


@onready var rng = RandomNumberGenerator.new()
var order_form = load("res://IceCream/Orders/OrderForm.tscn")
var path = "res://IceCream/Orders/Inventories"
var order_path = load("res://IceCream/Orders/Order.gd")
var template_path = load("res://IceCream/Orders/Template.gd")
var template_objects = []
var inventory = [] # Array of dicts
var scrolling=null
var orders_expanded=true

func _ready():
	load_file_data()
	get_order_form(10)


func _process(delta):
	if scrolling:
		$ViewOrders.position.y += scrolling*delta
		if Input.is_action_just_released("scroll_down") || Input.is_action_just_released("scroll_up"):
			scrolling = false

func load_file_data():
	
	for ext in ["IceCreamInventory.txt", "IceCreamObjects.txt"]:
		var read_file = FileAccess.open(path+ext, FileAccess.READ)
					
		match ext:
			"IceCreamInventory.txt":
				
				var inventory_labels = []
				var first_line = true
				while read_file.get_position() < read_file.get_length():
					var line =Array(read_file.get_line().split("/"))
					if first_line:
						for word in line:
							if (word.begins_with("Icon")||word==""):continue
							inventory_labels.append(word)
						first_line=false
					else:
						var inventory_dict = {}
						inventory_dict["IconPosition"] = Vector2(int(line[7]), int(line[6]))
		
						var i = 0
						for word in line:
							
							if word.is_valid_int()||word=="":
								line.erase(word)
								continue
							if word=="True":
								word = true
							elif word=="False":
								word=false
								
							inventory_dict[inventory_labels[i]] = word
							i += 1
						inventory.append(inventory_dict)
						
			"IceCreamObjects.txt":
				
				var line_number = 0

				while read_file.get_position() < read_file.get_length():
					var line = read_file.get_line().split("/")
					
					# Write to Template
					if line_number>0:
						for word in line:
							if word.is_valid_int():
								word = int(word)
						if line[1] != "False":
							var template_object = template_path.new()
							template_object.set_values(line[0], line[1], line[2], line[3], line[4], line[5])			
							template_objects.append(template_object)
					
					line_number += 1
	# Assign probabilities to template objects
	var prefix = ""
	for p in template_objects:
	# Assign lesser probabilities to repeat names
		var template_name = p.name.split(" ")
		if template_name[0] != prefix:
			p.probability = 6
			prefix = template_name[0]
		else:
			p.probability = 1

# Load inventory items, initiate order generation
func get_order_form(order_size):

	var order_form = []

	while order_size > 0:
		order_form.append(choose_item())
		order_size-=1
		

	return order_form
	

func choose_item():
	# Choose random template
	var pot = []
		
	for p in template_objects:
		var array = []
		array.resize(p.probability)
		array.fill(p) 
		pot.append_array(array)
	
	rng.randomize()
	var winner = rng.randi_range(0, pot.size() - 1)
	return fill_order(pot[winner])
	
	

# Add Random Flavors to template object
func fill_order(item):
	# Select randomized ingredient(s)
	var main_ingredients = []
	var main_ingredient_types = []
	var syrups =[]
	var toppings=[]
	var milk = false
	var whip=false
	var cherry = false
	
	# item_type, main_ingredient1, (main_ingredient2), syrup, topping, milk, whip)
	var icon_positions = []
	for entry in inventory:
		if (entry["Template"]==true and entry["Name"]==item.name):
			icon_positions.append(entry["IconPosition"])
	
	for ingredient_type in ["Ice Cream", "Soda"]:
		if ingredient_type in item.main_ingredient:
			var pot = []
			var icons = []
			for entry in inventory:
				if entry[ingredient_type]:
					pot.append(entry["Name"])
					icons.append(entry["IconPosition"])
			rng.randomize()
			var winner = rng.randi_range(0, pot.size()-1)
			main_ingredients.append(pot[winner])
			main_ingredient_types.append(ingredient_type)
			icon_positions.append(icons[winner])
			
			
	# Milk: Template dependent
	
	if item.milk:
		
		var milk_idx=0
		for i in range(inventory.size()):
			if inventory[i]["Name"]=="Milk":
				milk_idx=i
				break
		icon_positions.append(inventory[milk_idx]["IconPosition"])
			
	# Get syrups + Toppings
	if item.syrups:
		rng.randomize()
		var goget = bool(rng.randi_range(0,1))
		if goget:
			var syrups_icons = get_fixins("Syrup", item.name)
			syrups = syrups_icons[0]
			icon_positions.append_array(syrups_icons[1])
	if item.toppings:
		rng.randomize()
		var goget = bool(rng.randi_range(0,1))
		if goget:
			var toppings_icons = get_fixins("Topping", item.name)
			toppings = toppings_icons[0]
			icon_positions.append_array(toppings_icons[1])


	# Whip/Cherry (Selectively Optional)
	
	if item.whip:
		rng.randomize()
		whip = bool(rng.randi_range(0, 1))
		if whip:
			var whip_idx=0
			for i in range(inventory.size()):
				if inventory[i]["Name"]=="Whipped Cream":
					whip_idx=i
					break
			icon_positions.append(inventory[whip_idx]["IconPosition"])
			rng.randomize()
			cherry = bool(rng.randi_range(0, 2))
			if cherry:
				var cherry_idx = 0
				for i in range(inventory.size()):
					if inventory[i]["Name"]=="Cherry":
						cherry_idx=i
						break
				icon_positions.append(inventory[cherry_idx]["IconPosition"])
	
	

	var order = order_path.new()
	order.set_values(item.name, main_ingredients, main_ingredient_types, 
	syrups, toppings, item.milk, whip, cherry, icon_positions)

	return (order)



	# Get Random Sauce or Topping
func get_fixins(fixin, item_name):

	var pot = []
	var icons = []
	var final_fixins = []
	var final_icons = []
	var max_amt = 3
	
	for entry in inventory:
		if entry[fixin]:
			pot.append(entry["Name"])
			icons.append(entry["IconPosition"])

	# Get Random Amount of Fixins
	if ("Cone" in item_name || "Blizzie" in item_name) and fixin=="Syrup":
		max_amt=1
	if ("Cone" in item_name || "Blizzie" in item_name) and fixin=="Topping":
		max_amt=2
	rng.randomize()
	var amt = rng.randi_range(1, max_amt)	
	
	while amt > 0:
		# Get Random Fixin
		rng.randomize()
		var winner=rng.randi_range(0, pot.size()-1)
		final_fixins.append(pot[winner])
		final_icons.append(icons[winner])
		amt -= 1

	return [final_fixins, final_icons]
	
	



func _on_gui_input(event):
	if event.is_action_pressed("scroll_up"):
		scrolling = 2000
	elif event.is_action_pressed("scroll_down"):
		scrolling = -2000


		

# Place new order
func _on_new_order_pressed():

	var backup_templates = template_objects.duplicate(true)
	var order_forms = get_order_form(1)
	for form in order_forms:
		var order_node = order_form.instantiate()
		order_node.set_form(form)
		$ViewOrders.add_child(order_node)
	template_objects = backup_templates


func _on_expand_all_pressed():
	if orders_expanded:
		for order in $ViewOrders.get_children():
			order._collapse()
		orders_expanded=false
	else:
		for order in $ViewOrders.get_children():
			order._expand()
		orders_expanded=true
	$ViewOrders.position = ORDER_POS
