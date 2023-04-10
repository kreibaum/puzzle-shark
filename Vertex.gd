class_name Vertex extends PuzzleObject

# Store the current position in order to be able to undo drag events
var stored_position: Vector2 = Vector2.INF

## Anchor options of a vertex
enum ANCHOR {
	FREE = 0,
	VERTICAL = 1,
	HORIZONTAL = 2,
	CANVAS = 3,
	STICKER = 4,
}

var anchor: ANCHOR
var anchor_sticker: Sticker
var anchor_sticker_inv_transform: Transform2D

func inset_shape_free():
	var points = PackedVector2Array()
	for index in range(0,16):
		var angle = index * PI / 8
		var point = 4 * Vector2(cos(angle), sin(angle))
		points.append(point)
	return points

func inset_shape_vertical():
	var points = PackedVector2Array()
	points.append(Vector2(-2, -6))
	points.append(Vector2(2, -6))
	points.append(Vector2(2, 6))
	points.append(Vector2(-2, 6))
	return points

func inset_shape_horizontal():
	var points = PackedVector2Array()
	points.append(Vector2(-6, -2))
	points.append(Vector2(6, -2))
	points.append(Vector2(6, 2))
	points.append(Vector2(-6, 2))
	return points

func inset_shape_canvas():
	var points = PackedVector2Array()
	points.append(Vector2(-6, -2))
	points.append(Vector2(-2, -2))
	points.append(Vector2(-2, -6))
	points.append(Vector2(2, -6))
	points.append(Vector2(2, -2))
	points.append(Vector2(6, -2))
	points.append(Vector2(6, 2))
	points.append(Vector2(2, 2))
	points.append(Vector2(2, 6))
	points.append(Vector2(-2, 6))
	points.append(Vector2(-2, 2))
	points.append(Vector2(-6, 2))
	return points

func inset_shape_sticker():
	var points = PackedVector2Array()
	points.append(Vector2(-4, -4))
	points.append(Vector2(4, -4))
	points.append(Vector2(4, 4))
	points.append(Vector2(-4, 4))
	return points


## Update the visual indicator (the inset) that displays the current vertex
## anchoring
func set_inset_shape(given_anchor: ANCHOR):
	var points
	if given_anchor == ANCHOR.FREE:
		points = inset_shape_free()
	elif given_anchor == ANCHOR.VERTICAL:
		points = inset_shape_vertical()
	elif given_anchor == ANCHOR.HORIZONTAL:
		points = inset_shape_horizontal()
	elif given_anchor == ANCHOR.CANVAS:
		points = inset_shape_canvas()
	elif given_anchor == ANCHOR.STICKER:
		points = inset_shape_sticker()
	$Inset.set_polygon(points)

func find_sticker(context: Array):
	for index in range(len(context)-1, -1, -1):
		var object = context[index]
		if object is Sticker:
			return object

func set_anchor_mode(new_anchor: ANCHOR, context: Array = []):
	# If the previous anchor mode was STICKER, release the sticker that
	# was held
	if anchor == ANCHOR.STICKER:
		anchor_sticker.position_changed.disconnect(follow_sticker)
		anchor_sticker.unanchor_vertex(self)
		anchor_sticker = null

	if new_anchor in [ANCHOR.FREE, ANCHOR.VERTICAL, ANCHOR.HORIZONTAL, ANCHOR.CANVAS]:
		anchor = new_anchor
		set_inset_shape(anchor)
		return true
	else:
		var sticker = find_sticker(context)
		if sticker != null:
			anchor = ANCHOR.STICKER
			anchor_sticker = sticker
			anchor_sticker_inv_transform = sticker.transform.affine_inverse()
			anchor_sticker.position_changed.connect(follow_sticker)
			sticker.anchor_vertex(self)
			follow_sticker()
			set_inset_shape(anchor)
			return true
		else:
			return false
			
func follow_sticker():
	if anchor_sticker != null:
		var diff_transform = anchor_sticker.transform * anchor_sticker_inv_transform
		var target_position = diff_transform * position
		position = anchor_sticker.project_onto_object(target_position)
		position_changed.emit()
		anchor_sticker_inv_transform = anchor_sticker.transform.affine_inverse()

# TODO: This should become part of the PuzzleObject interface
func cycle_anchor_mode(context: Array = [], backwards = false):
	var next_mode = anchor
	while true:
		if backwards:
			next_mode = (next_mode + 4) % 5 as ANCHOR
		else:
			next_mode = (next_mode + 1) % 5 as ANCHOR
		if set_anchor_mode(next_mode, context):
			break

func apply_anchor_constraints(point: Vector2):
	var new_point = Vector2(point)
	if anchor == ANCHOR.VERTICAL:
		new_point.x = position.x
	elif anchor == ANCHOR.HORIZONTAL:
		new_point.y = position.y
	elif anchor == ANCHOR.CANVAS or anchor == ANCHOR.STICKER:
		new_point = position
	return new_point		

func _ready():
	set_inset_shape(anchor)
		

#
# PuzzleObject interface
#

func _set_virtual(value):
	if value:
		self.modulate = Color(1, 1, 1, 0.5)
		$CollisionShape2D.disabled = true
	else:
		self.modulate = Color(1, 1, 1, 1)
		$CollisionShape2D.disabled = false

func _set_focused(value):
	if value:
		self.modulate = Color(1.2, 1.2, 1.2)
	else:
		self.modulate = Color(1, 1, 1)

func _set_active(value):
	if value:
		$Background.color = "cc9766"
		$Inset.color = "3d3d3d"
		$Outline.default_color = "3d3d3d"
	else:
		$Background.color = "7aa2c4"
		$Inset.color = "3d3d3d"
		$Outline.default_color = "3d3d3d"

func store_position():
	stored_position = position

func unstore_position():
	stored_position = Vector2.INF

func restore_position():
	position = stored_position
	unstore_position()
	position_changed.emit()

func on_zoom_change(zoom: Vector2):
	self.scale = Vector2(1 / zoom.x, 1 / zoom.y)

func project_onto_object(_pos: Vector2):
	return global_position

