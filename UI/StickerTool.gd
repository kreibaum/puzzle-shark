class_name StickerTool extends State

## This Tool allows you to move around stickers and to attach vertices to
## stickers.
##
## - [x] Add a way to select a sticker and move it around.
## - [ ] Make it possible to snap a vertex to a sticker.
## - [ ] Make the vertex actually stick to the sticker.

var sticker_in_hand: Sticker = null
var last_mouse_position: Vector2 = Vector2.INF


func handle_event_ignoring_source(event: InputEvent):
	# Mouse button with a sticker in hand will always be consumed. It will
	# drop the sticker in place.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if !event.is_pressed():
				sticker_in_hand = null
				last_mouse_position = Vector2.INF
				set_input_as_handled()
	elif event is InputEventMouseMotion:
		if sticker_in_hand != null && (event.button_mask & MOUSE_BUTTON_LEFT):
			var new_position = canvas.get_global_mouse_position()
			if last_mouse_position != Vector2.INF:
				var delta = new_position - last_mouse_position
				canvas.move_sticker_by(sticker_in_hand, delta)
			last_mouse_position = new_position
			set_input_as_handled()
	if event.is_action_pressed("ZoomIn") && sticker_in_hand != null:
		if Input.is_key_pressed(KEY_CTRL):
			canvas.rotate_sticker(sticker_in_hand, -10.0 * PI / 180.0)
		else:
			canvas.zoom_sticker(sticker_in_hand, 1.0 / 1.1)
		set_input_as_handled()
	elif event.is_action_pressed("ZoomOut") && sticker_in_hand != null:
		if Input.is_key_pressed(KEY_CTRL):
			canvas.rotate_sticker(sticker_in_hand, 10.0 * PI / 180.0)
		else:
			canvas.zoom_sticker(sticker_in_hand, 1.1)
		set_input_as_handled()


func sticker_input_event(sticker: Sticker, event: InputEvent):
	# TODO: We now have two kinds of objects that we can drag around with the mouse.
	# We should really make a helper class for the information we need to do this.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				sticker_in_hand = sticker
				last_mouse_position = canvas.get_global_mouse_position()
				set_input_as_handled()
	handle_event_ignoring_source(event)


func unhandled_input(event: InputEvent):
	handle_event_ignoring_source(event)
