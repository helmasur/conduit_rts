# res://scripts/units/UnitBuild.gd
class_name UnitBuild

static func start_build(unit) -> void:
	# Exempel: kräv att enhetens speed_prop och power_prop är 0 för att få bygga
	if unit.mode == UnitShared.ActionMode.FREE and unit.speed_prop == 0 and unit.power_prop == 0:
		unit.mode = UnitShared.ActionMode.BUILD_STARTING
		unit.mode_timer = unit.build_start_time

static func stop_build(unit) -> void:
	if unit.mode == UnitShared.ActionMode.BUILDING:
		unit.mode = UnitShared.ActionMode.BUILD_STOPPING
		unit.mode_timer = unit.build_stop_time
		# Avbryter bygget

static func handle_build_state(unit, delta: float) -> void:
	match unit.mode:
		UnitShared.ActionMode.BUILD_STARTING:
			unit.mode_timer -= delta
			if unit.mode_timer <= 0:
				if unit.build_scene:
					unit.building_unit = unit.build_scene.instantiate() as CharacterBody2D
					unit.building_unit.global_position = unit.global_position + Vector2(50, 0)
					unit.get_tree().current_scene.add_child(unit.building_unit)

					unit.building_unit.energy = 1.0
					unit.building_unit.health_prop = 1.0
					unit.building_unit.speed_prop = 0.0
					unit.building_unit.power_prop = 0.0
					UnitAttributes.normalize_proportions(unit.building_unit)
					unit.building_unit.health_current = 1
				unit.mode = UnitShared.ActionMode.BUILDING
				unit.mode_timer = 0

		UnitShared.ActionMode.BUILDING:
			if unit.building_unit:
				var transfer_amount = unit.build_transfer_rate * delta
				if GlobalGameState.player_energy < transfer_amount:
					transfer_amount = GlobalGameState.player_energy

				var needed = unit.build_target_energy - unit.building_unit.energy
				if needed < transfer_amount:
					transfer_amount = needed

				if transfer_amount > 0:
					unit.building_unit.energy += transfer_amount
					GlobalGameState.player_energy -= transfer_amount

				if unit.building_unit.energy >= unit.build_target_energy:
					unit.building_unit.health_prop = unit.final_health_prop
					unit.building_unit.speed_prop = unit.final_speed_prop
					unit.building_unit.power_prop = unit.final_power_prop
					UnitAttributes.normalize_proportions(unit.building_unit)
					unit.building_unit.build_finished()
					unit.building_unit = null
					unit.mode = UnitShared.ActionMode.FREE

		UnitShared.ActionMode.BUILD_STOPPING:
			unit.mode_timer -= delta
			if unit.mode_timer <= 0:
				if unit.building_unit:
					unit.building_unit.queue_free()
					unit.building_unit = null
				unit.mode = UnitShared.ActionMode.FREE
				unit.mode_timer = 0
