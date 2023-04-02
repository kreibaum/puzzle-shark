class_name StateGrid extends ItemList

## The state grid is in charge of displaying the state of the ui state machine.
## It also takes inputs which allow the user to switch into a different state.
## This switch is then done by the state machine.

## An issue with cleanly coding this is that the information we get on item
## selection is the index of the item in the list. To make this robust, we
## actually fill the ItemList programatically when ready. This makes sure
## we don't go out of sync.

@export var state_machine: StateMachine

# Poor man's struct
const LABEL_INDEX = 0
const SHORTCUT_INDEX = 1
const CONSTRUCTOR_INDEX = 2


func state_definitions():
	return [
		["Select", KEY_X, func(): return SelectTool.new()],
		["Delete", KEY_V, func(): return DeleteTool.new()],
		["Create", KEY_U, func(): return CreateTool.new()],
		["Sculpt", KEY_I, func(): return SelectTool.new()]
	]


# Called when the node enters the scene tree for the first time.
func _ready():
	self.item_selected.connect(on_item_selected)
	clear()
	for state in state_definitions():
		add_item(state[LABEL_INDEX])
	select(0)


## Changes the current state of the state machine to the given state.
func select_state(state):
	state_machine.set_state(state[CONSTRUCTOR_INDEX].call())


## Click handler that finds the state that matches the index and switches to it.
func on_item_selected(index):
	select_state(state_definitions()[index])


## Looks for key events and switches to the state that matches the key.
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		var key_event = event as InputEventKey
		# Find the state that matches the key
		for index in range(state_definitions().size()):
			if state_definitions()[index][SHORTCUT_INDEX] == key_event.keycode:
				if !is_selected(index):
					select_state(state_definitions()[index])
					select(index)
				return
