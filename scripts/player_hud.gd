extends CanvasLayer

func _process(delta: float) -> void:
	$FPSLabel.text = "%d" % [Engine.time_scale / delta]
