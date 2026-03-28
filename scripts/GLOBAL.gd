extends Node

var player: CharacterBody3D

func player_init():
	player = preload("res://scenes/player.tscn").instantiate()

	get_tree().current_scene.add_child(player)
