extends CharacterBody2D

enum ActionMode {
	FREE,              # Kan röra sig/anfalla
	COLLECT_STARTING,  # Fördröjning innan själva insamlingen
	COLLECTING,        # Aktivt samlar energi
	COLLECT_STOPPING   # Fördröjning för att avbryta insamling
}

@export var total_energy: float = 100.0

@export var health_prop: float = 0.5
@export var speed_prop: float = 0.3
@export var attack_prop: float = 0.2

var target_health_prop: float
var target_speed_prop: float
var target_attack_prop: float

var health_current: float

# Tillstånd och timers
var mode: ActionMode = ActionMode.FREE
var mode_timer: float = 0.0

# Hur lång tid det tar att starta/stoppa insamling (sekunder)
@export var collect_start_time: float = 3.0
@export var collect_stop_time: float = 2.0

# Hur mycket energi man samlar in, multipliceras även av "free_space"-faktorn.
@export var base_collect_rate: float = 5.0

func _ready() -> void:
	target_health_prop = health_prop
	target_speed_prop = speed_prop
	target_attack_prop = attack_prop

	normalize_proportions()
	health_current = 1
	add_to_group("units")

func _physics_process(delta: float) -> void:
	# 1) Hantera övergångar mellan tillstånd
	handle_state_machine(delta)

	# 2) Bara om vi är i FREE får vi röra oss och anfalla
	if mode == ActionMode.FREE:
		var direction = Vector2.ZERO
		# direction.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		# direction.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
		velocity = direction.normalized() * get_speed_value()
		move_and_slide()
		global_position = Utils.wrap_position(global_position)
	else:
		# I andra tillstånd står man still, eller har annan logik
		velocity = Vector2.ZERO
		move_and_slide()
		# Men vi låter wrap_position gälla så man inte ”fastnar” vid kanten
		global_position = Utils.wrap_position(global_position)
	
	# 3) Hantera mjuk övergång av attribut
	update_proportions(delta)

	queue_redraw()

func _draw() -> void:
	# Exempel: Ritar en cirkel baserat på nuvarande hälsa
	# draw_circle(Vector2.ZERO, health_current, Color.RED)
	pass

# ------------------------------
# TILLSTÅNDSMASKIN FÖR INSAMLING
# ------------------------------
func handle_state_machine(delta: float) -> void:
	match mode:
		ActionMode.FREE:
			# Här kan du checka om spelaren t.ex. tryckt på en "Samla energi"-knapp.
			# Om ja -> gå till COLLECT_STARTING
			pass

		ActionMode.COLLECT_STARTING:
			mode_timer -= delta
			if mode_timer <= 0:
				# Klar med uppstarts-fördröjning, gå in i COLLECTING
				mode = ActionMode.COLLECTING
				mode_timer = 0.0

		ActionMode.COLLECTING:
			# Här sker insamlingen! 
			# Räkna ut hur mycket energi som adderas till spelarens globala pott
			var space_factor = Utils.calc_free_space_factor(global_position)
			var collected_amount = space_factor * base_collect_rate * delta
			# Exempel: Lägg till i en global pott
			GlobalGameState.player_energy += collected_amount

			# Om spelaren vill avbryta insamlingen (t.ex. trycker på en "Avbryt"-knapp)
			# så sätter vi mode = COLLECT_STOPPING
			pass

		ActionMode.COLLECT_STOPPING:
			mode_timer -= delta
			if mode_timer <= 0:
				# Klart med avbrytnings-fördröjning
				mode = ActionMode.FREE
				mode_timer = 0.0

# Kallas t.ex. från en knapp i UI eller i kod när man vill börja samla
func start_collecting() -> void:
	if mode == ActionMode.FREE:
		mode = ActionMode.COLLECT_STARTING
		mode_timer = collect_start_time

# Kallas när man vill sluta samla
func stop_collecting() -> void:
	if mode == ActionMode.COLLECTING:
		mode = ActionMode.COLLECT_STOPPING
		mode_timer = collect_stop_time

# ------------------------------
# MJUK ÖVERGÅNG AV ATTRIBUT
# ------------------------------
func update_proportions(delta: float) -> void:
	var lerp_factor = 2.0 * delta
	health_prop = lerp(health_prop, target_health_prop, lerp_factor)
	speed_prop = lerp(speed_prop, target_speed_prop, lerp_factor)
	attack_prop = lerp(attack_prop, target_attack_prop, lerp_factor)
	normalize_proportions()

# ------------------------------
# PROPORTIONSHANTERING OCH SKADA
# ------------------------------
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

# ------------------------------
# GUI callbacks (om du vill fortsätta med proportioner)
# ------------------------------
func _on_h_slider_value_changed(value: float) -> void:
	target_health_prop = value

func _on_s_slider_value_changed(value: float) -> void:
	target_speed_prop = value

func _on_p_slider_value_changed(value: float) -> void:
	target_attack_prop = value
