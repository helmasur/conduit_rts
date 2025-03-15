extends VBoxContainer

func _process(delta: float) -> void:
	$Energy.text = str(GlobalGameState.player_energy)
