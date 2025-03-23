# res://scripts/units/Unit.gd
extends CharacterBody2D
class_name Unit

# Ladda in våra nya script
#const UnitShared = preload("res://UnitShared.gd")
#const UnitAttributes = preload("res://UnitAttributes.gd")
#const UnitCollect = preload("res://UnitCollect.gd")
#const UnitBuild = preload("res://UnitBuild.gd")

var target_energy: float = 0.0
var energy: float = 0.0
var health: float
var health_current: float = 1
var power: float
var speed: float

@export var health_prop: float = 0.5
@export var power_prop: float = 0.2
@export var speed_prop: float = 0.3
@export var speed_factor: float = 1

var target_health_prop: float
var target_power_prop: float
var target_speed_prop: float

var fsf: float

var mode: int = UnitShared.ActionMode.FREE
var conduit_mode: int = UnitShared.ConduitMode.COLLECTING

@export var base_collect_rate: float = 5.0
@export var build_transfer_rate: float = 5.0

@export var unit_scene: PackedScene = preload("res://unit.tscn")

var nearby_units: Array = []
var build_queue: Array = []
var unit_to_build: Unit = null
var unit_to_attack: Unit = null
var unit_to_repair: Unit = null

var is_selected: bool = false
var destination: Vector2

func _ready() -> void:
	target_health_prop = health_prop
	target_speed_prop = speed_prop
	target_power_prop = power_prop
	#UnitAttributes.normalize_proportions(self)
	add_to_group("units")
	destination = global_position
	$Area2D.connect("body_entered", Callable(self, "_on_proximity_entered"))

func _physics_process(delta: float) -> void:
	handle_state_machine(delta)
	if speed_prop < 0.01: destination = global_position
	
	if energy < target_energy:
		# Enheten ej färdigbyggd
		mode = UnitShared.ActionMode.UNDER_CONSTRUCTION
		#add_to_group("unfinished")
		
	elif health_prop > 0.99:
		# Conduit mode
		mode = UnitShared.ActionMode.CONDUIT
		
	else:
		mode = UnitShared.ActionMode.FREE
		
		#var transaction = build_transfer_rate * delta / fsf
		#var diff = nearest_unfinished.target_energy - nearest_unfinished.energy
		#if diff > transaction:
			#GlobalGameState.player_energy -= transaction
			#nearest_unfinished.energy += transaction
		#else:
			#GlobalGameState.player_energy -= diff
			#nearest_unfinished.energy += diff
		
				
		#var collected_amount = fsf * base_collect_rate * delta
		#GlobalGameState.player_energy += collected_amount
	#else:
		#mode = UnitShared.ActionMode.FREE
		#remove_from_group("unfinished")
	
	if mode == UnitShared.ActionMode.FREE:
		var dist = destination.distance_to(global_position)
		var speed = UnitAttributes.get_speed_value(self)
		if dist > 2.0:
			var dir = (destination - global_position).normalized()
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

	fsf = Utils.calc_free_space_factor(global_position)
	queue_redraw()

func _draw() -> void:
	if is_selected:
		var size = 30.0
		var rect = Rect2(Vector2(-size/2, -size/2), Vector2(size, size))
		draw_rect(rect, Color(0,1,0), false, 2.0)
		draw_circle(Vector2.ZERO, fsf*300, Color.FLORAL_WHITE, false, -1.0, false) #ingen AA för width <0

func handle_state_machine(delta: float) -> void:
	match mode:
		UnitShared.ActionMode.CONDUIT:
			match conduit_mode:
				UnitShared.ConduitMode.COLLECTING:
					#UnitCollect.handle_collect_state(self, delta)
					var space_factor = Utils.calc_free_space_factor(global_position)
					var collected_amount = space_factor * base_collect_rate * delta
					GlobalGameState.player_energy += collected_amount
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
	
