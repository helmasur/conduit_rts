# res://scripts/units/UnitCollect.gd
class_name UnitCollect
#
#static func start_collecting(unit) -> void:
	#if unit.mode == UnitShared.ActionMode.FREE:
		#unit.mode = UnitShared.ActionMode.COLLECT_STARTING
		#unit.mode_timer = unit.collect_start_time
#
#static func stop_collecting(unit) -> void:
	#if unit.mode == UnitShared.ActionMode.COLLECTING:
		#unit.mode = UnitShared.ActionMode.COLLECT_STOPPING
		#unit.mode_timer = unit.collect_stop_time

static func handle_collect_state(unit: Unit, delta: float) -> void:
	match unit.conduit_mode:
		UnitShared.ConduitMode.COLLECTING:
			var space_factor = Utils.calc_free_space_factor(unit.global_position)
			var collected_amount = space_factor * unit.base_collect_rate * delta
			GlobalGameState.player_energy += collected_amount
