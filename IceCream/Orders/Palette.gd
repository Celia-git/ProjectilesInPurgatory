class_name Palette

var name
var main_ingredient=[]
var syrups
var toppings
var milk
var whip
var probability

func _init(name, main_ingredient, syrups, milk, toppings, whip):
	self.name = name
	var ingredient_array = main_ingredient.split(",")
	for ingredient in ingredient_array:
		self.main_ingredient.append(ingredient.strip_edges())
	self.syrups = (syrups=="True")
	self.toppings = (toppings=="True")
	self.milk= (milk=="True")
	self.whip= (whip=="True")
	self.probability = 0
	
