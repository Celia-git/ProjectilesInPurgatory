extends Node

signal win_game
signal achievement_unlocked
signal load_images

const ACHIEVEMENT_SIZE = Vector2(45, 45)
var known_characters = []
var unlocked_achievements = []
var card_types = {} # A dict of card types, organized by subcategory

var achievements = {
	"Mother Warrior":0,
	"Spectre Rogue":0,
	"Maiden Priest":0,
	"Crone Seer":0,
	"Water Mage":0,
	"Fire Warrior":0,
	"Stone Priest":0,
	"Stone Spectre":0,
	}
	
var goals = {
	"Mother Warrior":3,
	"Spectre Rogue":3,
	"Maiden Priest":3,
	"Crone Seer":3,
	"Water Mage":4,
	"Fire Warrior":4,
	"Stone Priest":4,
	"Stone Spectre":5
	}
	
#Track achievements and known characters for saving 

# Set variables, load images
func load_data(types, known_char, achieve, unlocked_ach):
	achievements = achieve
	known_characters=known_char
	unlocked_achievements=unlocked_ach
	
	for subtype in types:
		card_types[subtype] = subtype["subcategories"]
	
	# Populate achievement goals dict, load achievement textures
	var textures = Globals.texture_script.new()
	var last_pos = Vector2(6, 3)
	var atlas = textures.get_atlas_all_args("achievements.png", last_pos, ACHIEVEMENT_SIZE)
	emit_signal("load_images", atlas, "All Combos")
	last_pos.x -= 1
	
	# Load custom achievement icons
	var keys = goals.keys()
	keys.reverse()
	for key in keys:
		if last_pos.x < 0:
			last_pos.y -= 1
			last_pos.x = 6
		
		var atlas1 = textures.get_atlas_all_args("achievements.png", last_pos, ACHIEVEMENT_SIZE)
		emit_signal("load_images", atlas1, key)
		
		last_pos.x -= 1

	
	# Iterate standard achievements
	var y = 2
	for key in card_types.keys():
		
		var x = 0
		# Copy the dict of arrays, omit the current array
		var copy = card_types.duplicate(true)
		copy.erase(key)
		var goal = 1
		for copy_key in copy.keys():
			goal *= copy[copy_key].size()
		
		# Load all achievement textures in this row
		# Set goals based on card type
		for entry in card_types[key]:
			goals[entry] = goal
			var atlas2 = textures.get_atlas_all_args("achievements.png", Vector2(x, y), ACHIEVEMENT_SIZE)
			emit_signal("load_images", atlas2, entry)
			x += 1
			
		y -= 1


##################### FINISH ################################
# Check for win condition (60 matches) or other achievements
func check_win():
	var match_amount = 1
	for subtype in card_types:
		match_amount *= subtype.size()
	if match_amount == known_characters.size():
		emit_signal("achievement_unlocked", "All Combos")
		unlocked_achievements.append("All Combos")
		emit_signal("win_game")
	

func check_achievements():
	
	for type in achievements:
		if !(type in goals.keys()):
			continue

		if (achievements[type] == goals[type]) and !(type in unlocked_achievements):
			
			emit_signal("achievement_unlocked", type)
			unlocked_achievements.append(type)

func add_character(character):
	var array = character.split(" ")
	# Check for standard 1-type achievement
	for item in array:
		if !(item in unlocked_achievements):
			if !(item in achievements.keys()):
				achievements[item]=1
			else:
				achievements[item] += 1
	
	# Check for custom 2-type achievements
	var scenario_1 = array[0] + " " + array[1]
	var scenario_2 = array[1] + " " + array[2]
	var scenario_3 = array[0] + " " + array[2]
	
	for scenario in [scenario_1, scenario_2, scenario_3]:
		if scenario in achievements.keys():
			achievements[scenario] += 1
			
	known_characters.append(character)
