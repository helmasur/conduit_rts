extends VBoxContainer

func _ready() -> void:
	$HSlider.value = get_parent().target_health_prop
	$PSlider.value = get_parent().target_attack_prop
	$SSlider.value = get_parent().target_speed_prop

func _process(_delta: float) -> void:
	$E.text = str(get_parent().total_energy)
	$H.text = str(get_parent().health_current)
	$P.text = str(get_parent().get_attack_value())
	$S.text = str(get_parent().get_speed_value())
	$FSF.text = "%.3f" % get_parent().fsf

	


func _on_h_slider_value_changed(value: float) -> void:
	$PSlider.value = get_parent().target_attack_prop
	$SSlider.value = get_parent().target_speed_prop


func _on_p_slider_value_changed(value: float) -> void:
	$HSlider.value = get_parent().target_health_prop
	$SSlider.value = get_parent().target_speed_prop


func _on_s_slider_value_changed(value: float) -> void:
	$HSlider.value = get_parent().target_health_prop
	$PSlider.value = get_parent().target_attack_prop
