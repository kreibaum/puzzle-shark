class_name AsyncCollisionManager extends Node

## This class spends some time every frame to maintain the collisions between
## the edges of the puzzle. This is done incrementally, so that the game
## doesn't freeze while the collisions are being calculated.

## How many milliseconds to spend on collision calculations each frame.
const STOP_AFTER_MS = 3

var i: int = 0
var j: int = 0

@onready var canvas: PuzzleCanvas = get_parent()


func reset():
	i = 0
	j = 0
	for edge in canvas.edges:
		edge.set_color(edge.color_normal)
		edge.queue_redraw()


## This function is called every frame. It will spend some time calculating
## collisions, and then return. The next frame, it will continue where it left
## off.
func _process(_delta):
	var n = canvas.edges.size()
	var start_time: int = Time.get_ticks_msec()
	# print("Checking collisions between edges %d and %d" % [i, j])
	while Time.get_ticks_msec() - start_time < STOP_AFTER_MS:
		if i >= n:
			i = j
			j += 1
		if j >= n:
			j = 0
			return
		if i != j:
			check_collisions(i, j)
		i += 1


## Check if the edges at indices i and j are colliding. If they are, set their
## colors to the collision color.
func check_collisions(i: int, j: int):
	var edge1: Edge = canvas.edges[i]
	var edge2: Edge = canvas.edges[j]
	if edge1.check_collision_against(edge2):
		edge1.set_color(edge1.color_collision)
		edge2.set_color(edge2.color_collision)
		edge1.queue_redraw()
		edge2.queue_redraw()
