extends Interactable

@onready var label = $Label3D

@export var text := ""

signal pressed

func _ready() -> void:
	label.text = text

func interact():
	Audio.playsound3d(
		preload("res://assets/audio/sfx/buttons/Switch2.ogg"),
		global_position,
		0.05
	)
	pressed.emit()
