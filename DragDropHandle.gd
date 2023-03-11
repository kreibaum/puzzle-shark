class_name DragDropHandle extends Area2D

var drag_offset : Vector2 = Vector2(0, 0)
var is_dragging : bool = false
var hovered : bool = false
var in_selection : bool = false : 
	set(value):
		in_selection = value
		update_color()

@export var camera: Camera2D

signal position_changed

# Called when the node enters the scene tree for the first time.
func _ready():
	camera.zoom_changed.connect(update_zoom)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_dragging:
		var mouse_at = get_global_mouse_position()
		move_to(mouse_at + drag_offset)

# Sets the position and triggers the signal so dependent objects can update.
func move_to(new_position):
	if self.position != new_position:
		self.position = new_position
		position_changed.emit()

func transform(transformation: Transform2D):
	self.position = transformation * self.position
	position_changed.emit()

# Called when the mouse is pressed
func _input_event(_viewport, event, _shape_index):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var mouse_at = get_global_mouse_position()
				drag_offset = self.position - mouse_at
				is_dragging = true
			else:
				is_dragging = false

func _mouse_enter():
	hovered = true
	update_color()
	
func _mouse_exit():
	hovered = false
	update_color()

func update_color():
	if hovered or in_selection:
		$Polygon2D.color = "eb00cf"
	else:
		$Polygon2D.color = "ad40a0"

func update_zoom(zoom):
	self.scale = Vector2(1/zoom.x, 1/zoom.y)
