extends Resource

class_name Player

@export var player_name:String=""
@export var tickets:int = 0

@export var front_pocket = []
@export var lunchbox = []
@export var big_pocket = []
@export var figurines = []
@export var figurine_sets = []
@export var active_quests = []
@export var completed_quests = []

@export var unlocked_cursors = [0, 1, 2, 3]
@export var settings:Dictionary = {
	"All Volume":0,
	"Sound Effects":0,
	"Music":0,
	"Ambient":0,
	"Cursor":0,
	"mouse_tail_length":5,
	"mouse_tail_action":0
}
@export var active_map_idx:int=4
@export var active_map_type:String="Exterior"
@export var previous_map_idx:int=0
@export var current_subgame:int=0
@export var mouse_trail_enabled:bool=false

func set_player_name(arg:String):
	self.player_name = arg

func get_player_name():
	return self.player_name

func set_tickets(arg:int):
	self.tickets = arg
	
func get_tickets():
	return self.tickets
	
	
func set_unlocked_cursors(arg:Array):
	self.unlocked_cursors = arg

func get_unlocked_cursors():
	return self.unlocked_cursors

func set_settings(st:Dictionary):
	self.settings = st
	
func get_settings():
	return self.settings

func set_active_map_idx(arg:int):
	self.active_map_idx=arg

func get_active_map_idx():
	return self.active_map_idx

func set_active_map_type(arg:String):
	self.active_map_type = arg

func get_active_map_type():
	return self.active_map_type

func set_previous_map_idx(arg:int):
	self.previous_map_idx = arg 

func get_previous_map_idx():
	return self.previous_map_idx

func set_current_subgame(arg:int):
	self.current_subgame = arg

func get_current_subgame():
	return self.current_subgame

func set_mouse_trail_enabled(arg:bool):
	self.mouse_trail_enabled = arg

func get_mouse_trail_enabled():
	return self.mouse_trail_enabled
