extends Control

var join_ip: String

func _on_ip_text_submitted(new_text: String) -> void:
	$"Join Button".disabled = false
	join_ip = new_text

# Exempel: Starta som host
func _on_host_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn")
	MultiplayerManager.host()


# Eller klient
func _on_join_button_pressed():
	get_tree().change_scene_to_file("res://game.tscn")
	MultiplayerManager.join(join_ip)
