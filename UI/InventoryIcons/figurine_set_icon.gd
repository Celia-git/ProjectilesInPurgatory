extends InventoryIcon

class_name FigurineSetIcon

var fixed_icon_position:bool
var set_size:int
var current_size:int=0

# Set made initially of at least two prizes dropped on one another
func _init(prize_1, prize_2, prize_3=null, prize_4=null, prize_5=null, prize_6=null):
	add_child(prize_1)
	add_child(prize_2)
	self.current_size =2
	for prize in [prize_3, prize_4, prize_5, prize_6]:
		if prize == null:
			break
		add_child(prize)
		self.current_size += 1

	self.item_name = prize_1.set_name
	self.set_size = prize_1.set_size
	self.fixed_icon_position = prize_1.fixed_icon_position

func add_prize(prize):
	add_child(prize)
	self.current_size += 1
	

func is_complete_set():
	return self.current_size == self.set_size
