extends Node

var player: CharacterBody3D

func player_init():
	player = preload("res://scenes/player.tscn").instantiate()

	get_tree().current_scene.add_child(player)

func player_log(text: String):
	var log_term = get_tree().current_scene.get_node_or_null("LogScreen")

	if log_term:
		log_term.log_text(text)
