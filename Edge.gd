extends Node2D

@export var left_handle : DragDropHandle
@export var right_handle : DragDropHandle

@onready var edge_shape = $EdgeShape

# Called when the node enters the scene tree for the first time.
func _ready():
	print(self, "is ready", left_handle, right_handle)
	left_handle.position_changed.connect(update_position)
	right_handle.position_changed.connect(update_position)
	update_position()
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	
	# First, move left to 0.
	# Transform2D(0, Vector2.ZERO, 0, -left)
	var scale = Vector2(target_length / shape_length, target_length / shape_length)
	var transform = Transform2D(target_angle - shape_angle, scale, 0, left_handle.position - left)
	# var transform = Transform2D(target_angle - shape_angle, 0, 0, left_handle.position - left)
	
	self.transform = transform

