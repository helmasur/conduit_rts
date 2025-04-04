# res://scripts/units/UnitAttributes.gd
class_name UnitAttributes

static func update_proportions(unit: Unit, delta: float) -> void:
	var rate = 200 * delta
	if unit.transform_amount > 0.0:
		unit.transform_current = move_toward(unit.transform_current, unit.transform_amount, rate / unit.energy)
		var ratio = unit.transform_current / unit.transform_amount
		unit.health_prop = unit.old_health_prop + (unit.target_health_prop - unit.old_health_prop) * ratio
		unit.power_prop = unit.old_power_prop + (unit.target_power_prop - unit.old_power_prop) * ratio
		unit.speed_prop = unit.old_speed_prop + (unit.target_speed_prop - unit.old_speed_prop) * ratio
		#unit.health_current = unit.old_health_current + (unit.target_health_current - unit.old_health_current) * ratio
		unit.health_max = get_health_max(unit)
		unit.health_current = min(unit.health_current, unit.health_max)
		#unit.health_prop = move_toward(unit.health_prop, unit.target_health_prop, rate)
		#unit.speed_prop = move_toward(unit.speed_prop, unit.target_speed_prop, rate)
		#unit.power_prop = move_toward(unit.power_prop, unit.target_power_prop, rate)
		#unit.health_current = move_toward(unit.health_current, unit.target_health_current, rate)

static func get_health_max(unit) -> float:
	return max(1.0, unit.health_prop * unit.energy)

static func get_speed_value(unit) -> float:
	return nlf(unit.speed_prop, 3) * unit.energy * unit.speed_factor

static func get_power_value(unit) -> float:
	return unit.power_prop * unit.energy

static func apply_damage(unit, amount: float) -> void:
	unit.health_current = max(0, unit.health_current - amount)
	if unit.health_current <= 0:
		unit.queue_free()

static func build_finished(unit) -> void:
	unit.health_current = get_health_max(unit)
	
static func nlf(value: float, mod: float) -> float:
	#Non linear function - mod=3 is approx x^2
	return (pow(2, mod*value - mod) - pow(2, -mod)) / (1 - pow(2, -mod))
	
