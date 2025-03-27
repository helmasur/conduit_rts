extends Control

var join_ip: String

func _on_ip_text_submitted(new_text: String) -> void:
	$"Join Button".disabled = false
	join_ip = new_text

# Exempel: Starta som host
func _on_host_button_pressed():
	MultiplayerManager.host()
	get_tree().change_scene_to_file("res://main.tscn")


# Eller klient
func _on_join_button_pressed():
	MultiplayerManager.join(join_ip)
	get_tree().change_scene_to_file("res://main.tscn")
