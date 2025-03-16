extends CharacterBody2D

enum ActionMode {
	FREE,
	COLLECT_STARTING,
	COLLECTING,
	COLLECT_STOPPING,
	BUILD_STARTING,
	BUILDING,
	BUILD_STOPPING
}

@export var total_energy: float = 100.0

@export var health_prop: float = 0.5
@export var speed_prop: float = 0.3
@export var attack_prop: float = 0.2

var target_health_prop: float
var target_speed_prop: float
var target_attack_prop: float

var health_current: float

var fsf: float

var mode: ActionMode = ActionMode.FREE
var mode_timer: float = 0.0

@export var collect_start_time: float = 0.0
@export var collect_stop_time: float = 0.0
@export var base_collect_rate: float = 5.0
@export var build_start_time: float = 0.0
@export var build_stop_time: float = 0.0
@export var build_cost: float = 50.0

@export var build_scene: PackedScene = preload("res://unit.tscn")
@export var build_target_energy: float = 50.0   # Hur mycket energi den nya enheten ska få
@export var build_transfer_rate: float = 10.0   # Hur snabbt energi överförs
@export var final_health_prop: float = 0.5      # Slutlig fördelning för nya enheten
@export var final_speed_prop: float = 0.3
@export var final_attack_prop: float = 0.2

var building_unit: CharacterBody2D = null   # Referens till den enhet vi bygger

# Pekare på scenen (PackedScene) för den enhet du vill instansiera
#@export var unit_scene: PackedScene = preload("res://unit.tscn")

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
	
	fsf = Utils.calc_free_space_factor(global_position)
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
				
		ActionMode.BUILD_STARTING:
			mode_timer -= delta
			if mode_timer <= 0:
				print("qwe")
				# 1) Skapa nya enheten direkt i scenen
				if build_scene:
					building_unit = build_scene.instantiate() as CharacterBody2D
					# Placera den t.ex. bredvid byggaren
					building_unit.global_position = global_position + Vector2(50, 0)
					get_tree().current_scene.add_child(building_unit)

					# 2) Minimala attribut: total_energy ~1, health_prop=1, speed=0, attack=0
					building_unit.total_energy = 1.0
					building_unit.health_prop = 1.0
					building_unit.speed_prop = 0.0
					building_unit.attack_prop = 0.0
					building_unit.normalize_proportions()
					# Sätt dess health_current så den inte dör i förväg
					building_unit.health_current = 1

				# Gå nu över till själva bygg-fasen
				mode = ActionMode.BUILDING
				mode_timer = 0  # eller en "byggtid" om du vill ha extra tidsregler

		ActionMode.BUILDING:
			if building_unit:
				# 1) Räkna ut hur mycket energi vi kan överföra denna frame
				var transfer_amount = build_transfer_rate * delta
				if GlobalGameState.player_energy < transfer_amount:
					transfer_amount = GlobalGameState.player_energy

				# 2) Kolla hur mycket den nya enheten behöver för att nå build_target_energy
				var needed = build_target_energy - building_unit.total_energy
				if needed < transfer_amount:
					transfer_amount = needed

				# 3) Genomför överföring
				if transfer_amount > 0:
					building_unit.total_energy += transfer_amount
					GlobalGameState.player_energy -= transfer_amount

				# 4) Är enheten färdigbyggd?
				if building_unit.total_energy >= build_target_energy:
					# Sätt slutliga attribut
					building_unit.health_prop = final_health_prop
					building_unit.speed_prop = final_speed_prop
					building_unit.attack_prop = final_attack_prop
					building_unit.normalize_proportions()
					building_unit.build_finished()  # sätter health_current = get_health_max()

					building_unit = null
					mode = ActionMode.FREE

		ActionMode.BUILD_STOPPING:
			mode_timer -= delta
			if mode_timer <= 0:
				# Avbryt bygget. Här bestämmer du vad som ska hända med den halvfärdiga enheten.
				if building_unit:
					# Exempel 1: Låt den finnas kvar med sin nuvarande energi & attribut
					# building_unit = null

					# Exempel 2: Ta bort den helt
					building_unit.queue_free()
					building_unit = null

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
	var rate = 0.2 * delta
	health_prop = move_toward(health_prop, target_health_prop, rate)
	speed_prop = move_toward(speed_prop, target_speed_prop, rate)
	attack_prop = move_toward(attack_prop, target_attack_prop, rate)
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
	
func finish_build() -> void:
	# Kolla om spelaren har tillräckligt med energi i sin globala pott
	if GlobalGameState.player_energy >= build_cost:
		# Dra av energi
		GlobalGameState.player_energy -= build_cost

		## Skapa (instance) den nya enheten
		#if unit_scene:
			#var new_unit = unit_scene.instantiate()
			## Placera bredvid den byggande enheten, t.ex. 50 pixlar till höger
			#new_unit.global_position = global_position + Vector2(50, 0)
			## Lägg till i scenträdet
			#get_tree().current_scene.add_child(new_unit)
	
func start_build() -> void:
# Kolla t.ex. att enhetens speed_prop och attack_prop är 0 
# om du vill följa "endast byggare kan bygga"-regeln
	if mode == ActionMode.FREE and speed_prop == 0 and attack_prop == 0:
		mode = ActionMode.BUILD_STARTING
		mode_timer = build_start_time

func stop_build() -> void:
	if mode == ActionMode.BUILDING:
		# Gå till STOPPING-läget om vi vill ha en avbrytstid
		mode = ActionMode.BUILD_STOPPING
		mode_timer = build_stop_time

	
	# Gå tillbaka till FREE-läget oavsett om energin räckte
	mode = ActionMode.FREE
	mode_timer = 0

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

func _on_collect_button_pressed() -> void:
	if mode == ActionMode.FREE:
		start_collecting()
	elif mode == ActionMode.COLLECTING:
		stop_collecting()


func _on_build_button_pressed() -> void:
	if mode == ActionMode.FREE:
		start_build()
	elif mode == ActionMode.BUILDING:
		stop_build()
