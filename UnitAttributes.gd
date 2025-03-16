# res://scripts/units/UnitAttributes.gd
class_name UnitAttributes

static func update_proportions(unit, delta: float) -> void:
	var rate = 0.2 * delta
	unit.health_prop = move_toward(unit.health_prop, unit.target_health_prop, rate)
	unit.speed_prop = move_toward(unit.speed_prop, unit.target_speed_prop, rate)
	unit.attack_prop = move_toward(unit.attack_prop, unit.target_attack_prop, rate)
	normalize_proportions(unit)

static func normalize_proportions(unit) -> void:
	var sum_props = unit.health_prop + unit.speed_prop + unit.attack_prop
	if sum_props == 0:
		unit.health_prop = 1.0
		unit.speed_prop = 0.0
		unit.attack_prop = 0.0
	else:
		unit.health_prop /= sum_props
		unit.speed_prop /= sum_props
		unit.attack_prop /= sum_props

	var sum_target_props = unit.target_health_prop + unit.target_speed_prop + unit.target_attack_prop
	if sum_target_props == 0:
		unit.target_health_prop = 1.0
		unit.target_speed_prop = 0.0
		unit.target_attack_prop = 0.0
	else:
		unit.target_health_prop /= sum_target_props
		unit.target_speed_prop /= sum_target_props
		unit.target_attack_prop /= sum_target_props

static func get_health_max(unit) -> float:
	return max(1.0, unit.health_prop * unit.total_energy)

static func get_speed_value(unit) -> float:
	return unit.speed_prop * unit.total_energy

static func get_attack_value(unit) -> float:
	return unit.attack_prop * unit.total_energy

static func apply_damage(unit, amount: float) -> void:
	unit.health_current = max(0, unit.health_current - amount)
	if unit.health_current <= 0:
		unit.queue_free()

static func build_finished(unit) -> void:
	unit.health_current = get_health_max(unit)
