extends Node2D

var handle_scene = preload("res://drag_drop_handle.tscn")
var edge_scene = preload("res://edge.tscn")

@export var camera: Camera2D

var points = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	var w = 5
	var h = 3
	for x in range(0, w):
		for y in range(0, h):
			var handle = handle_scene.instantiate()
			points[Vector2i(x, y)] = handle
			handle.position = Vector2(200 * x, 200 * y)
			handle.z_index = 2
			add_child(handle)
	
	for x in range(1, w):
		for y in range(0, h):
			var edge : Edge = edge_scene.instantiate()
			edge.left_handle = points[Vector2i(x-1, y)]
			edge.right_handle = points[Vector2i(x, y)]
			add_child(edge)
	
	for x in range(0, w):
		for y in range(1, h):
			var edge : Edge = edge_scene.instantiate()
			edge.left_handle = points[Vector2i(x, y-1)]
			edge.right_handle = points[Vector2i(x, y)]
			add_child(edge)



