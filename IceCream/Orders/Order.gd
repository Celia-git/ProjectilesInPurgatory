
class_name Order

const ICONSIZE = Vector2(75, 75)
var icon_positions

var item_type
var main_ingredients
var main_types
var syrups
var toppings
var milk
var whip
var cherry

func set_values(item_type, main_ingredients, main_types, syrups, toppings, milk, whip, cherry, icon_positions):
	self.item_type=item_type
	self.main_ingredients=main_ingredients
	self.main_types = main_types
	self.syrups=syrups
	self.toppings=toppings
	self.milk=milk
	self.whip=whip
	self.cherry = cherry
	self.icon_positions = icon_positions	# item_type, main_ingredient1, (main_ingredient2), syrup, topping, milk, whip)

