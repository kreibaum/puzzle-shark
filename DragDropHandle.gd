extends Area2D

var drag_offset : Vector2 = Vector2(0, 0)
var is_dragging : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.s

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if is_dragging:
		var mouse_at = get_global_mouse_position()
		self.position = mouse_at + drag_offset;

# Called when the mouse is pressed
func _input_event(_viewport, event, _shape_index):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				var mouse_at = get_global_mouse_position()
				drag_offset = self.position - mouse_at
				is_dragging = true
			else:
				is_dragging = false
