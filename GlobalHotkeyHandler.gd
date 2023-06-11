class_name ReloadDebugHotkey extends Node

@export var canvas: PuzzleCanvas
@export var state_machine: StateMachine


func _ready():
	$SaveFileDialog.add_filter("*.shark", "Puzzle Shark Project Files")
	$SaveFileDialog.file_selected.connect(save_puzzle)

	$LoadFileDialog.add_filter("*.shark", "Puzzle Shark Project Files")
	$LoadFileDialog.file_selected.connect(load_puzzle)

	$ExportFileDialog.add_filter("*.svg", "Scalable Vector Graphics")
	$ExportFileDialog.file_selected.connect(export_puzzle)


func _input(_event):
	if Input.is_action_just_pressed("ReloadDebugHotkey"):
		print("ReloadDebugHotkey")
		stop_current_tool()

		# Reload everything going through serialization
		var serialized = CanvasSerializer.serialize(canvas)

		print(JSON.stringify(serialized))

		CanvasSerializer.deserialize(canvas, serialized)

	if Input.is_action_just_pressed("SavePuzzle"):
		# Ask the user where to save the .shark file and to give a file name.
		$SaveFileDialog.size = get_window().get_size()
		$SaveFileDialog.show()

	if Input.is_action_just_pressed("LoadPuzzle"):
		# Ask the user where to load the .shark file.
		$LoadFileDialog.size = get_window().get_size()
		$LoadFileDialog.show()

	if Input.is_action_just_pressed("ExportPuzzle"):
		# Ask the user where to save the .svg file.
		$ExportFileDialog.size = get_window().get_size()
		$ExportFileDialog.show()


func save_puzzle(target_file_path):
	print("Saving puzzle to " + target_file_path)
	var serialized = CanvasSerializer.serialize(canvas)

	var file = FileAccess.open(target_file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(serialized))
	file.close()


func load_puzzle(source_file_path):
	print("Loading puzzle from " + source_file_path)
	var file = FileAccess.open(source_file_path, FileAccess.READ)
	var serialized = JSON.parse_string(file.get_as_text())
	file.close()

	stop_current_tool()
	CanvasSerializer.deserialize(canvas, serialized)


func export_puzzle(target_file_path):
	print("Exporting puzzle to " + target_file_path)
	var file = FileAccess.open(target_file_path, FileAccess.WRITE)
	var export_rope = CanvasSerializer.exportToSvg(canvas)

	for line in export_rope:
		file.store_string(line)

	file.close()


func stop_current_tool():
	state_machine.set_state(SelectTool.new())
	# TODO: Tell the state grid
