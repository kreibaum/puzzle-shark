class_name EdgeInspector extends VBoxContainer

@export var canvas: PuzzleCanvas


# Called when the node enters the scene tree for the first time.
func _ready():
	canvas.selection_changed.connect(_on_selection_changed)
	$SingleEdgeView/LinePreview.visible = false

	$SmallEdgeButtons/LongerEdgeButton.pressed.connect(grow_edge)
	$SmallEdgeButtons/ShorterEdgeButton.pressed.connect(shrink_edge)
	$SmallEdgeButtons/LeftShiftEdgeButton.pressed.connect(left_shift_edge)
	$SmallEdgeButtons/RightShiftEdgeButton.pressed.connect(right_shift_edge)


var click_started_on_button = null


func hovered_button() -> Button:
	if $SmallEdgeButtons/LongerEdgeButton.is_hovered():
		return $SmallEdgeButtons/LongerEdgeButton
	if $SmallEdgeButtons/ShorterEdgeButton.is_hovered():
		return $SmallEdgeButtons/ShorterEdgeButton
	if $SmallEdgeButtons/LeftShiftEdgeButton.is_hovered():
		return $SmallEdgeButtons/LeftShiftEdgeButton
	if $SmallEdgeButtons/RightShiftEdgeButton.is_hovered():
		return $SmallEdgeButtons/RightShiftEdgeButton
	return null


func _input(event):
	var button = hovered_button()
	if button != null || click_started_on_button:
		if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				click_started_on_button = button
				get_viewport().set_input_as_handled()
			elif button == click_started_on_button:
				click_started_on_button = null
				_on_Button_pressed(button)
				get_viewport().set_input_as_handled()
			else:
				click_started_on_button = null
				get_viewport().set_input_as_handled()


func _on_Button_pressed(button: Button):
	if button == $SmallEdgeButtons/LongerEdgeButton:
		grow_edge()
	elif button == $SmallEdgeButtons/ShorterEdgeButton:
		shrink_edge()
	elif button == $SmallEdgeButtons/LeftShiftEdgeButton:
		left_shift_edge()
	elif button == $SmallEdgeButtons/RightShiftEdgeButton:
		right_shift_edge()


func _on_selection_changed():
	var selected_edges = canvas.get_selected_edges()
	var edge_count = selected_edges.size()
	if edge_count == 0:
		$SelectionLabel.text = "No Selection"
	elif edge_count == 1:
		$SelectionLabel.text = "1 Edge"
		# If there is only a single edge, we want to display it in the inspector
		# so that the user can edit it.
		var edge: Edge = selected_edges[0]
		var points = edge.get_shape_points().duplicate()
		# Transform the edge so that it has the correct position and rotation.
		var w = $SingleEdgeView.size.x - 10
		var h = $SingleEdgeView.size.y
		var transform = FixedPointTransform2D.build_transformation_matrix(
			points[0], points[-1], Vector2(5, h / 2), Vector2(w, h / 2)
		)
		if transform:
			$SingleEdgeView/LinePreview.points = transform * points

	else:
		$SelectionLabel.text = "%d Edges" % edge_count

	$SingleEdgeView/LinePreview.visible = edge_count == 1


func grow_edge():
	shift_ends(5, -5)


func shrink_edge():
	shift_ends(-5, 5)


func left_shift_edge():
	shift_ends(5, 5)


func right_shift_edge():
	shift_ends(-5, -5)


func shift_ends(lShift: float, rShift: float):
	var selected_edges = canvas.get_selected_edges()
	for edge in selected_edges:
		# Get both controll nodes at each end of the edge.
		# Move them apart / towards each other.
		# This depends on the skeleton already being normalized.
		var points = edge.skeleton
		points[0] += Vector2(lShift, 0)
		points[-1] += Vector2(rShift, 0)

		edge.set_skeleton(points)
		edge.update()
		canvas.selection_changed.emit()
