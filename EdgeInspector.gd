class_name EdgeInspector extends VBoxContainer

@export var canvas: PuzzleCanvas


# Called when the node enters the scene tree for the first time.
func _ready():
	canvas.selection_changed.connect(_on_selection_changed)
	$SingleEdgeView/LinePreview.visible = false


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
		$SingleEdgeView/LinePreview.points = transform * points

	else:
		$SelectionLabel.text = "%d Edges" % edge_count

	$SingleEdgeView/LinePreview.visible = edge_count == 1
