class_name EdgeGenerator extends Node2D

## This generator can be used to generate a random path for an edge.
## It takes one of its children and uses it as a template for the path.
## It also adds some jitter.

var children: Array[EdgeTemplate] = []
var total_frequency: float = 0.0


func _ready():
	# We want to see this in design mode but not in the game.
	visible = false

	# Iterate all the children. They must all be EdgeTemplate nodes.
	for i in range(get_child_count()):
		var child = get_child(i)
		if child is EdgeTemplate:
			children.append(child)
			total_frequency += child.frequency


## Returns a random child based on the frequency of each child.
func random_weighted_child() -> EdgeTemplate:
	# Pick a random number between 0 and the total frequency.
	var random = randf() * total_frequency
	var sum = 0.0

	# Iterate all the children and add their frequency to the sum.
	# If the sum is greater than the random number, we have found the child.
	for i in range(children.size()):
		sum += children[i].frequency
		if sum > random:
			return children[i]

	# If we get here, we have a problem.
	print("Error: Could not find a child for the edge generator.")
	return null


func random_line() -> PackedVector2Array:
	# Pick a random child, get the line from the child
	var line: PackedVector2Array = random_weighted_child().points.duplicate()

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
