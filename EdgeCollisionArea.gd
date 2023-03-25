class_name EdgeCollisionArea extends Area2D


## Takes the shape of an Edge2D that has already been transformed into
## world space and creates a collision area that matches the shape of the edge.
##
## We must first transform the edge into world space because otherwise
## long edges would have a collision area that is too wide.
##
## The approach we take is to place a rectangular collision shape at each
## segment of the non-smooth edge template.
func recalculate(edge_shape: PackedVector2Array):
	# Delete all child nodes
	for child in get_children():
		child.queue_free()

	var width: float = 5.0

	# Special case for the border of the puzzle. If the edge is strait,
	# we make a single rectangle that is 80% of the width of the edge.
	if edge_shape.size() == 2:
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()

		var left = edge_shape[0]
		var right = edge_shape[1]

		rect.size = Vector2(left.distance_to(right) * 0.8, width)
		shape.set_shape(rect)

		shape.transform = Transform2D((right - left).angle(), left + (right - left) / 2.0)

		add_child(shape)
		return

	# Create new collision shapes
	# We also want to drop 10% on each vertex to avoid collision with the
	# edges legitimately connected to the vertex.
	# We approximate 10% by dropping 10% of the indices on each side.
	var ten_pct = int(edge_shape.size() / 10.0)
	for i in range(ten_pct, edge_shape.size() - 1 - ten_pct):
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()

		var left = edge_shape[i]
		var right = edge_shape[i + 1]

		rect.size = Vector2(left.distance_to(right), width)
		shape.set_shape(rect)

		shape.transform = Transform2D((right - left).angle(), left + (right - left) / 2.0)

		add_child(shape)
