extends ClawMachine

signal stabilize_prizes

@export var claw_dip_radius = 8.0
var prize_amount = 400
var prize_inventory_path = "res://ClawMachine/resources/Prizes_Candy.txt"
# fruity and spicy candies come with a combination of flavors (colors) and forms (shapes)
var candy_a_flavors = {"cherry chili":Color(.88, .21, .09, 1), "blackberry":Color(.51, .17, .84, 1), "orange clove":Color(1, .53, 0, 1), "chili mango":Color(1, .87, .04, 1), "coconut lime":Color(.2, .95, .2, 1), "lavender pear":Color(.81, .48, .95, 1),\
 "blueberry vanilla":Color(.22, .41, 1, 1), "raspberry basil":Color(1, .09, .58, 1), "banana cream":Color(1, .99, .65, 1), "strawberry cardamom":Color(1, .49, .65, 1)}
var candy_a_forms = ["jelly", "rock candy", "taffy", "gummy ring", "soft drop", "hard drop", "hard twist",\
 "hard ribbon", "lollipop"]
# chocolatey candies come with a base(shape) and coating(color)
var candy_b_coating = {"chocolate":Color(.39, .13, .08, 1), "candy":Color(.94, .21, .1, 1), "caramel":Color(.93, .75, .35, 1), "white chocolate":Color(.97, .91, .78, 1)}
var candy_b_base = ["nougat bar", "caramel", "malted milk ball", "marshmallow", "peanut", "chocolate bar"]

var fudge_variations = {"rocky road":Color(.98, .98, .98, 1), "maple":Color(.91, .68, .28, 1), "mint":Color(.26, 1, .89, 1), "walnut":Color(.66, .59, .5, 1)}
var brittle_variations = {"pecan":Color(.72, .49, .22, 1), "pistachio":Color(.59, 1, .61, 1), "peanut":Color(.91, .68, .28, 1)} 

var  timer

	
func _ready():
	super._ready()
	timer = Timer.new()
	timer.timeout.connect(_stabilize_prize_movement)
	add_child(timer)
	timer.start(.2)
	

func set_prizes():
	
	self.prize_path = prize_path % [machine_idx]
	var prize_dir = DirAccess.open(prize_path)
	var prize_scenes = {}
	var prizes = []
	
	# Load prize scenes from directory
	if prize_dir:
		prize_dir.list_dir_begin()
		var file_name = prize_dir.get_next()
		while file_name != "":
			if !prize_dir.current_is_dir():
				prize_scenes[file_name.replace("_", " ").trim_suffix(".tscn")] = (prize_path+file_name)
			file_name = prize_dir.get_next()
	
	# Instantiate prize scenes and set weights
	var rng = RandomNumberGenerator.new()
	var icon_pos = Vector2(0,0)
	var icon_size = Vector2(32, 24)
	
	# Iterate all prize shapes (scenes)
	for key in prize_scenes.keys():
		rng.randomize()
		var prize = load(prize_scenes[key]).instantiate()	
		var weighted_amount = float(2*prize_amount)*prize.get_meta("weight")
		var randomizer = rng.randf_range(.85, 1.05)	
		var this_prize_amount = int(randomizer*weighted_amount/float(prize_scenes.keys().size()))
		setup_prize(prize, key, rng, key in candy_a_forms, Rect2(icon_pos, icon_size))
		
		# Make p flavor variations of this prize
		var p = 1
		while p < this_prize_amount:
			var new_prize = load(prize_scenes[key]).instantiate()			
			setup_prize(new_prize, key, rng, key in candy_a_forms, Rect2(icon_pos, icon_size))
			
			p += 1
		
		# Increment Icon Position
		if (icon_pos.x + icon_size.x) < 160:
			icon_pos.x += icon_size.x
		else:
			icon_pos.y += icon_size.y
			icon_pos.x = 0
	
# Set prize texture, flavor, and color
func setup_prize(prize, key, rng, is_candy_a, atlas_region):
	set_prize_physical_parameters(prize)	
	load_prize_texture(prize, key)				
	stabilize_prizes.connect(prize._stabilize.bind(Rect2(to_global(expanded_toybox.position), to_global(expanded_toybox.end))))
	var flavor = ""
	rng.randomize()
	
	prize.atlas_region = atlas_region
	prize.add_to_group("prizes")
	
	if is_candy_a:
		flavor = candy_a_flavors.keys()[rng.randi_range(0, candy_a_flavors.keys().size()-1)]
		prize.set_sprite_color(candy_a_flavors[flavor].lightened(.1))
		
	elif key in candy_b_base:
		flavor = candy_b_coating.keys()[rng.randi_range(0, candy_b_coating.keys().size()-1)]
		prize.set_sprite_color(candy_b_coating[flavor].lightened(.1))
		prize.prize_name = flavor + " coated "+ key
		return
	elif key=="fudge":
		flavor = fudge_variations.keys()[rng.randi_range(0, fudge_variations.keys().size()-1)]
		prize.set_sprite_color(fudge_variations[flavor].lightened(.1)) 
	elif key=="brittle":
		flavor = brittle_variations.keys()[rng.randi_range(0, brittle_variations.keys().size()-1)]
		prize.set_sprite_color(brittle_variations[flavor].lightened(.1))
		
	prize.prize_name = flavor +" "+ key
	prize.meta_combo = get_candy_meta_combo(key, flavor, is_candy_a)
	prize.inventory_location = prize_type
	prize.asset_names = ["lunchbox_0.png", "lunchbox_1.png", "lunchbox_click_mask.bmp"]


func _stabilize_prize_movement():
	emit_signal("stabilize_prizes")
	
# Determine meta combo appropriate for this candy
func get_candy_meta_combo(shape, flavor, is_candy_a):
	return ""	
