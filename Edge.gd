extends Node2D

@export var left_handle : DragDropHandle
@export var right_handle : DragDropHandle

@onready var edge_shape = $EdgeShape

# Called when the node enters the scene tree for the first time.
# At this point, all other nodes already exist, even though they may not be
# members of the scene tree yet.
func _ready():
	left_handle.position_changed.connect(update_position)
	right_handle.position_changed.connect(update_position)
	
	# Initial alignment
	update_position()


# Called to set up the edge in the correct position and then again whenever one
# of the handles moves.
func update_position():
	if left_handle == null or right_handle == null:
		return
	
	var left : Vector2 = edge_shape.get_point_position(0)
	var right : Vector2 = edge_shape.get_point_position(edge_shape.get_point_count()-1)
		
	var baseline = right - left
	var shape_length = baseline.length()
	var shape_angle = baseline.angle()
	
	var target_baseline = right_handle.position - left_handle.position
	var target_length = target_baseline.length()
	var target_angle = target_baseline.angle()
	
	var scale = Vector2(target_length / shape_length, target_length / shape_length)
	
	# It is important that we first move
	var zero_out = Transform2D(0, Vector2.ONE, 0, -left)
	var transform = Transform2D(target_angle - shape_angle, scale, 0, left_handle.position) * zero_out
	# var transform = Transform2D(target_angle - shape_angle, scale, 0, left_handle.position - left)
	
	self.transform = transform

