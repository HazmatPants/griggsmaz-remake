extends Node

func playsound3d(stream: AudioStream, global_position: Vector3, volume_linear: float=1.0, bus: StringName=&"SFX", pitch_scale: float=1.0) -> AudioStreamPlayer3D:
	var ap := AudioStreamPlayer3D.new()

	ap.stream = stream
	ap.volume_linear = volume_linear
	ap.bus = bus
	ap.pitch_scale = pitch_scale
	ap.autoplay = true
	ap.finished.connect(ap.queue_free)

	get_tree().current_scene.add_child(ap)

	ap.global_position = global_position

	return ap

func playsound(stream: AudioStream, volume_linear: float=1.0, bus: StringName=&"SFX"):
	var ap := AudioStreamPlayer.new()

	ap.stream = stream
	ap.volume_linear = volume_linear
	ap.bus = bus
	ap.autoplay = true
	ap.finished.connect(ap.queue_free)

	get_tree().current_scene.add_child(ap)

func playrandom3d(sound_list: Array, global_position: Vector3, volume_linear: float=1.0, bus: StringName=&"SFX"):
	if sound_list.is_empty(): return

	var idx = randi_range(0, sound_list.size() - 1)

	playsound3d(sound_list[idx], global_position, volume_linear, bus)

func playrandom(sound_list: Array[AudioStream], volume_linear: float=1.0, bus: StringName=&"SFX"):
	if sound_list.is_empty(): return

	var idx = randi_range(0, sound_list.size() - 1)

	playsound(sound_list[idx], volume_linear, bus)

func _process(_delta: float) -> void:
	var lowpass = AudioServer.get_bus_effect(1, 1).cutoff_hz

	lowpass = lerpf(lowpass, lerpf(0.0, 20500, ease(GLOBAL.player.consciousness, 3.0)), 0.05)

	AudioServer.get_bus_effect(1, 1).cutoff_hz = lowpass

	AudioServer.set_bus_effect_enabled(1, 2, GLOBAL.player.consciousness < 0.5)
