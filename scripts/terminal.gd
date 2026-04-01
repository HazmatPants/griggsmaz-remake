extends Interactable

@onready var term_output: RichTextLabel = $SubViewport/ColorRect/TextEdit
@onready var console: StaticBody3D = $"../LogScreen"

var is_terminal_open := false

signal enter_pressed

func interact():
	is_terminal_open = true

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
	if not is_terminal_open: return

	if event is InputEventKey:
		if event.pressed:
			if event.is_command_or_control_pressed():
				match event.keycode:
					KEY_L:
						parse_command("clear")
						simulate_key(KEY_ENTER)
					KEY_C:
						if can_input:
							current_input = ""
							simulate_key(KEY_ENTER)
				return
			match event.keycode:
				KEY_ENTER:
					enter_pressed.emit()

					if not event.is_echo():
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
					if not event.is_echo():
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

						if not event.is_echo():
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
	if is_terminal_open:
		var tx = global_transform

		tx = tx.translated(global_basis.z)

		GLOBAL.player.camera.global_transform = GLOBAL.player.camera.global_transform.interpolate_with(tx, 0.3)
		GLOBAL.player.can_move = false

		if Input.is_action_just_pressed("escape"):
			is_terminal_open = false
			GLOBAL.player.can_move = true

func parse_command(cmd_string: String):
	var args: Array = cmd_string.split(" ")

	var command = args.pop_front()

	match command:
		"help":
			var cmd = args.pop_front()
			match cmd:
				null:
					var help_string = "Command list:\n"
					help_string += "- help - this\n"
					help_string += "- probe - control probes\n"
					help_string += "- celobj - scan celestial objects\n"
					help_string += "- cam - set camera feed\n"
					help_string += "- clear - clear the screen (Ctrl+L also works)\n"
					print_out(help_string)
				"probe":
					var help_string = "Probe:\n"
					help_string += "- launch - launch the probe, and navigate it towards its target if it has one\n"
					help_string += "- return - command the probe to return to its docking bay\n"
					help_string += "- status - get probe(s) status\n"
					help_string += "- poll <n>- get probe(s) status every <n> seconds\n"
					help_string += "- target <id> - set probe(s) target to <id>\n"
					help_string += "- control - switch the probe to manual control mode\n"
					help_string += "- scan - command the probe to scan its target, if in range\n"
					print_out(help_string)
				"celobj":
					var help_string = "Celestial Object Manager:\n"
					help_string += "- scan - scan for undiscovered objects\n"
					help_string += "- list - list objects in the database (any objects previously scanned)\n"
					help_string += "- calibrate - calibrate the object scanner, reduces instability, increasing scan speed\n"
					help_string += "- status - returns the number of bodies in the database and the current scanner instability\n"
					print_out(help_string)
				_:
					print_out("help: there is no help page for '%s'" % cmd)
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
						console.log_text("Probe %s launched" % probe_idx)
					elif probe_idx == "all":
						for i in probe_bays.size():
							await print_probe_launch(i, probe_bays)
					else:
						print_out("probe: probe index must be an integer or \"all\" to operate on all probes")
				"return":
					if probe_idx.is_valid_int():
						var bay = probe_bays.get(int(probe_idx))
						var probe = bay.probe

						if probe.is_docked:
							print_out("probe: return: Probe %s is docked" % probe_idx)
						else:
							print_out("Probe %s is now returning to base" % probe_idx)
							console.log_text("Command probe %s to return to base" % probe_idx)
							probe.rtb()

					elif probe_idx == "all":
						for i in probe_bays.size():
							var bay = probe_bays.get(i)
							var probe = bay.probe

							if probe.is_docked:
								print_out("probe: return: Probe %s is docked" % probe_idx)
							else:
								print_out("Probe %s is now returning to base" % probe_idx)
								console.log_text("Command probe %s to return to base" % probe_idx)
								probe.rtb()
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
					console.log_text("Started polling probe %s" % probe_idx)
					while true:
						var delta = get_process_delta_time()
						refresh_timer += delta
						if is_key_pressed(KEY_Q):
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
				"target":
					var body_id = args.pop_front()
					if not body_id:
						print_out("probe: target: missing target")
						return
					if CelestialObjectManager.scanned_bodies.keys().has(body_id) or body_id == "clear":
						if probe_idx.is_valid_int():
							var bay = probe_bays.get(int(probe_idx))
							var probe = bay.probe

							if probe:
								if body_id == "clear":
									probe.target = {}
									print_out("Cleared Probe %s target" % [probe_idx])
									console.log_text("Cleared Probe %s target" % [probe_idx])
								else:
									probe.target = CelestialObjectManager.scanned_bodies[body_id]
									print_out("Set Probe %s target to %s" % [probe_idx, body_id])
									console.log_text("Set Probe %s target to %s" % [probe_idx, body_id])
						elif probe_idx == "all":
							for i in probe_bays.size():
								var bay = probe_bays.get(i)
								var probe = bay.probe

								if probe:
									if body_id == "clear":
										probe.target = {}
										console.log_text("Cleared Probe %s target" % [i])
									else:
										probe.target = CelestialObjectManager.scanned_bodies[body_id]
										console.log_text("Set Probe %s target to %s" % [i, body_id])
							if body_id == "clear":
								print_out("Cleared all probes targets")
							else:
								print_out("Set all probes target to %s" % [body_id])
					else:
						print_out("probe: target: Body %s not found" % body_id)
				"control":
					if probe_idx.is_valid_int():
						var bay = probe_bays.get(int(probe_idx))
						var probe = bay.probe
						if probe.is_docked:
							print_out("probe: control: Probe is docked")
							return
						bay.probe_status = ProbeBay.PROBE_STATUS.MANUAL_CTRL
						probe.targeting_enabled = false
						while true:
							if is_key_pressed(KEY_Q):
								break
							if probe.is_docked:
								print_out("Probe docked, stopping control")
								break
							term_output.text = ""
							print_out("--- CONTROLLING PROBE %s ---" % probe_idx)
							print_out("W - pitch down")
							print_out("A - yaw left")
							print_out("S - pitch up")
							print_out("D - yaw right")
							print_out("C - roll left")
							print_out("V - roll right")
							print_out("SPACE - thrust")
							print_out("Inertia dampening ON")
							print_out("Press Q to stop controlling")
							await get_tree().process_frame
						bay.probe_status = ProbeBay.PROBE_STATUS.IDLE
					else:
						print_out("probe: control: Probe index must be a valid integer (cannot control multiple probes)")
				"scan":
					if probe_idx.is_valid_int():
						print_probe_scan(int(probe_idx), probe_bays)
					elif probe_idx == "all":
						for i in probe_bays.size():
							print_probe_scan(i, probe_bays)
					else:
						print_out("probe: probe index must be an integer or \"all\" to operate on all probes")
				_:
					print_out("probe: Invalid subcommand '%s'" % subcommand)
		"celobj":
			var subcommand = args.pop_back()

			if not subcommand:
				print_out("celobj: missing subcommand")
				print_out("Usage: celobj <subcommand>")
				return

			match subcommand:
				"scan":
					print_out("Scanning for nearby celestial objects...")
					if CelestialObjectManager.scanner_instability > 1.25:
						print_out("Warning! Scanner instability at %.1f%%. Please calibrate scanner with `celobj calibrate`" % [(CelestialObjectManager.scanner_instability - 1.0) * 100])
					await get_tree().create_timer(randf_range(3.0, 5.0) * CelestialObjectManager.scanner_instability).timeout
					if CelestialObjectManager.bodies.keys() == CelestialObjectManager.scanned_bodies.keys():
						print_out("No new objects detected")
						return
					for body in CelestialObjectManager.bodies.keys():
						if body in CelestialObjectManager.scanned_bodies:
							continue

						while true:
							if randf() > 0.8:
								break
							await get_tree().create_timer(1.0 * CelestialObjectManager.scanner_instability).timeout
							await get_tree().process_frame

						var body_data = CelestialObjectManager.bodies[body]
						var body_distance = Vector3.ZERO.distance_to(body_data["position"])
						var body_type = CelestialObjectManager.BODY_TYPE.find_key(body_data["type"])

						CelestialObjectManager.scanned_bodies[body] = body_data
						print_out("Detected object:")
						print_out("	Type: '%s'" % body_type)
						print_out("	Distance: ~%.1fm" % body_distance)
						print_out("	ID: %s" % body)
						await get_tree().create_timer(1.0 * CelestialObjectManager.scanner_instability).timeout
					console.log_text("Scanned %d objects" % len(CelestialObjectManager.scanned_bodies))
				"list":
					for body in CelestialObjectManager.scanned_bodies.keys():
						var body_data = CelestialObjectManager.scanned_bodies[body]
						var body_distance = Vector3.ZERO.distance_to(body_data["position"])
						var body_progress = body_data["scan_progress"]
						var body_type = CelestialObjectManager.BODY_TYPE.find_key(body_data["type"])
						print_out("%s:" % body)
						print_out("	Type: %s" % body_type)
						print_out("	Distance: ~%.1fm" % body_distance)
						print_out("	Scan progress: %.1f%%" % body_progress)
				"calibrate":
					while CelestialObjectManager.scanner_instability > 1.009:
						CelestialObjectManager.scanner_instability -= randf() / 20
						CelestialObjectManager.scanner_instability = clampf(CelestialObjectManager.scanner_instability, 1.0, 2.0)
						print_out("Scanner instability: %.1f%%" % [(CelestialObjectManager.scanner_instability - 1.0) * 100])
						await get_tree().create_timer(randf()).timeout
						await get_tree().process_frame
					console.log_text("Object scanner calibrated")
				"status":
					print_out("Scanner instability: %.1f%%" % [(CelestialObjectManager.scanner_instability - 1.0) * 100])
					print_out("%d detected bodies" % len(CelestialObjectManager.scanned_bodies))
				_:
					print_out("probe: Invalid subcommand '%s'" % subcommand)
		"cam":
			var subcommand = args.pop_front()

			match subcommand:
				"probe":
					var probe_idx = args.pop_front()

					if not probe_idx:
						print_out("camera: probe: missing probe index")
						print_out("Usage: camera probe <probe index>")
						return

					var probe_bays = []

					for node in get_tree().current_scene.get_children():
						if node is ProbeBay:
							probe_bays.append(node)

					if probe_idx.is_valid_int():
						var bay = probe_bays.get(int(probe_idx))
						if not bay:
							print_out("probe: probe bay %s not found" % probe_idx)
							return
						$"../FeedScreen".viewport = bay.probe.view
						$"../FeedScreen".camera = bay.probe.camera
						$"../FeedScreen".feed_text = "Probe %s" % probe_idx
						print_out("Set camera feed to probe %s" % probe_idx)
						console.log_text("Set camera feed to probe %s" % probe_idx)
					else:
						print_out("probe: probe index must be an integer")
				"clear":
					$"../FeedScreen".viewport = null
					$"../FeedScreen".camera = null
					$"../FeedScreen".feed_text = ""
					print_out("Cleared camera feed")
					console.log_text("Cleared camera feed")
				_:
					print_out("probe: Invalid subcommand '%s'" % subcommand)
		"":
			pass
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
	if probe.target:
		print_out("	Distance to target: %.1fm" % [probe.global_position.distance_to(probe.target["position"])])
	print_out("	Velocity: %.1fm/s" % [probe.linear_velocity.length()])

	match bay.probe_status:
		ProbeBay.PROBE_STATUS.SCANNING:
			print_out("	Task: Scanning target (%.1f%%)" % [probe.target["scan_progress"] * 100])
		ProbeBay.PROBE_STATUS.IDLE:
			print_out("	Task: Idle")
		ProbeBay.PROBE_STATUS.APPROACH:
			print_out("	Task: Approach target")
		ProbeBay.PROBE_STATUS.RETURN:
			print_out("	Task: RTB")
		ProbeBay.PROBE_STATUS.MANUAL_CTRL:
			print_out("	Task: MADDOG")

func print_probe_launch(idx: int, bays: Array):
	var probe_bay = bays.get(idx)

	var mad_dog := false

	if probe_bay:
		var probe = probe_bay.probe
		if not probe.target:
			print_out("Probe %s has no target" % idx)
			var choice = await input("Are you sure you want launch? (y/N): ")
			if choice.to_lower() == "y":
				mad_dog = true
			else: return
		if probe.is_docked:
			print_out("Loading probe %s..." % idx, false)

			probe_bay.reload()

			var is_probe_loaded = await probe_bay.reloaded

			if is_probe_loaded:
				print_out("OK")
			else:
				print_out("FAIL (no probe)")
				return

			await get_tree().create_timer(1.0).timeout
			print_out("Launching probe %s..." % idx, false)
			probe_bay.launch()
			await probe.launched
			print_out("OK")

			if mad_dog: return

			await get_tree().create_timer(1.0).timeout
			print_out("Locking target...", false)
			await probe.target_locked
			print_out("OK")
		else:
			print_out("probe: probe %s not docked" % idx)
	else:
		print_out("probe: probe bay %s not found" % idx)

func print_probe_scan(idx: int, bays: Array):
	var probe_bay = bays.get(idx)
	var probe = probe_bay.probe

	var status = await probe.scan()

	match status:
		"":
			print_out("Probe %d is now scanning %d" % [idx, probe.target["id"]])
		"no_target":
			print_out("Probe %d has no target" % idx)
		"out_of_range":
			print_out("Probe %d is out of range of %s" % [idx, probe.target["id"]])

func is_key_pressed(key: Key):
	return Input.is_key_pressed(key) and is_terminal_open

func simulate_key(key: Key):
	var ev = InputEventKey.new()
	ev.keycode = key
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	ev = ev.duplicate()
	ev.pressed = false
	Input.parse_input_event(ev)
