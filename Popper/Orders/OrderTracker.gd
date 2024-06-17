extends Control

# Create orders for popper
signal order_submitted
signal order_recinded
signal get_popcorn_order
signal get_apple_order


var inventory_path = "res://IceCream/Orders/InventoriesIceCreamInventory.txt"
var order_form_scene = "res://Popper/Orders/OrderForm.tscn"

var total_orders = 0
var fulfilled_orders = 0
var failed_orders = 0
var sauces = {}
var toppings = {}

@onready var order_docker = $OrderDockerPopup/ScrollContainer/OrderDocker
var expanded = false

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Load Inventory
	if sauces.is_empty():
		sauces = Globals.get_inventory("popcorn sauce")
	if toppings.is_empty():
		toppings = Globals.get_inventory("topping") 

func _generate_order(amount):

	for i in range(amount):
		var get_order = ["get_popcorn_order", "get_apple_order"][randi_range(0, 1)]
		var order_form = load(order_form_scene).instantiate()
		order_form.add_to_group("orders")
		order_form.set_meta("index", total_orders)
		order_form.set_meta("late", false)	
		order_form.submit_order.connect(_submit_order.bind(order_form))
		order_form.recind_order.connect(_recind_order.bind(order_form))
		order_form.order_failed.connect(_order_failed.bind(total_orders))
		emit_signal(get_order, order_form)
		total_orders+=1

func _get_popcorn_order(order_form):
	
	var orders = ["Bag of Popcorn"]
	var is_plain = bool(randi_range(0, 3))
	var sauce = sauces.keys()[randi_range(0, sauces.size()-1)]

	if !is_plain:

		orders.append("with %s Sauce" % [sauce])
	
	if orders.size()==1:
		# THIS IS WHERE THE POPCORN ICON WOULD GO
		order_form.set_values({orders[0]:null})
	else:
		order_form.set_values({orders[0]:null, orders[1]:sauces[sauce][1]})
	order_docker.add_child(order_form)
	
func _get_apple_order(order_form):
	
	var coating = ["Candy", "Caramel"][randi_range(0,1)]
	var with_topping = randi_range(0, 3)
	var orders = ["%s Apple" % [coating]]
	var topping
	if bool(with_topping):
		for i in range(with_topping):
			var all_toppings = toppings.keys()
			topping = all_toppings[randi_range(0, all_toppings.size()-1)]
			orders.append(topping)
		
	if orders.size()==1:
		# THIS IS WHERE THE APPLE ICON WOULD GO
		order_form.set_values({orders[0]:null})
	else:
		order_form.set_values({orders[0]:null, orders[1]:toppings[topping][1]})
	
	order_docker.add_child(order_form)
		
		

# View Order Docker
func _on_view_orders_toggled(_button_pressed):
	$OrderDockerPopup.visible = !$OrderDockerPopup.visible
	$ViewOrders/TextureRect.position.y = [4, 10][int(_button_pressed)]

func _on_order_docker_child_entered_tree(node):
	if node.is_in_group("orders"):
		$ViewOrders.button_pressed=true

		
# Submit order: match with sprite on counter 
func _submit_order(order):
	emit_signal("order_submitted", order, order.get_meta("late"))
	
func _recind_order(order):
	emit_signal("order_recinded", order)

# Expand/Contract all orderz in Docker
func _on_button_pressed(toggle_mode):
	for node in order_docker.get_children():
		if node.is_in_group("orders"):
			match toggle_mode:
				true:
					node._collapse()
				false:
					node._expand()
	
	expanded = !expanded
	

func _order_fulfilled(index):
	for node in order_docker.get_children():
		if node.is_in_group("orders"):
			if node.get_meta("index")==index:
				node.call_deferred("queue_free")
	fulfilled_orders += 1
	
func _order_failed(index):
	failed_orders += 1




func _on_view_orders_mouse_entered():
	emit_signal("mouse_entered")

func _on_view_orders_mouse_exited():
	emit_signal("mouse_exited")


func _on_order_docker_popup_close_requested():
	$ViewOrders.button_pressed=false
