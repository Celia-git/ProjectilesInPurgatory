extends Node

# Access boardwalk map data: Arrow + portal positions, etc


const BACKGROUND_PATH = "res://Assets/Backgrounds/Boardwalk/Boardwalk%d.png"
var portal_array=[
	
	[		# BOARDWALK 0
		{"destination":0,"overworld_index":0, "subgame":0}, # "click_area":[Rect2(0,190,228, 570), Rect2( 276, 328, 185, 372), Rect2(1065, 285, 173, 367), Rect2(1285, 305, 196, 493)]}
		{"destination":0,"overworld_index":1, "subgame":1},
		{"destination":0,"overworld_index":2, "subgame":2},
		{"destination":0,"overworld_index":3, "subgame":3},
		{"destination":9,"overworld_index":4, "subgame":0}
	],
	[		# BOARDWALK 1
		{"destination":2, "overworld_index":0, "subgame":0}# "click_area":[Rect2(40, 560, 180, 180)]}
	],
	[		# BOARDWALK 02 ( empty)
	],		
	[		# BOARDWALK 03
		{"destination":4, "overworld_index":0, "subgame":0}
	],
	[		# BOARDWALK 04
		{"destination":3, "overworld_index":0, "subgame":0},#"click_area":[Rect2(0, 125, 335, 550), Rect2(425, 300, 108, 308), Rect2(1125, 125, 450, 550)]}
		{"destination":3, "overworld_index":1, "subgame":1},
		{"destination":3, "overworld_index":2, "subgame":2}
	],
	[		# BOARDWALK 05 (empty)
	],
	[		# BOARDWALK 06
		{"destination":6, "overworld_index":0, "subgame":0} #"click_area":[Rect2(755, 175, 158, 315)]}
	],
	[		# BOARDWALK 07
		{"destination":7, "overworld_index":0, "subgame":0},#"click_area":[Rect2(180, 118,324,675)]},
		{"destination":8, "overworld_index":1, "subgame":0}#"click_area":[Rect2(1090, 530, 390, 260)]}
	],
	[		# BOARDWALK 08
		{"destination":5, "overworld_index":0, "subgame":0}#"click_area":[Rect2(570, 0, 775, 386)]}
	],
	[		# BOARDWALK 09
		{"destination":1, "overworld_index":0, "subgame":0}#"click_area":[Rect2(1071, 53 ,270, 500)]}
	]
]



var arrow_array=[
	
	[		# BOARDWALK 00
		{"destination":1, "direction":"forward","position":Vector2(720, 562)}
	],
	[		# BOARDWALK 01
		{"destination":0, "direction":"back", "position":Vector2(477, 747)},
		{"destination":9, "direction":"forward_right", "position":Vector2(750, 582)},
		{"destination":2, "direction":"forward_left", "position":Vector2(375, 462)}
	],
	[		# BOARDWALK 02
		{"destination":1, "direction":"back_left", "position":Vector2(435, 765)},
		{"destination":3, "direction":"right", "position":Vector2(990, 795)}
	],
	[		# BOARDWALK 03
		{"destination":2, "direction":"left", "position":Vector2(25, 765)},
		{"destination":4, "direction":"right", "position":Vector2(1170, 765)}
	],
	[		# BOARDWALK 04
		{"destination":5, "direction":"back", "position":Vector2(739, 750)},
		{"destination":6, "direction":"forward", "position":Vector2(675, 540)}
	],
	[		# BOARDWALK 05
		{"destination":4, "direction":"back", "position":Vector2(560, 745)},
		{"destination":7, "direction":"forward_left", "position":Vector2(125,617)},
		{"destination":3, "direction":"forward_right", "position":Vector2(975, 665)}
	],
	[		# BOARDWALK 06
		{"destination":5, "direction":"back", "position":Vector2(735, 750)}
	],
	[		# BOARDWALK 07
		{"destination":5, "direction":"back", "position":Vector2(780, 740)},
		{"destination":8, "direction":"forward", "position":Vector2(830, 535)}
	],
	[		# BOARDWALK 08
		{"destination":7, "direction":"left", "position":Vector2(35, 765)},
		{"destination":9, "direction":"right", "position":Vector2(1007, 765)}
	],
	[		# BOARDWALK 09
		{"destination":8, "direction":"back_left", "position":Vector2(155, 665)},
		{"destination":1, "direction":"right", "position":Vector2(955, 685)}
	]
	
]
var portals:Array
var arrows:Array
var texture:Texture2D

func _init(map_idx:int):
	self.portals = portal_array[map_idx]
	self.arrows = arrow_array[map_idx]
	self.texture = load(BACKGROUND_PATH % [map_idx] )
	
# Return array of arrow dicts per this map
func get_arrow_data():
	return self.arrows

func get_portal_data():
	return self.portals
	
func get_background_texture():
	return self.texture
	

