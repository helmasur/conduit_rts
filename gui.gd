extends Control

var selected_unit: Unit
var selected_units: Array[Node]
var selected_units_count
var unit_scene: PackedScene = preload("res://unit.tscn")

func _process(_delta: float) -> void:
	selected_unit = null
	selected_units = get_tree().get_nodes_in_group("selected_units")
	selected_units_count = len(selected_units)
	
	if $"/root/Game".player:
		%Player_energy.text = "Energy pool %.0f" % $"/root/Game".player.player_energy

	
	if selected_units_count > 0:
		selected_unit = selected_units[0]
		%Transform_button.disabled = false
		%Conduit.disabled = false
	else:
		%Conduit.disabled = true
		%Transform_button.disabled = true
	if selected_unit:
		%UnitStats.visible = true
		%BuildControls.visible = false
		%TriCon.set_light_mode(true)
		%Energy.text = "Energy: " + _fmt(selected_unit.energy).lstrip(" ") + "/" + _fmt(selected_unit.energy_max).lstrip(" ")
		#%Energy_prog.value = selected_unit.energy / selected_unit.energy_max
		%Power.text = "P: " + _fmt(selected_unit.power)
		%Speed.text = "S: " + _fmt(selected_unit.speed)
		%Health.text = "D: " + _fmt(selected_unit.defense)
		%TriCon.set_point(selected_unit.defense_prop, selected_unit.power_prop, selected_unit.speed_prop)
	else:
		%UnitStats.visible = false
		%BuildControls.visible = true
		%TriCon.set_light_mode(false)
		%BuildEnergy.text = "Cost: " + _fmt(%EnergySlider.value)
		%BuildArmour.text = "A: " + _fmt(%TriCon.current_h * %EnergySlider.value)
		%BuildPower.text = "P: " + _fmt(%TriCon.current_p * %EnergySlider.value)
		%BuildSpeed.text = "S: " + _fmt(%TriCon.current_s * %EnergySlider.value)

func _fmt(f: float) -> String:
	if f < 10:
		return ("%6.1f" % f)
	else:
		return ("%6.0f" % f)

func _on_transform_button_pressed() -> void:
	$"/root/Game".transform_selected(%TriCon.current_h, %TriCon.current_p, %TriCon.current_s)
		
func _on_conduit_pressed() -> void:
	for unit in selected_units:
		unit.target_defense_prop = 1
		unit.target_power_prop = 0
		unit.target_speed_prop = 0
	%TriCon.set_handle(selected_unit.target_defense_prop, selected_unit.target_power_prop, selected_unit.target_speed_prop)

func _on_build_energy_value_changed(value: float) -> void:
	%BuildEnergy.text = "Cost: %.0f" % value
	pass # Replace with function body.
