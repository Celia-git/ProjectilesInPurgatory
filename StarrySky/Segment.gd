extends Area2D

signal segment_entered
signal no_segment_entered

# first index of stars at which the segment overlaps  
var anchor_point1= 0
var anchor_point2= 0

# If area overlap is not excluded points, emit signal
func _on_area_entered(area):
	
	# Ignore overlapping anchor points
	var anchor = area.get_parent()
	if anchor.is_in_group("Stars"):
		if anchor.index_line1 == anchor_point1 || anchor.index_line1 == anchor_point2:
			return
			
	# Ignore overlapping segments which share anchor points and overlap with those anchor points
	elif area.is_in_group("Segments"):
		if area.anchor_point1 == anchor_point1 || area.anchor_point2 == anchor_point1\
		|| area.anchor_point1 == anchor_point2 || area.anchor_point2 == anchor_point2:
			emit_signal("no_segment_entered")
			return
			
	emit_signal("segment_entered", area)
