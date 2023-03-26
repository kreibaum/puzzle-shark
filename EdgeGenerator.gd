class_name EdgeGenerator extends Node2D

## This generator can be used to generate a random path for an edge.
## It takes one of its children and uses it as a template for the path.
## It also adds some jitter.


## We want to see this in design mode but not in the game.
func _ready():
	visible = false


func random_line() -> PackedVector2Array:
	# Pick a random child
	var child = get_child(randi() % get_child_count())
	# Get the line from the child
	var line: PackedVector2Array = child.points

	# Randomizes the shape of the edge by adding a random offset to each point.
	# May also flip the edge with a probability of 0.5.
	var jitter = 10
	var flip_x = randf() < 0.5
	var flip_y = randf() < 0.5

	for i in range(line.size()):
		line[i] += Vector2(randf_range(-jitter, jitter), randf_range(-jitter, jitter))
		if flip_x:
			line[i].x *= -1
		if flip_y:
			line[i].y *= -1

	return line
