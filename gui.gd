extends Control

@export var player: Player

var selected_unit: Unit
var selected_units: Array[Node]
var selected_units_count
var unit_scene: PackedScene = preload("res://unit.tscn")

func _process(_delta: float) -> void:
	selected_unit = null
	selected_units = get_tree().get_nodes_in_group("selected_units")
	selected_units_count = len(selected_units)
	
	if player:
		%Player_energy.text = "Energy pool: " + str(get_parent().get_parent().player.player_energy)
	
	if selected_units_count == 1:
		selected_unit = selected_units[0]
		%Transform_button.disabled = false
		%Conduit.disabled = false
	else:
		%Conduit.disabled = true
		%Transform_button.disabled = true
		%Pop.disabled = true
	if selected_unit:
		if selected_unit.health_prop > 0.99:
			%Pop.disabled = false
		else: %Pop.disabled = true
		%Energy.text = "%.3f" % selected_unit.energy
		%Energy_prog.value = selected_unit.energy / selected_unit.target_energy
		%Health.value = selected_unit.health_current / selected_unit.health_max
		%Power.text = "%.3f" % selected_unit.power
		%Speed.text = "%.3f" % UnitAttributes.get_speed_value(selected_unit)
		%TriCon.set_point(selected_unit.health_prop, selected_unit.power_prop, selected_unit.speed_prop)

		
	else:
		%Energy.text = "---"
		%Health.value = %TriCon.current_h
		%Power.text = "%.3f" % %TriCon.current_p
		%Speed.text = "%.3f" % %TriCon.current_s
	

func _on_transform_button_pressed() -> void:
	print("Tricon: ", %TriCon.current_h, " ", %TriCon.current_p, " ", %TriCon.current_s)
	print("Mode: ", selected_unit.mode)
	print("Conduit Mode: ", selected_unit.conduit_mode)
	for unit: Unit in selected_units:
		unit.old_health_prop = unit.health_prop
		unit.old_power_prop = unit.power_prop
		unit.old_speed_prop = unit.speed_prop
		unit.target_health_prop = %TriCon.current_h
		if unit.target_health_prop < unit.health_prop:
			unit.old_health_current = unit.health_current
			var new_max = unit.target_health_prop * unit.energy
			var ratio = unit.health_current / unit.health_max
			unit.target_health_current = ratio * new_max
		unit.target_power_prop = %TriCon.current_p
		unit.target_speed_prop = %TriCon.current_s
		unit.transform_amount = 0.0
		unit.transform_current = 0.0
		unit.transform_amount += abs(unit.target_health_prop - unit.health_prop)
		unit.transform_amount += abs(unit.target_power_prop - unit.power_prop)
		unit.transform_amount += abs(unit.target_speed_prop - unit.speed_prop)

func _on_conduit_pressed() -> void:
	for unit in selected_units:
		unit.target_health_prop = 1
		unit.target_power_prop = 0
		unit.target_speed_prop = 0
	%TriCon.set_handle(selected_unit.target_health_prop, selected_unit.target_power_prop, selected_unit.target_speed_prop)

func _on_pop_pressed() -> void:
	selected_unit.start_build(float(%Pop_energy.text), %TriCon.current_h, %TriCon.current_p, %TriCon.current_s)
	
	


func _on_build_energy_value_changed(value: float) -> void:
	%"Energy cost".text = str(value)
	pass # Replace with function body.
