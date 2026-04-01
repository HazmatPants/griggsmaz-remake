extends Interactable

@onready var ap := $AudioStreamPlayer3D
@onready var label := $SubViewport/ColorRect/Label

const SFX_BUTTON = preload("res://assets/audio/sfx/buttons/Switch1.ogg")
const SFX_SLIDER = preload("res://assets/audio/sfx/buttons/Slide.ogg")

enum MODE {
	LOOP,
	LOOP_ONE,
	NO_LOOP
}

var shuffle := true

var playlist := &"builtin"

var files: PackedStringArray = []

var play_mode := MODE.NO_LOOP
var now_playing: String
var now_playing_idx: int

var is_open := false

var menu := 0

func interact():
	is_open = true

func _input(event: InputEvent) -> void:
	if not is_open: return
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_ESCAPE:
				is_open = false
				GLOBAL.player.can_move = true

			KEY_W:
				$Node3D/DPadUp.position.x = 0.04
				sfx_button()
				switch_playlist(&"builtin")
				play()
				show_status("Playlist: %s" % playlist)

			KEY_A:
				$Node3D/DPadLeft.position.x = 0.04
				sfx_button()
				now_playing_idx -= 1
				now_playing_idx = clampi(now_playing_idx, 0, files.size() - 1)
				play()
				show_status("Previous")

			KEY_S:
				$Node3D/DPadDown.position.x = 0.04
				sfx_button()
				switch_playlist(&"custom")
				play()
				show_status("Playlist: %s" % playlist)

			KEY_D:
				$Node3D/DPadRight.position.x = 0.04
				sfx_button()
				now_playing_idx += 1
				now_playing_idx = clampi(now_playing_idx, 0, files.size() - 1)
				play()
				show_status("Next")

			KEY_SPACE:
				ap.stream_paused = !ap.stream_paused
				if ap.stream_paused:
					show_status("Paused")
					Audio.playsound3d(
						preload("res://assets/audio/sfx/buttons/ButtonOff.ogg"),
						$Node3D/DPadCenter.position,
						0.2
					)
				else:
					show_status("Resumed")
					Audio.playsound3d(
						preload("res://assets/audio/sfx/buttons/ButtonOn.ogg"),
						$Node3D/DPadCenter.position,
						0.2
					)

			KEY_L:
				Audio.playsound3d(
					SFX_SLIDER,
					$Node3D/LoopSelectorBar/LoopSelector.position,
					0.4
				)
				if play_mode == MODE.NO_LOOP:
					play_mode = MODE.LOOP
					show_status("Loop")
				elif play_mode == MODE.LOOP:
					play_mode = MODE.LOOP_ONE
					show_status("Loop One")
				elif play_mode == MODE.LOOP_ONE:
					play_mode = MODE.NO_LOOP
					show_status("No Loop")

			KEY_EQUAL:
				sfx_button()
				ap.volume_linear += 0.0025
				show_status("VOL: %d%%" % [ap.volume_linear * 2000])

			KEY_MINUS:
				sfx_button()
				ap.volume_linear -= 0.0025
				show_status("VOL: %d%%" % [ap.volume_linear * 2000])

			KEY_C:
				shuffle = !shuffle
				if shuffle:
					show_status("Shuffle ON")
					Audio.playsound3d(
						preload("res://assets/audio/sfx/buttons/ButtonOff.ogg"),
						$Node3D/ShuffleButton.position,
						0.2
					)
				else:
					show_status("Shuffle OFF")
					Audio.playsound3d(
						preload("res://assets/audio/sfx/buttons/ButtonOn.ogg"),
						$Node3D/ShuffleButton.position,
						0.2
					)

func _process(_delta: float) -> void:
	if is_open:
		var tx = global_transform

		tx = tx.translated(global_basis.z / 3)

		GLOBAL.player.camera.global_transform = GLOBAL.player.camera.global_transform.interpolate_with(tx, 0.3)
		GLOBAL.player.can_move = false

		$SubViewport/ColorRect/StatusLabel.modulate.a = lerp($SubViewport/ColorRect/StatusLabel.modulate.a, 0.0, 0.1)

	ap.volume_linear = clampf(ap.volume_linear, 0.0, 0.2)

	if play_mode == MODE.NO_LOOP:
		$Node3D/LoopSelectorBar/LoopSelector.position.x = lerp($Node3D/LoopSelectorBar/LoopSelector.position.x, -0.045, 0.3)
	elif play_mode == MODE.LOOP:
		$Node3D/LoopSelectorBar/LoopSelector.position.x = lerp($Node3D/LoopSelectorBar/LoopSelector.position.x, 0.0, 0.3)
	elif play_mode == MODE.LOOP_ONE:
		$Node3D/LoopSelectorBar/LoopSelector.position.x = lerp($Node3D/LoopSelectorBar/LoopSelector.position.x, 0.045, 0.3)

	$Node3D/VolDial.rotation.z = lerp_angle($Node3D/VolDial.rotation.z, deg_to_rad(90) - ap.volume_linear * 100, 0.3) 

	if ap.stream_paused:
		$Node3D/DPadCenter.position.x = lerp($Node3D/DPadCenter.position.x, 0.04, 0.3) 
	else:
		$Node3D/DPadCenter.position.x = lerp($Node3D/DPadCenter.position.x, 0.055, 0.3) 

	if shuffle:
		$Node3D/ShuffleButton.position.x = lerp($Node3D/ShuffleButton.position.x, 0.04, 0.3) 
	else:
		$Node3D/ShuffleButton.position.x = lerp($Node3D/ShuffleButton.position.x, 0.055, 0.3) 

	$Node3D/DPadUp.position.x = lerp($Node3D/DPadUp.position.x, 0.055, 0.1) 
	$Node3D/DPadLeft.position.x = lerp($Node3D/DPadLeft.position.x, 0.055, 0.1) 
	$Node3D/DPadDown.position.x = lerp($Node3D/DPadDown.position.x, 0.055, 0.1) 
	$Node3D/DPadRight.position.x = lerp($Node3D/DPadRight.position.x, 0.055, 0.1)  

func _ready() -> void:
	ap.volume_linear = 0.05
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path("user://custom_music")):
		DirAccess.make_dir_absolute(ProjectSettings.globalize_path("user://custom_music"))
	switch_playlist(&"builtin")
	play()

func switch_playlist(target: StringName):
	now_playing_idx = 0
	now_playing = ""
	playlist = target

	match playlist:
		&"builtin":
			files = [
				"res://assets/audio/music/BIT SHREDDER.wav",
				"res://assets/audio/music/Take Care.ogg",
				"res://assets/audio/music/Dream.mp3",
				"res://assets/audio/music/idwtstwof.ogg",
				"res://assets/audio/music/every_light_is_blinking_at_once.ogg",
				"res://assets/audio/music/Sh Boom.ogg",
				"res://assets/audio/music/The Wanderer.ogg",
				"res://assets/audio/music/lhs_rld11.ogg",
			]
		&"custom":
			files = DirAccess.get_files_at("user://custom_music")
			if files.is_empty():
				files = [
					"res://assets/audio/music/Me When The Custom Music Folder Is Empty.ogg",
				]

func play():
	var stream: AudioStream

	if files.is_empty(): return

	var file = ""

	if shuffle:
		file = files[randi_range(0, files.size() - 1)]
		while file.get_file() == now_playing:
			file = files[randi_range(0, files.size() - 1)]
	else:
		file = files.get(now_playing_idx)

	if file.begins_with("res://"):
		stream = load(file)
	else:
		match file.get_extension():
			"wav":
				stream = AudioStreamWAV.load_from_file("user://custom_music/%s" % file)
			"mp3":
				stream = AudioStreamMP3.load_from_file("user://custom_music/%s" % file)
			"ogg":
				stream = AudioStreamOggVorbis.load_from_file("user://custom_music/%s" % file)

	now_playing = file
	ap.stream = stream
	ap.play()

	label.text = "Now Playing: %s\nPlaylist: %s\n" % [now_playing.get_file(), playlist.capitalize()]

	if playlist == &"custom":
		label.text += "--- Custom music folder ---\n%s" % ProjectSettings.globalize_path("user://custom_music")

	await ap.finished

	if play_mode == MODE.LOOP_ONE:
		ap.play()
	if play_mode == MODE.LOOP:
		if now_playing_idx == files.size() - 1:
			now_playing_idx = 0
			play()
		else:
			now_playing_idx += 1
	if play_mode == MODE.NO_LOOP:
		now_playing = ""
		return

func show_status(text: String):
	$SubViewport/ColorRect/StatusLabel.text = text
	$SubViewport/ColorRect/StatusLabel.modulate.a = 1.0

func is_key_pressed(key: Key):
	return Input.is_key_pressed(key) and is_open

func sfx_button():
	Audio.playsound3d(
		SFX_BUTTON,
		global_position,
		0.07,
		"SFX",
		2.0
	)
