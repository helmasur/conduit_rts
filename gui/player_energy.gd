extends Label

func _process(_delta: float) -> void:
	text = "Energy pool: " + str(%Player.player_energy)
