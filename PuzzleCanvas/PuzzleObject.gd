class_name PuzzleObject extends Area2D

# Object states
# Object states both influence the visual appearance and the functionality of
# an object. For example, objects in a virtual state are usually dimmed down and
# are not interactive.
@export var active: bool = false
@export var focused: bool = false
@export var virtual: bool = false

# Manipulate the object state. These functions are mainly responsible for
# adapting the visual appearance of an object, like proper highlighting on
# picking.
func _set_active(_value): pass	
func _set_focused(_value): pass
func _set_virtual(_value): pass

func set_active(value, force = false):
	if force or value != active:
		active = value
		_set_active(value)

func set_focused(value, force = false):
	if force or value != focused:
		if value and not focused:
			z_index += 1
		elif not value and focused:
			z_index -= 1
		focused = value
		_set_focused(value)

func set_virtual(value, force = false):
	if force or value != virtual:
		virtual = value
		_set_virtual(value)

## Signal to notify a position / transformation change
signal position_changed

## Assume the next available anchor modes of the object.
## Some types of anchoring might rely on the current context,
## which is by default represented by an array of objects (hovered objects)
func cycle_anchor_mode(_context_objects: Array = [], _backwards = false):
	pass

func set_anchor_mode(_mode, _context_array: Array = []) -> bool:
	return true

# Captured hover events are processed by the puzzle
# canvas, which organizes a list of currently hovered objects.
signal captured_hover_event(PuzzleObject, bool)

func _mouse_enter():
	captured_hover_event.emit(self, true)

func _mouse_exit():
	captured_hover_event.emit(self, false)

## Temporarily store the current spatial positioning information of the object.
## Subsequent positional changes can be reset via restore_position()
func store_position(): pass	

## Remove the currently stored position information from the object
func unstore_position(): pass

## Restore a previously stored position
func restore_position(): pass

## React to a change in the camera zoom value. This can include updates of
## the apperance, since Puzzle Objects are assumed to be zoom- independent GUI
## elements that live on the Node2d canvas.
func on_zoom_change(_value):
	pass

## Project a vector onto the puzzle object. This is used for snapping
## functionality.
func project_onto_object(pos: Vector2):
	return pos

