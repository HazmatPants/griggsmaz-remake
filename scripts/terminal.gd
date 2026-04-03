extends Interactable

@onready var term_output: RichTextLabel = $SubViewport/ColorRect/TextEdit
@onready var console: StaticBody3D = $"../LogScreen"

var is_terminal_open := false

signal enter_pressed

func interact():
	is_terminal_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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
						var tmp = current_input
						current_input = "clear"
						await simulate_key(KEY_ENTER)
						current_input = tmp
						cursor_pos = len(current_input)
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

func print_err(output_text: String="", nl: bool=true):
	term_output.text += "[color=red]ERROR: %s[/color]" % output_text
	if nl:
		term_output.text += "\n"

func print_warn(output_text: String="", nl: bool=true):
	term_output.text += "[color=yellow]WARN: %s[/color]" % output_text
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
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

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
					help_string += "- station - view station status or control subsystems\n"

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
					help_string += "- relock - command the probe to lock its target and approach it\n"
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
				print_err("Missing probe index")
				print_err("Usage: probe <probe index> <subcommand>")
				return

			if not subcommand:
				print_err("Missing subcommand")
				print_err("Usage: probe <probe index> <subcommand>")
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
						print_err("Probe index must be an integer or \"all\" to operate on all probes")
				"return":
					for i in range(probe_bays.size()):
						if probe_idx.is_valid_int():
							if i != int(probe_idx): continue
						elif not probe_idx == "all":
							print_err("Probe index must be an integer or \"all\" to operate on all probes")
							return
						var bay = probe_bays.get(i)
						var probe = bay.probe

						if probe.is_docked:
							print_err("Probe %s is docked" % i)
						else:
							print_out("Probe %s is now returning to base" % i)
							console.log_text("Command probe %s to return to base" % i)
							probe.rtb()
				"relock":
					for i in range(probe_bays.size()):
						if probe_idx.is_valid_int():
							if i != int(probe_idx): continue
						elif not probe_idx == "all":
							print_err("Probe index must be an integer or \"all\" to operate on all probes")
							return

						var bay = probe_bays.get(i)
						var probe = bay.probe

						if probe.is_docked:
							print_err("Probe %s is docked" % i)
						else:
							print_out("Relocking Probe %s target..." % i)
							console.log_text("Command probe %s to relock" % i)
							probe.lock()
				"status":
					for i in range(probe_bays.size()):
						if probe_idx.is_valid_int():
							if i != int(probe_idx): continue
						elif not probe_idx == "all":
							print_err("Probe index must be an integer or \"all\" to operate on all probes")
							return
						print_probe_status(i, probe_bays)
				"poll":
					var interval = args.pop_front()
					if interval:
						if interval.is_valid_float():
							interval = float(interval)
						else:
							print_err("Interval must be a valid floating point number")
							return
					else:
						interval = 1.0

					var refresh_timer := 0.0
					if interval < 0.0:
						print_err("Interval must not be negative")
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
						print_out("Missing target")
						return
					if CelestialObjectManager.scanned_bodies.keys().has(body_id) or body_id == "clear":
						for i in range(probe_bays.size()):
							if probe_idx.is_valid_int():
								if i != int(probe_idx): continue
							elif not probe_idx == "all":
								print_err("probe index must be an integer or \"all\" to operate on all probes")
								return
							var bay = probe_bays.get(i)
							var probe = bay.probe

							if probe:
								if body_id == "clear":
									probe.target = {}
									print_out("Cleared Probe %s target" % [i])
									console.log_text("Cleared Probe %s target" % [i])
								else:
									probe.target = CelestialObjectManager.scanned_bodies[body_id]
									print_out("Set Probe %s target to %s" % [i, body_id])
									console.log_text("Set Probe %s target to %s" % [i, body_id])
					else:
						print_err("Body %s not found" % body_id)
				"control":
					if probe_idx.is_valid_int():
						var bay = probe_bays.get(int(probe_idx))
						var probe = bay.probe
						if probe.is_docked:
							print_err("Probe is docked")
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
						print_err("Probe index must be a valid integer (cannot control multiple probes)")
				"scan":
					for i in range(probe_bays.size()):
						if probe_idx.is_valid_int():
							if i != int(probe_idx): continue
						elif not probe_idx == "all":
							print_err("Probe index must be an integer or \"all\" to operate on all probes")
							return
						print_probe_scan(i, probe_bays)
				_:
					print_err("Invalid subcommand '%s'" % subcommand)
		"celobj":
			var subcommand = args.pop_back()

			if not subcommand:
				print_err("Missing subcommand")
				print_err("Usage: celobj <subcommand>")
				return

			match subcommand:
				"scan":
					print_out("Scanning for nearby celestial objects...")
					if CelestialObjectManager.scanner_instability > 1.25:
						print_warn("Scanner instability at %.1f%%. Please calibrate scanner with `celobj calibrate`" % [(CelestialObjectManager.scanner_instability - 1.0) * 100])
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
						var body_value = body_data["scan_value"]
						var body_distance = Vector3.ZERO.distance_to(body_data["position"])
						var body_type = CelestialObjectManager.BODY_TYPE.find_key(body_data["type"])

						CelestialObjectManager.scanned_bodies[body] = body_data
						print_out("Detected object:")
						print_out("	Type: '%s'" % body_type)
						print_out("	Value: %d" % roundi(body_value))
						print_out("	Distance: ~%.1fm" % body_distance)
						print_out("	ID: %s" % body)
						await get_tree().create_timer(1.0 * CelestialObjectManager.scanner_instability).timeout
					console.log_text("Scanned %d objects" % len(CelestialObjectManager.scanned_bodies))
				"list":
					for body in CelestialObjectManager.scanned_bodies.keys():
						var body_data = CelestialObjectManager.scanned_bodies[body]
						var body_distance = Vector3.ZERO.distance_to(body_data["position"])
						var body_progress = body_data["scan_progress"] * 100
						var body_value = body_data["scan_value"]
						var body_type = CelestialObjectManager.BODY_TYPE.find_key(body_data["type"])
						print_out("%s:" % body)
						print_out("	Type: %s" % body_type)
						print_out("	Value: %d" % roundi(body_value))
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
				"upload":
					if CelestialObjectManager.scanned_bodies.is_empty():
						print_err("No data to upload")
						return
					print_out("Communicating with satellite uplink...")
					await get_tree().create_timer(randf_range(5.0, 10.0)).timeout
					print_out("Uploading scanned data...")
					var value = 0.0
					var bodies = CelestialObjectManager.scanned_bodies
					for body in CelestialObjectManager.scanned_bodies.keys():
						if bodies[body]["scan_progress"] < 0.1:
							print_warn("Body '%s' not enough data (<10%%)" % bodies[body]["id"])
							continue
						if bodies[body]["uploaded"]:
							print_err("Body '%s' already uploaded" % bodies[body]["id"])
							continue
						value += bodies[body]["scan_value"] * bodies[body]["scan_progress"]
						bodies[body]["uploaded"] = true
						print_out("%s: %.1f%% of %d = %d" % [bodies[body]["id"], bodies[body]["scan_progress"] * 100, roundi(bodies[body]["scan_value"]), roundi(bodies[body]["scan_value"] * bodies[body]["scan_progress"])])
						await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
					print_out("%d¢ credited to balance" % roundi(value))
				_:
					print_err("Invalid subcommand '%s'" % subcommand)
		"cam":
			var subcommand = args.pop_front()

			if not subcommand:
				print_err("Missing subcommand")
				print_err("Usage: cam <subcommand>")
				return

			match subcommand:
				"probe":
					var probe_idx = args.pop_front()

					if not probe_idx:
						print_err("Missing probe index")
						print_err("Usage: camera probe <probe index>")
						return

					var probe_bays = []

					for node in get_tree().current_scene.get_children():
						if node is ProbeBay:
							probe_bays.append(node)

					if probe_idx.is_valid_int():
						var bay = probe_bays.get(int(probe_idx))
						if not bay:
							print_err("Probe bay %s not found" % probe_idx)
							return
						$"../FeedScreen".viewport = bay.probe.view
						$"../FeedScreen".camera = bay.probe.camera
						$"../FeedScreen".feed_text = "Probe %s" % probe_idx
						print_out("Set camera feed to probe %s" % probe_idx)
						console.log_text("Set camera feed to probe %s" % probe_idx)
					else:
						print_err("probe: probe index must be an integer")
				"clear":
					$"../FeedScreen".viewport = null
					$"../FeedScreen".camera = null
					$"../FeedScreen".feed_text = ""
					print_out("Cleared camera feed")
					console.log_text("Cleared camera feed")
				_:
					print_err("Invalid subcommand '%s'" % subcommand)
		"station":
			var station = get_tree().current_scene

			var subcommand = args.pop_front()

			if not subcommand:
				print_err("Missing subcommand")
				print_err("Usage: station <subcommand>")
				return

			match subcommand:
				"status":
					print_station_status(station)
				"poll":
					var interval = args.pop_front()
					if interval:
						if interval.is_valid_float():
							interval = float(interval)
						else:
							print_err("Interval must be a valid floating point number")
							return
					else:
						interval = 1.0

					var refresh_timer := 0.0
					if interval < 0.0:
						print_err("Interval must not be negative")
						return
					console.log_text("Started polling station")
					while true:
						var delta = get_process_delta_time()
						refresh_timer += delta
						if is_key_pressed(KEY_Q):
							break
						if refresh_timer > interval:
							refresh_timer = 0.0
							term_output.text = ""
							print_station_status(station)
							print_out("\nPress Q to stop")
						await get_tree().process_frame
				_:
					print_err("Invalid subcommand '%s'" % subcommand)
		"":
			pass
		_:
			print_err("No such command")

func print_probe_status(idx: int, bays: Array):
	var bay = bays.get(idx)
	var probe = bay.probe
	print_out("Probe %d status:" % idx)
	if bay.probe.is_docked:
		print_out("	Probe docked")
	else:
		print_out("	Not docked")

	var vel = probe.linear_velocity.length()
	var dist = 0.0

	print_out("	Fuel: %.1f%%" % [bay.probe.fuel * 100])
	print_out("	Battery: %.1f%%" % [bay.probe.battery * 100])
	print_out("	Distance: %.1fm" % probe.global_position.distance_to(bay.global_position))
	if probe.target:
		dist = probe.global_position.distance_to(probe.target["position"])
		print_out("	Distance to target: %.1fm" % dist)
	print_out("	Velocity: %.1fm/s" % vel)

	match bay.probe_status:
		ProbeBay.PROBE_STATUS.SCANNING:
			print_out("	Task: Scanning target (%.1f%%)" % [probe.target["scan_progress"] * 100])
		ProbeBay.PROBE_STATUS.IDLE:
			print_out("	Task: Idle")
		ProbeBay.PROBE_STATUS.APPROACH:
			print_out("	Task: Approach target (T-%.1fs)" % [dist / vel])
		ProbeBay.PROBE_STATUS.RETURN:
			print_out("	Task: RTB (T-%.1fs)" % [dist / vel])
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
				print_out("[color=green]OK[/color]")
			else:
				print_out("FAIL (no probe)")
				return

			await get_tree().create_timer(1.0).timeout
			print_out("Launching probe %s..." % idx, false)
			probe_bay.launch()
			await probe.launched
			print_out("[color=green]OK[/color]")

			if mad_dog: return

			await get_tree().create_timer(1.0).timeout
			print_out("Locking target...", false)
			await probe.target_locked
			print_out("[color=green]OK[/color]")
		else:
			print_err("probe: probe %s not docked" % idx)
	else:
		print_err("probe: probe bay %s not found" % idx)

func print_probe_scan(idx: int, bays: Array):
	var probe_bay = bays.get(idx)
	var probe = probe_bay.probe

	var status = await probe.scan()

	match status:
		"":
			print_out("Probe %d is now scanning %s" % [idx, probe.target["id"]])
		"no_target":
			print_out("Probe %d has no target" % idx)
		"out_of_range":
			print_out("Probe %d is out of range of %s" % [idx, probe.target["id"]])

func print_station_status(station):
	print_out("Station Status:")
	print_out("	Station ID: %s" % station.id)
	print_out("	Dyson Swarm Generator:")
	print_out("		Instability: %.1f" % abs(station.generator.instability))
	print_out("		Internal Heat: %.1f°C" % station.generator.heat)
	print_out("		Power Output: %.1f MW" % station.generator.output)
	print_out("		Members: %d" % station.generator.members)
	print_out("	Life Support:")
	print_out("		O2: %.1f%%" % [station.oxygen * 100])
	print_out("		Air Pressure: %.1f kPa" % station.air_pressure)
	if station.o2_generator.bond_plate:
		print_out("		Plate Condition: %.1f%%" % [station.o2_generator.bond_plate.condition * 100])

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
