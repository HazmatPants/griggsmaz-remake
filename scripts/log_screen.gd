extends Interactable

@onready var term_output: TextEdit = $SubViewport/ColorRect/TextEdit

var is_terminal_open := false

func interact():
	is_terminal_open = true

func _process(_delta: float) -> void:
	if is_terminal_open:
		var tx = global_transform

		tx = tx.translated(global_basis.z)

		GLOBAL.player.camera.global_transform = GLOBAL.player.camera.global_transform.interpolate_with(tx, 0.3)
		GLOBAL.player.can_move = false

		if Input.is_action_just_pressed("escape"):
			is_terminal_open = false
			GLOBAL.player.can_move = true

func log_text(output_text: String="", nl: bool=true):
	term_output.text += output_text
	if nl:
		term_output.text += "\n"
