extends CanvasLayer

func _process(delta: float) -> void:
	$FPSLabel.text = "%d" % [Engine.time_scale / delta]

	if Input.is_action_just_pressed("dev_menu"):
		$DevMenu.visible = !$DevMenu.visible
		if $DevMenu.visible:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	$Blackout.modulate.a = 1.0 - owner.consciousness

	var noise = $Noise.material.get_shader_parameter("noise_intensity")

	if owner.is_unconscious():
		$Noise.material.set_shader_parameter("noise_intensity", lerpf(noise, 0.2, 0.1))
	else:
		$Noise.material.set_shader_parameter("noise_intensity", lerpf(noise, clampf(1.0 - (owner.oxygen / 0.17), 0.0, 0.1), 0.1))

func _on_noclip_button_pressed() -> void:
	owner.noclip = !owner.noclip

	if owner.noclip:
		$DevMenu/Panel/VBoxContainer/NoclipButton.text = "Noclip: ON"
	else:
		$DevMenu/Panel/VBoxContainer/NoclipButton.text = "Noclip: OFF"
