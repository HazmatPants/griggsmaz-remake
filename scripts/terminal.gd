extends Interactable

@onready var term_output: TextEdit = $SubViewport/ColorRect/TextEdit

var is_teminal_open := false

var scroll_amount: int = 0

signal enter_pressed

func interact():
	is_teminal_open = true

var term_config := {
	"cursor_blink_rate": 0.15
}

var can_input: bool = false
var max_backspace: int = 9999

var current_input: String = ""
var cursor_pos: int = 0
var hide_current_input: bool = false
var CURSOR := "_"

var cursor_blink_timer = Timer.new()

func _ready() -> void:
	term_output.get_v_scroll_bar().visible = false

	cursor_blink_timer.wait_time = 0.15
	cursor_blink_timer.autostart = true
	cursor_blink_timer.timeout.connect(_cursor_blink)
	add_child(cursor_blink_timer)

	if term_config["cursor_blink_rate"] < 0.0:
		cursor_blink_timer.stop()
		CURSOR = "_"
	else:
		cursor_blink_timer.wait_time = term_config["cursor_blink_rate"]

	while true:
		var cmd = await input("$ ")

		await parse_command(cmd)

func _input(event: InputEvent) -> void:
	if not can_input: return
	if not is_teminal_open: return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ENTER:
				enter_pressed.emit()

				Audio.playrandom3d([
					preload("res://assets/audio/sfx/machine/keypress/enter/key-enter-01.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/enter/key-enter-02.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/enter/key-enter-03.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/enter/key-enter-04.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/enter/key-enter-05.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/enter/key-enter-06.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/enter/key-enter-07.ogg"),
				], global_position)

			KEY_LEFT:
				cursor_pos = max(cursor_pos - 1, 0)
				_render_input()

			KEY_RIGHT:
				cursor_pos = min(cursor_pos + 1, current_input.length())
				_render_input()

			KEY_BACKSPACE:
				if cursor_pos > 0:
					current_input = (
						current_input.substr(0, cursor_pos - 1)
						+ current_input.substr(cursor_pos)
					)
					cursor_pos -= 1
					_render_input()

				Audio.playrandom3d([
					preload("res://assets/audio/sfx/machine/keypress/back/key-back-01.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/back/key-back-02.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/back/key-back-03.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/back/key-back-04.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/back/key-back-05.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/back/key-back-06.ogg"),
					preload("res://assets/audio/sfx/machine/keypress/back/key-back-07.ogg"),
				], global_position)

			_:
				if event.unicode > 0:
					var ch := char(event.unicode)
					current_input = (
						current_input.substr(0, cursor_pos)
						+ ch
						+ current_input.substr(cursor_pos)
					)
					cursor_pos += 1
					_render_input()

					Audio.playrandom3d([
						preload("res://assets/audio/sfx/machine/keypress/key/key-01.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-02.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-03.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-04.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-05.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-06.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-07.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-08.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-09.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-10.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-11.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-12.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-13.ogg"),
						preload("res://assets/audio/sfx/machine/keypress/key/key-14.ogg"),
					], global_position)

func _render_input():
	var display := ""

	if hide_current_input:
		display = "*".repeat(current_input.length())
	else:
		display = current_input

	display = (
		display.substr(0, cursor_pos)
		+ CURSOR
		+ display.substr(cursor_pos)
	)

	term_output.text = term_output.text.substr(0, max_backspace) + display
	term_output.scroll_vertical = scroll_amount

func _cursor_blink():
	if can_input:
		if CURSOR == " ":
			CURSOR = "_"
		else:
			CURSOR = " "
		_render_input()

func print_out(output_text: String="", nl: bool=true):
	term_output.text += output_text
	if nl:
		term_output.text += "\n"

	scroll_amount = term_output.get_line_count()

func input(query: String, hide_input: bool = false) -> String:
	print_out(query, false)

	current_input = ""
	cursor_pos = 0
	hide_current_input = hide_input
	max_backspace = term_output.text.length()

	_render_input()

	can_input = true
	await enter_pressed
	can_input = false

	var committed := (
		"*".repeat(current_input.length())
		if hide_current_input
		else current_input
	)

	term_output.text = term_output.text.substr(0, max_backspace) + committed + "\n"

	hide_current_input = false
	return current_input

func _process(_delta: float) -> void:
	term_output.scroll_vertical = scroll_amount

	if is_teminal_open:
		var tx = global_transform

		tx = tx.translated(global_basis.z)

		GLOBAL.player.camera.global_transform = GLOBAL.player.camera.global_transform.interpolate_with(tx, 0.3)
		GLOBAL.player.can_move = false

		if Input.is_action_just_pressed("escape"):
			is_teminal_open = false
			GLOBAL.player.can_move = true

func parse_command(cmd_string: String):
	var args: Array = cmd_string.split(" ")

	var command = args.pop_front()

	match command:
		"clear":
			term_output.text = ""
		"probe":
			var probe_idx = args.pop_front()
			var subcommand = args.pop_front()

			var probe_bays = []

			for node in get_tree().current_scene.get_children():
				if node is ProbeBay:
					probe_bays.append(node)

			if not probe_idx:
				print_out("probe: missing probe index")
				print_out("Usage: probe <probe index> <subcommand>")
				return

			if not subcommand:
				print_out("probe: missing subcommand")
				print_out("Usage: probe <probe index> <subcommand>")
				return

			match subcommand:
				"launch":
					if probe_idx.is_valid_int():
						await print_probe_launch(int(probe_idx), probe_bays)
					elif probe_idx == "all":
						for i in probe_bays.size():
							await print_probe_launch(i + 1, probe_bays)
					else:
						print_out("probe: probe index must be an integer or \"all\" to operate on all probes")

				"status":
					if probe_idx == "all":
						for i in probe_bays.size():
							print_probe_status(i, probe_bays)
					elif probe_idx.is_valid_int():
						print_probe_status(int(probe_idx), probe_bays)
				"poll":
					var interval = args.pop_front()
					if interval: 
						if interval.is_valid_float():
							interval = float(interval)
						else:
							print_out("probe: poll: Interval must be a valid floating point number")
							return
					else:
						interval = 1.0

					var refresh_timer := 0.0
					if interval < 0.0:
						print_out("probe: poll: Interval must not be negative")
						return
					while true:
						var delta = get_process_delta_time()
						refresh_timer += delta
						if Input.is_key_pressed(KEY_Q):
							break
						if refresh_timer > interval:
							refresh_timer = 0.0
							term_output.text = ""
							if probe_idx == "all":
								print_out("Polling all probes status every %.1f second(s)" % interval)
								for i in probe_bays.size():
									print_probe_status(i, probe_bays)
							elif probe_idx.is_valid_int():
								print_out("Polling probe %s status every %.1f second(s)" % [probe_idx, interval])
								print_probe_status(int(probe_idx), probe_bays)
							print_out("\nPress Q to stop")
						await get_tree().process_frame
				"feed":
					if probe_idx.is_valid_int():
						if not probe_bays.get(int(probe_idx)):
							print_out("probe: probe bay %s not found" % probe_idx)
							return
						$"../FeedScreen".probe_idx = int(probe_idx)
					else:
						print_out("probe: probe index must be an integer")
				_:
					print_out("probe: Invalid subcommand '%s'" % subcommand)
		_:
			print_out("No such command")

func print_probe_status(idx: int, bays: Array):
	var bay = bays.get(idx)
	var probe = bay.probe
	print_out("Probe %d status:" % idx)
	if bay.probe.is_docked:
		print_out("	Probe docked")
	else:
		print_out("	Not docked")

	print_out("	Fuel: %.1f%%" % [bay.probe.fuel * 100])
	print_out("	Battery: %.1f%%" % [bay.probe.battery * 100])
	print_out("	Distance: %.1fm" % [probe.global_position.distance_to(bay.global_position)])
	print_out("	Distance to target: %.1fm" % [probe.global_position.distance_to(probe.target)])
	print_out("	Velocity: %.1fm/s" % [probe.linear_velocity.length()])

	match bay.probe_status:
		ProbeBay.PROBE_STATUS.SCANNING:
			print_out("	Task: Scanning target (%.1f%%)" % [probe.scan_progress * 100])
		ProbeBay.PROBE_STATUS.IDLE:
			print_out("	Task: Idle")
		ProbeBay.PROBE_STATUS.APPROACH:
			print_out("	Task: Approach target")
		ProbeBay.PROBE_STATUS.RETURN:
			print_out("	Task: RTB")

func print_probe_launch(idx: int, bays: Array):
	var probe_bay = bays.get(idx)

	if probe_bay:
		var probe = probe_bay.probe
		if probe.is_docked:
			print_out("Loading probe %s..." % idx, false)

			probe_bay.reload()

			var is_probe_loaded = await probe_bay.reloaded

			if is_probe_loaded:
				print_out("OK")
			else:
				print_out("FAIL (no probe)")
				return

			await get_tree().create_timer(3.0).timeout
			print_out("Launching probe %s..." % idx, false)
			probe_bay.launch()
			await probe.launched
			print_out("OK")
			await get_tree().create_timer(1.0).timeout
			print_out("Locking target...", false)
			await probe.target_locked
			print_out("OK")
		else:
			print_out("probe: probe %s not docked" % idx)
	else:
		print_out("probe: probe bay %s not found" % idx)
