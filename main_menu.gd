# main_menu.gd
extends Control

func _ready() -> void:
	visible = true

# Exempel: Starta som host
func _on_host_button_pressed():
	MultiplayerManager.host()
	$"/root/Game"._on_server_start()
	visible = false
	
	#get_tree().change_scene_to_file("res://game.tscn")


# Eller klient
func _on_join_button_pressed():
	MultiplayerManager.join($"IP".text)
	visible = false
	#get_tree().change_scene_to_file("res://game.tscn")


func _on_start_button_pressed() -> void:
	$"/root/Game"._on_game_started()
