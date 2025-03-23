extends VBoxContainer

var selected_unit: Unit
var selected_units
var selected_units_count
var unit_scene: PackedScene = preload("res://unit.tscn")

func _process(_delta: float) -> void:
	selected_unit = null
	selected_units = get_tree().get_nodes_in_group("selected_units")
	selected_units_count = len(selected_units)
	
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
		%Health.value = selected_unit.health_current / selected_unit.health
		%Power.text = "%.3f" % selected_unit.power
		%Speed.text = "%.3f" % selected_unit.speed
		%TriCon.set_point(selected_unit.health_prop, selected_unit.power_prop, selected_unit.speed_prop)

		
	else:
		%Energy.text = "---"
		%Health.value = %TriCon.current_h
		%Power.text = "%.3f" % %TriCon.current_p
		%Speed.text = "%.3f" % %TriCon.current_s
	

func _on_transform_button_pressed() -> void:
	print("Tricon: ", %TriCon.current_h, " ", %TriCon.current_p, " ", %TriCon.current_s)
	for unit in selected_units:
		unit.target_health_prop = %TriCon.current_h
		#print(unit.health_prop, " ", unit.target_health_prop)
		unit.target_power_prop = %TriCon.current_p
		unit.target_speed_prop = %TriCon.current_s

func _on_conduit_pressed() -> void:
	for unit in selected_units:
		unit.target_health_prop = 1
		unit.target_power_prop = 0
		unit.target_speed_prop = 0
	%TriCon.set_handle(selected_unit.target_health_prop, selected_unit.target_power_prop, selected_unit.target_speed_prop)

func _on_pop_pressed() -> void:
	selected_unit.start_build(float(%Pop_energy.text), %TriCon.current_h, %TriCon.current_p, %TriCon.current_s)
	
	
