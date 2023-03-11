extends Camera2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
			self.position -= event.relative / self.zoom
	elif event.is_action_pressed("ZoomIn"):
		zoom_at_mouse(0.9)
	elif event.is_action_pressed("ZoomOut"):
		zoom_at_mouse(1.0/0.9)

func zoom_at_mouse(zoom_change:float):
	var mouse_old = get_global_mouse_position()
	self.zoom *= zoom_change
	var mouse_new = get_global_mouse_position()
	var relative = mouse_new - mouse_old
	self.position -= relative 
