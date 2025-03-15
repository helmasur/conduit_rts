extends CharacterBody2D

enum ActionMode {
	FREE,
	COLLECT_STARTING,
	COLLECTING,
	COLLECT_STOPPING
}

@export var total_energy: float = 100.0

@export var health_prop: float = 0.5
@export var speed_prop: float = 0.3
@export var attack_prop: float = 0.2

var target_health_prop: float
var target_speed_prop: float
var target_attack_prop: float

var health_current: float

var mode: ActionMode = ActionMode.FREE
var mode_timer: float = 0.0

@export var collect_start_time: float = 3.0
@export var collect_stop_time: float = 2.0
@export var base_collect_rate: float = 5.0

# ---- Nya variabler för selektion och rörelse ----
var is_selected: bool = false
var destination: Vector2

func _ready() -> void:
	target_health_prop = health_prop
	target_speed_prop = speed_prop
	target_attack_prop = attack_prop

	normalize_proportions()
	health_current = 1
	
	# Initiera destination till nuvarande position så att enheten inte "rusar i väg"
	destination = global_position
	
	add_to_group("units")

func _physics_process(delta: float) -> void:
	handle_state_machine(delta)

	# Endast i FREE-läget tillåter vi "manuell" rörelse mot en destination
	if mode == ActionMode.FREE:
		# Enkel "gå mot destination"-logik
		var dist = destination.distance_to(global_position)
		if dist > 2.0:  # tröskel så den inte skakar kring målpunkten
			var dir = (destination - global_position).normalized()
			velocity = dir * get_speed_value()
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
	else:
		# I andra lägen t.ex. insamling = ingen rörelse
		velocity = Vector2.ZERO
		move_and_slide()

	# Wrap-positionen för toroidal karta
	global_position = Utils.wrap_position(global_position)

	# Mjuk övergång för attribut
	update_proportions(delta)

	queue_redraw()

func _draw() -> void:
	# Rita exempelvis en cirkel för att visa liv (om du vill):
	# draw_circle(Vector2.ZERO, health_current, Color.RED)

	# Om enheten är vald, rita en grön ruta runt dess “storlek”
	if is_selected:
		# Här väljer vi en enkel storlek. Du kan anpassa beroende på enhetens form.
		var size = 30.0
		var rect = Rect2(Vector2(-size/2, -size/2), Vector2(size, size))
		draw_rect(rect, Color(0,1,0), false, 2.0)  # (fylld=false, tjocklek=2)

# ======================
# Tillståndsmaskin för insamling
# ======================
func handle_state_machine(delta: float) -> void:
	match mode:
		ActionMode.FREE:
			# Här kan man lyssna om spelaren initierar insamling.
			pass

		ActionMode.COLLECT_STARTING:
			mode_timer -= delta
			if mode_timer <= 0:
				mode = ActionMode.COLLECTING
				mode_timer = 0

		ActionMode.COLLECTING:
			# Samlar energi
			var space_factor = Utils.calc_free_space_factor(global_position)
			var collected_amount = space_factor * base_collect_rate * delta
			GlobalGameState.player_energy += collected_amount

		ActionMode.COLLECT_STOPPING:
			mode_timer -= delta
			if mode_timer <= 0:
				mode = ActionMode.FREE
				mode_timer = 0

func start_collecting() -> void:
	if mode == ActionMode.FREE:
		mode = ActionMode.COLLECT_STARTING
		mode_timer = collect_start_time

func stop_collecting() -> void:
	if mode == ActionMode.COLLECTING:
		mode = ActionMode.COLLECT_STOPPING
		mode_timer = collect_stop_time

# ======================
# Mjuk övergång av attribut
# ======================
func update_proportions(delta: float) -> void:
	var lerp_factor = 2.0 * delta
	health_prop = lerp(health_prop, target_health_prop, lerp_factor)
	speed_prop = lerp(speed_prop, target_speed_prop, lerp_factor)
	attack_prop = lerp(attack_prop, target_attack_prop, lerp_factor)
	normalize_proportions()

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

# ===============
# GUI callbacks (frivilligt om du har sliders)
# ===============
func _on_h_slider_value_changed(value: float) -> void:
	target_health_prop = value

func _on_s_slider_value_changed(value: float) -> void:
	target_speed_prop = value

func _on_p_slider_value_changed(value: float) -> void:
	target_attack_prop = value


# =========================
# Publika hjälpfunktioner 
# =========================

func set_selected(selected: bool) -> void:
	is_selected = selected

func set_destination(pos: Vector2) -> void:
	destination = pos
