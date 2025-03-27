extends Label

func _process(_delta: float) -> void:
	if %GUI.player:
		text = "Energy pool: " + str(%GUI.player.player_energy)
