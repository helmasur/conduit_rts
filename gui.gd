extends VBoxContainer

func _process(_delta: float) -> void:
	$Energy.text = str(GlobalGameState.player_energy)
