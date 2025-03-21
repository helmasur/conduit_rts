extends Label

func _process(_delta: float) -> void:
	text = "Energy pool: " + str(GlobalGameState.player_energy)
