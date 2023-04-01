class_name NodeState extends State


func enter_state(_new_canvas: PuzzleCanvas):
	print("NodeState: enter_state")


## Called when the state is exited. After this there won't be any new events.
func exit_state():
	print("NodeState: exit_state")
