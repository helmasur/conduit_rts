# res://scripts/units/UnitAttributes.gd
class_name UnitAttributes

static func update_proportions(unit: Unit, delta: float) -> void:
	var rate = delta * unit.base_transform_rate
	if unit.transform_amount > 0.0:
		unit.transform_current = move_toward(unit.transform_current, unit.transform_amount, rate / unit.energy)
		var ratio = unit.transform_current / unit.transform_amount
		unit.defense_prop = unit.old_defense_prop + (unit.target_defense_prop - unit.old_defense_prop) * ratio
		unit.power_prop = unit.old_power_prop + (unit.target_power_prop - unit.old_power_prop) * ratio
		unit.speed_prop = unit.old_speed_prop + (unit.target_speed_prop - unit.old_speed_prop) * ratio
		#unit.defense_max = get_defense_max(unit)
		#unit.defense_current = min(unit.defense_current, unit.defense_max)

static func get_defense_max(unit) -> float:
	return max(1.0, unit.defense_prop * unit.energy)

static func get_speed_value(unit) -> float:
	return nlf(unit.speed_prop, 3) * unit.energy * unit.speed_factor

static func get_power_value(unit) -> float:
	return unit.power_prop * unit.energy

static func apply_damage(unit, amount: float) -> void:
	unit.defense_current = max(0, unit.defense_current - amount)
	if unit.defense_current <= 0:
		unit.queue_free()

static func build_finished(unit) -> void:
	unit.defense_current = get_defense_max(unit)
	
static func nlf(value: float, mod: float) -> float:
	#Non linear function - mod=3 is approx x^2
	return (pow(2, mod*value - mod) - pow(2, -mod)) / (1 - pow(2, -mod))
	
