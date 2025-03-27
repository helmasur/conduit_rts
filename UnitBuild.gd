# res://scripts/units/UnitBuild.gd
class_name UnitBuild

static func start_build(unit: Unit, e: float, h: float, p: float, s: float) -> void:
	var new_unit = unit.unit_scene.instantiate() as CharacterBody2D
	unit.get_tree().current_scene.add_child(new_unit)
	unit.unit_to_build = new_unit
	new_unit.global_position = unit.global_position + Vector2(50, 0)
	new_unit.target_energy = e
	new_unit.health_prop = h
	new_unit.power_prop = p
	new_unit.speed_prop = s
	new_unit.target_health_prop = h
	new_unit.target_power_prop = p
	new_unit.target_speed_prop = s
	unit.conduit_mode = UnitShared.ConduitMode.BUILDING
	
static func handle_build_state(unit: Unit, delta: float) -> void:
	match unit.conduit_mode:
		#UnitShared.ActionMode.BUILD_STARTING:
			#unit.mode_timer -= delta
			#if unit.mode_timer <= 0:
				#if unit.build_scene:
					#unit.unit_to_build = unit.build_scene.instantiate() as CharacterBody2D
					#unit.unit_to_build.global_position = unit.global_position + Vector2(50, 0)
					#unit.get_tree().current_scene.add_child(unit.unit_to_build)
#
					#unit.unit_to_build.energy = 1.0
					#unit.unit_to_build.health_prop = 1.0
					#unit.unit_to_build.speed_prop = 0.0
					#unit.unit_to_build.power_prop = 0.0
					#UnitAttributes.normalize_proportions(unit.unit_to_build)
					#unit.unit_to_build.health_current = 1
				#unit.mode = UnitShared.ActionMode.BUILDING
				#unit.mode_timer = 0

		UnitShared.ConduitMode.BUILDING:
			if unit.unit_to_build:
				var transfer_amount = unit.build_transfer_rate * delta
				if unit.get_parent().player_energy < transfer_amount:
					transfer_amount = unit.get_parent().player_energy
				var needed = unit.unit_to_build.target_energy - unit.unit_to_build.energy
				if needed < transfer_amount:
					transfer_amount = needed
				if transfer_amount > 0:
					unit.unit_to_build.energy += transfer_amount
					unit.get_parent().player_energy -= transfer_amount
				if unit.unit_to_build.energy >= unit.unit_to_build.target_energy:
					# Unit är redo
					#UnitAttributes.normalize_proportions(unit.unit_to_build)
					#unit.unit_to_build.mode = UnitShared.ActionMode.FREE
					#unit.unit_to_build.build_finished()
					unit.unit_to_build = null
					unit.mode = UnitShared.ConduitMode.COLLECTING

		#UnitShared.ConduitMode.BUILD_STOPPING:
			#unit.mode_timer -= delta
			#if unit.mode_timer <= 0:
				#if unit.unit_to_build:
					#unit.unit_to_build.queue_free()
					#unit.unit_to_build = null
				#unit.mode = UnitShared.ActionMode.FREE
				#unit.mode_timer = 0
