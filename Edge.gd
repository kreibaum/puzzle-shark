extends Node2D

var left_handle
var right_handle

@onready var edge_shape = $EdgeShape

# Called when the node enters the scene tree for the first time.
func _ready():
	left_handle = $"../Handle A"
	right_handle = $"../Handle B"
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var left : Vector2 = edge_shape.get_point_position(0)
	var right : Vector2 = edge_shape.get_point_position(edge_shape.get_point_count()-1)
		
	var baseline = right - left
	var shape_length = baseline.length()
	var shape_angle = baseline.angle()
	
	var target_baseline = right_handle.position - left_handle.position
	var target_length = target_baseline.length()
	var target_angle = target_baseline.angle()
	
	# First, move left to 0.
	# Transform2D(0, Vector2.ZERO, 0, -left)
	var scale = Vector2(target_length / shape_length, target_length / shape_length)
	var transform = Transform2D(target_angle - shape_angle, scale, 0, left_handle.position - left)
	# var transform = Transform2D(target_angle - shape_angle, 0, 0, left_handle.position - left)
	
	self.transform = transform

