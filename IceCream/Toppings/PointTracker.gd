extends Control

var points = {}
var winning_colors = []
var label_settings = load(Globals.label_settings)

# Create display labels for the first time
func set_display():
	var keys = points.keys()
	for entry in keys:
		var rect = ColorRect.new()
		rect.size = Vector2(48, 48)
		rect.color = entry
		rect.name = str(entry)
		var label = Label.new()
		label.name = "Label"
		label.text = str(points[entry])
		label.horizontal_alignment = 1
		label.vertical_alignment = 1
		label.label_settings = label_settings
		rect.add_child(label)
		$Scoreboard.add_child(rect)
		rect.position.x += (($Scoreboard.get_child_count()*48) +24)
		rect.color = winning_colors[0]

# Add new key to points values
func set_points(key, value):
	points[key] = value

# Set winning colors array of Color
func set_winning_colors(colors):
	winning_colors = colors

# Reconfigure display labels
func _new_point(particle_color):
	points[particle_color] += 1
	# Update Display Label
	var rect = $Scoreboard.get_node(str(particle_color))
	rect.get_node("Label").text = str(points[particle_color])
	
# Calculate and diplay score
func display_score():
	
	var ratio = get_score()
	var label = Label.new()
	label.label_settings = label_settings
	if ratio >.5:
		label.text = "Very Bad!"
	elif (ratio <=.5 and ratio > .3): 
		label.text = "Not Bad"
	elif (ratio <=.3 and ratio > .1): 
		label.text = "Good Job!"
	else:
		label.text = "WINNER!!!"
	$Message.add_child(label)
	$Message.visible = true
	
func get_score():
	var win=0
	var loss=0
	
	for key in points.keys():
		if key in winning_colors:
			win += float(points[key])
		else:
			loss += float(points[key])
	
	if win < 5:
		return 1
	
	return (loss/win)
			

