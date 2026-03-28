extends Node

func playsound3d(stream: AudioStream, global_position: Vector3, volume_linear: float=1.0, bus: StringName=&"SFX", pitch_scale: float=1.0):
	var ap := AudioStreamPlayer3D.new()

	ap.stream = stream
	ap.volume_linear = volume_linear
	ap.bus = bus
	ap.autoplay = true
	ap.pitch_scale = pitch_scale
	ap.finished.connect(ap.queue_free)

	get_tree().current_scene.add_child(ap)

	ap.global_position = global_position

func playsound(stream: AudioStream, volume_linear: float=1.0, bus: StringName=&"SFX"):
	var ap := AudioStreamPlayer.new()

	ap.stream = stream
	ap.volume_linear = volume_linear
	ap.bus = bus
	ap.autoplay = true
	ap.finished.connect(ap.queue_free)

	get_tree().current_scene.add_child(ap)

func playrandom3d(sound_list: Array, global_position: Vector3, volume_linear: float=1.0, bus: StringName=&"SFX"):
	var idx = randi_range(0, sound_list.size() - 1)

	playsound3d(sound_list[idx], global_position, volume_linear, bus)

func playrandom(sound_list: Array[AudioStream], volume_linear: float=1.0, bus: StringName=&"SFX"):
	var idx = randi_range(0, sound_list.size() - 1)

	playsound(sound_list[idx], volume_linear, bus)
