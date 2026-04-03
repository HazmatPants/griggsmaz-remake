extends Node3D

@onready var generator := $Generator
@onready var o2_generator := $OxygenGenerator

var id := ""

var oxygen := 0.2
var air_pressure := 101.0

func _ready() -> void:
	GLOBAL.player_init()

	var id_string = Marshalls.utf8_to_base64(str(randi()))

	id = id_string.substr(0, id_string.length() - 2)

func _process(_delta: float) -> void:
	air_pressure = 101.0 * (oxygen + 0.8)

	oxygen = clampf(oxygen, 0.0, 1.0)
