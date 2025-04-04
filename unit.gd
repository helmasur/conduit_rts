# res://scripts/units/Unit.gd
extends CharacterBody2D
class_name Unit

var unit_scene = preload("res://unit.tscn")
var player : Player

var target_energy: float = 0.0
var energy: float = 0.0
var health_max: float
var health_current: float = 1
var power: float

@export var speed_factor: float = 2
@export var base_collect_rate: float = 5.0
@export var build_transfer_rate: float = 5.0

var transform_amount: float = 0.0
var transform_current: float
var fsf: float

@export var health_prop: float = 0.5
@export var power_prop: float = 0.2
@export var speed_prop: float = 0.3
var target_health_prop: float
var target_power_prop: float
var target_speed_prop: float
var old_health_prop: float
var old_power_prop: float
var old_speed_prop: float

var destination: Vector2
var nearby_units: Array = []
var build_queue: Array = []
var unit_to_build: Unit = null
var unit_to_attack: Unit = null
var unit_to_repair: Unit = null

var mode: int = UnitShared.ActionMode.FREE
var conduit_mode: int = UnitShared.ConduitMode.COLLECTING
var is_selected: bool = false

func _ready() -> void:
	target_health_prop = health_prop
	target_speed_prop = speed_prop
	target_power_prop = power_prop
	health_max = UnitAttributes.get_health_max(self)
	health_current = health_max / 2 ##for testing
	add_to_group("units")
	destination = global_position
	$Area2D.connect("body_entered", Callable(self, "_on_proximity_entered"))

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	handle_state_machine(delta)
	if speed_prop < 0.01: destination = global_position
	if energy < target_energy:
		# Enheten ej färdigbyggd
		mode = UnitShared.ActionMode.UNDER_CONSTRUCTION
	elif health_prop > 0.99:
		# Conduit mode
		mode = UnitShared.ActionMode.CONDUIT
	else:
		mode = UnitShared.ActionMode.FREE
		
	if mode == UnitShared.ActionMode.FREE:
		var dist = destination.distance_to(global_position)
		var speed = UnitAttributes.get_speed_value(self)
		if dist > 2.0:
			var dir = Utils.toroid_direction(global_position, destination, player.world_size).normalized()
			velocity = dir * speed
			
			# UNDERSÖK om vi kommer passera destinationen under detta frame
			var frame_movement = velocity * delta
			if frame_movement.length() >= dist:
				# Vi skulle överskjuta -> hoppa till destination och stoppa
				global_position = destination
				velocity = Vector2.ZERO
			else:
				move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

	var wrap_pos = Utils.wrap_position(global_position)
	if global_position != wrap_pos:
		global_position = wrap_pos
		destination = Utils.wrap_position(destination)

	UnitAttributes.update_proportions(self, delta)

	if self. is_in_group("selected") or mode == UnitShared.ActionMode.CONDUIT:
		var units = get_tree().get_nodes_in_group("units")
		fsf = Utils.calc_free_space_factor(global_position, player.world_size, units)
		
	queue_redraw()

func _draw() -> void:
	if is_multiplayer_authority():
		var size = 30.0
		var color = player.player_color

		# Rita 9 kopior
		for offset in Utils.get_toroid_offsets(player.world_size):
			var rect = Rect2(Vector2(-size/2, -size/2), Vector2(size, size))
			draw_set_transform(offset)
			draw_rect(rect, color, false, 2.0, true)
			if is_selected:
				rect = Rect2(Vector2(-size/2-3, -size/2-3), Vector2(size+6, size+6))
				draw_rect(rect, Color.BEIGE, false, -1)
				draw_circle(Vector2.ZERO, fsf*300, Color.FLORAL_WHITE, false, -1.0, false) #ingen AA för width <0
			elif conduit_mode == UnitShared.ConduitMode.COLLECTING:
				draw_circle(Vector2.ZERO, fsf*300, Color.FLORAL_WHITE, false, -1.0, false) #ingen AA för width <0

		# Återställ transform (för säkerhets skull)
		draw_set_transform(Vector2.ZERO)

func handle_state_machine(delta: float) -> void:
	match mode:
		UnitShared.ActionMode.CONDUIT:
			match conduit_mode:
				UnitShared.ConduitMode.COLLECTING:
					#UnitCollect.handle_collect_state(self, delta)
					var collected_amount = fsf * base_collect_rate * delta
					player.add_player_energy(collected_amount)
				UnitShared.ConduitMode.BUILDING:
					UnitBuild.handle_build_state(self, delta)
			
		UnitShared.ActionMode.UNDER_CONSTRUCTION:
			pass

		_:
			# ActionMode.FREE eller annat
			pass

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		self.add_to_group("selected_units")
	else:
		self.remove_from_group("selected_units")

func set_destination(pos: Vector2) -> void:
	destination = pos

func start_build(e: float, h: float, p: float, s: float) -> void:
	if e > 0:
		UnitBuild.start_build(self, e, h, p, s)

func apply_damage(amount: float) -> void:
	UnitAttributes.apply_damage(self, amount)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Unit and body != self:
		nearby_units.append(body)
	else: return

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Unit:
		nearby_units.erase(body)
	if unit_to_attack == body: unit_to_attack = null
	if unit_to_repair == body: unit_to_repair = null
	
