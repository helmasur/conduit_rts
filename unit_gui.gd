extends VBoxContainer

#func _ready() -> void:
	#$HSlider.value = get_parent().target_health_prop
	#$PSlider.value = get_parent().target_power_prop
	#$SSlider.value = get_parent().target_speed_prop

#func _process(_delta: float) -> void:
	#$E.text = str(get_parent().total_energy)
	#$H.text = str(get_parent().health_current)
	#$P.text = str(UnitAttributes.get_power_value(get_parent()))
	#$S.text = str(UnitAttributes.get_speed_value(get_parent()))
	#$FSF.text = "%.3f" % get_parent().fsf
