extends Camera2D

signal zoom_changed(float)

@onready var zoom_target: Vector2 = self.zoom
var zoom_tween: Tween

var drag_tween: Tween
var drag_prev_time: float
var drag_velocity: Vector2 = Vector2(0, 0)
var drag_fixpoint: Vector2
var drag_ongoing: bool

func _process(_delta: float):
	if self.drag_ongoing: drag_while()

func _unhandled_input(event):
	# Disable the camera when pressing ctrl
	if Input.is_key_pressed(KEY_CTRL):
		return

	if Input.is_action_just_pressed("Drag"):
		drag_start()
	elif Input.is_action_just_released("Drag"):
		drag_stop()
		
	if event.is_action_pressed("ZoomIn"):
		zoom_at_mouse_smooth(self.zoom_target * 0.8)
	elif event.is_action_pressed("ZoomOut"):
		zoom_at_mouse_smooth(self.zoom_target / 0.8)


func drag_timestamp():
	var time = Time.get_ticks_msec()
	var dt = time - self.drag_prev_time
	self.drag_prev_time = time
	return dt
	
func drag_start():
	self.drag_fixpoint = get_global_mouse_position()
	self.drag_velocity = Vector2(0,0)
	self.drag_ongoing = true
	if self.drag_tween: self.drag_tween.kill()
	
func drag_while():
	var dt = drag_timestamp()
	var diff = self.drag_fixpoint - get_global_mouse_position()
	self.drag_velocity = 0.8 * self.drag_velocity + 0.2 * diff / dt
	self.position += diff

func drag_stop():
	var velocity
	self.drag_ongoing = false
	self.drag_tween = create_tween()
	if self.drag_velocity.length() > 10:
		velocity = self.drag_velocity.normalized() * 10
	else:
		velocity = self.drag_velocity
	self.drag_tween.tween_method(drag_glide, velocity, Vector2(0, 0), 0.4)

func drag_glide(velocity: Vector2):
	var dt = drag_timestamp()
	self.drag_velocity = velocity
	self.position += velocity * dt

func zoom_at_mouse_smooth(zoom_level: Vector2):
	self.zoom_target = zoom_level
	# That is the official way to set a new tween target
	if self.zoom_tween: self.zoom_tween.kill()
	self.zoom_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	self.zoom_tween.tween_method(zoom_at_mouse, self.zoom, zoom_target, 0.75)

func zoom_at_mouse(zoom_level: Vector2):
	# Get the factor by which we zoom and calculate the necessary shift for the
	# camera
	var zoom_factor = zoom_level.x / self.zoom.x
	var mouse_position = get_global_mouse_position()
	var delta = (mouse_position - self.position) * (zoom_factor - 1)

	# We first have to shift the camera and then have to zoom. However, this
	# changes the mouse position slightly, so we reposition it to its previous
	# position afterwards. Also, unpleasant effects happen if the zoom-
	# repositioning interacts with dragging. The best solutions seems to be to
	# let drag handle the position in these cases.
	if not drag_ongoing:
		self.position += delta
	self.zoom = zoom_level
	if not drag_ongoing:
		self.position -= get_global_mouse_position() - mouse_position

	# Show the world that the zoom level just changed
	zoom_changed.emit(self.zoom)
