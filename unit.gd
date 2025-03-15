extends CharacterBody2D

@export var total_energy: float = 100.0

@export var health_prop: float = 0.5
@export var speed_prop: float = 0.3
@export var attack_prop: float = 0.2

var target_health_prop: float
var target_speed_prop: float
var target_attack_prop: float

var health_current: float

func _ready() -> void:
	# Initiera target-variablerna
	target_health_prop = health_prop
	target_speed_prop = speed_prop
	target_attack_prop = attack_prop

	normalize_proportions()
	health_current = 1
	add_to_group("units")

func _physics_process(delta: float) -> void:
	# Smidigt närma oss målvärdena
	var lerp_factor = 2.0 * delta  # Justera efter tycke och smak
	health_prop = lerp(health_prop, target_health_prop, lerp_factor)
	speed_prop = lerp(speed_prop, target_speed_prop, lerp_factor)
	attack_prop = lerp(attack_prop, target_attack_prop, lerp_factor)
	normalize_proportions()

	# Rörelse och wrapping
	var direction = Vector2.ZERO
	velocity = direction.normalized() * get_speed_value()
	move_and_slide()
	global_position = Utils.wrap_position(global_position)
	queue_redraw()

func _draw() -> void:
	# Ritar en cirkel baserad på nuvarande health (exempel)
	# draw_circle(Vector2.ZERO, health_current, Color.RED)
	pass

func normalize_proportions() -> void:
	var sum_props = health_prop + speed_prop + attack_prop
	if sum_props == 0:
		health_prop = 1.0
		speed_prop = 0.0
		attack_prop = 0.0
	else:
		health_prop /= sum_props
		speed_prop /= sum_props
		attack_prop /= sum_props
	var sum_target_props = target_health_prop + target_speed_prop + target_attack_prop
	if sum_target_props == 0:
		target_health_prop = 1.0
		target_speed_prop = 0.0
		target_attack_prop = 0.0
	else:
		target_health_prop /= sum_target_props
		target_speed_prop /= sum_target_props
		target_attack_prop /= sum_target_props

func get_health_max() -> float:
	return max(1.0, health_prop * total_energy)

func get_speed_value() -> float:
	return speed_prop * total_energy

func get_attack_value() -> float:
	return attack_prop * total_energy

func apply_damage(amount: float) -> void:
	health_current = max(0, health_current - amount)
	if health_current <= 0:
		queue_free()

func build_finished() -> void:
	health_current = get_health_max()

# GUI callbacks:
func _on_h_slider_value_changed(value: float) -> void:
	target_health_prop = value

func _on_s_slider_value_changed(value: float) -> void:
	target_speed_prop = value

func _on_p_slider_value_changed(value: float) -> void:
	target_attack_prop = value
