class_name ReloadDebugHotkey extends Node

@export var canvas: PuzzleCanvas
@export var state_machine: StateMachine


func _input(_event):
	if Input.is_action_just_pressed("ReloadDebugHotkey"):
		print("ReloadDebugHotkey")
		# Stop the current tool
		state_machine.set_state(SelectTool.new())
		# TODO: Tell the state grid

		# Reload everything going through serialization
		var serialized = CanvasSerializer.serialize(canvas)

		print(JSON.stringify(serialized))

		CanvasSerializer.deserialize(canvas, serialized)
		# Restart the current tool
		pass
