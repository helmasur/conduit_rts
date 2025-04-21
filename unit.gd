# res://scripts/units/Unit.gd
extends CharacterBody2D
class_name Unit

var unit_scene = preload("res://unit.tscn")
var player : Player
@export var unit_id: int = -1


@export var energy_max: float = 1
@export var energy: float = 1
@export var defense: float = 0
@export var power: float = 0
@export var speed: float = 0

@export var base_collect_rate: float = 25.0
@export var base_transfer_rate: float = 25.0
@export var base_transform_rate: float = 25.0
@export var base_attack_factor: float = 1
@export var base_defense_factor: float = 1
@export var base_speed_factor: float = 1
@export var base_conduit_area_factor: float = 300
@export var attack_range: float = 500

var transform_amount: float = 0.0
var transform_current: float
var fsf: float

var defense_prop: float = 0.5
var power_prop: float = 0.2
var speed_prop: float = 0.3
var target_defense_prop: float
var target_power_prop: float
var target_speed_prop: float
var old_defense_prop: float
var old_power_prop: float
var old_speed_prop: float

var destination: Vector2
var nearby_units: Array = []
var repair_queue: Array = []
#var unit_to_build: Unit = null
var unit_to_attack: Unit = null

@export var mode: int = UnitShared.ActionMode.FREE
var conduit_mode: int = UnitShared.ConduitMode.COLLECTING
@export var is_selected: bool = false
var multimesh_instance_indices: Array = []
var player_color = Color.YELLOW_GREEN
var graphics_array: Array = []
var physics_array: Array = []

#func _enter_tree() -> void:
	#set_multiplayer_authority(get_parent().muid, true)

func _ready() -> void:
	name = str(unit_id)
	target_defense_prop = defense_prop
	target_speed_prop = speed_prop
	target_power_prop = power_prop
	_update_attributes()
	destination = global_position
	#$Area2D.connect("body_entered", Callable(self, "_on_proximity_entered"))
	#if is_multiplayer_authority():
		#add_to_group("player_units")
	add_to_group("units")
	
	graphics_array.append($Graphics)
	for offs in Utils.get_toroid_copies(get_parent().world_size):
		var copy = $Graphics.duplicate()
		#copy.set_multiplayer_authority(get_parent().muid)
		copy.position = offs
		graphics_array.append(copy)
		add_child(copy)
		
	for offs in Utils.get_toroid_copies(get_parent().world_size):
		var copy = $CollisionShape2D.duplicate()
		var copy1 = $Area2D.duplicate()
		copy.position = offs
		copy1.position = offs
		#copy.set_multiplayer_authority(get_parent().muid)
		#copy1.set_multiplayer_authority(get_parent().muid)
		physics_array.append(copy)
		physics_array.append(copy1)
		add_child(copy)
		add_child(copy1)

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	handle_state_machine(delta)
	_update_attributes()
	if speed_prop < 0.01: destination = global_position
	if mode == UnitShared.ActionMode.FREE:
		if defense_prop > 0.99:
			mode = UnitShared.ActionMode.CONDUIT
		var dist = destination.distance_to(global_position)
		if dist > 2.0:
			var dir = Utils.toroid_direction(global_position, destination, get_parent().world_size).normalized()
			velocity = dir * speed * base_speed_factor
			
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
	for graphics: Node2D in graphics_array:
		graphics.get_node("ShieldRing").amount_ratio = defense_prop
		graphics.get_node("SpeedRing").amount_ratio = speed_prop
		graphics.get_node("PowerRing").amount_ratio = power_prop

	if is_selected:
		if get_tree().get_node_count_in_group("selected_units") == 1:
			var units = get_tree().get_nodes_in_group("units")
			fsf = Utils.calc_free_space_factor(global_position, get_parent().world_size, units)
			_update_fsfcircle()
			for graphics in graphics_array:
				graphics.get_node("FSFCircle").visible = true
	else:
		for graphics in graphics_array:
			graphics.get_node("FSFCircle").visible = false
			
	if self.is_in_group("selected_units") or mode == UnitShared.ActionMode.CONDUIT:
		var units = get_tree().get_nodes_in_group("units")
		fsf = Utils.calc_free_space_factor(global_position, get_parent().world_size, units)
		

		
	queue_redraw()

func _draw() -> void:
	pass

func handle_state_machine(delta: float) -> void:
	match mode:
		UnitShared.ActionMode.CONDUIT:
			for unit: Unit in nearby_units:
				if unit.energy < unit.energy_max:
					if unit not in repair_queue:
						repair_queue.append(unit)
				else:
					repair_queue.erase(unit)
			
			if defense_prop < 0.99:
				mode = UnitShared.ActionMode.FREE
				return
			for graphics in graphics_array:
				graphics.get_node("ShieldRing").visible = true
				graphics.get_node("SpeedRing").visible = true
				graphics.get_node("PowerRing").visible = true
				graphics.get_node("ConduitArea").visible = true
				graphics.get_node("Laser").visible = false
			if len(repair_queue) > 0:
				if repair_queue[0] != null:
					conduit_mode = UnitShared.ConduitMode.BUILDING
				else: conduit_mode = UnitShared.ConduitMode.COLLECTING
			else: conduit_mode = UnitShared.ConduitMode.COLLECTING
			
			match conduit_mode:
				UnitShared.ConduitMode.COLLECTING:
					var collected_amount = fsf * base_collect_rate * delta
					get_parent().add_player_energy(collected_amount)
				UnitShared.ConduitMode.BUILDING:
					var transfer_amount = base_transfer_rate * delta
					if get_parent().player_energy < transfer_amount:
						transfer_amount = get_parent().player_energy
					var needed = repair_queue[0].energy_max - repair_queue[0].energy
					if needed < transfer_amount:
						transfer_amount = needed
					if transfer_amount > 0:
						repair_queue[0].energy += transfer_amount
						get_parent().player_energy -= transfer_amount
					if repair_queue[0].energy >= repair_queue[0].energy_max:
						if repair_queue[0].mode == UnitShared.ActionMode.UNDER_CONSTRUCTION:
							repair_queue[0].mode = UnitShared.ActionMode.FREE
						repair_queue.pop_front()
			
		UnitShared.ActionMode.UNDER_CONSTRUCTION:
			for graphics in graphics_array:
				graphics.get_node("ShieldRing").visible = false
				graphics.get_node("SpeedRing").visible = false
				graphics.get_node("PowerRing").visible = false
				graphics.get_node("ConduitArea").visible = false
			pass
		UnitShared.ActionMode.ATTACKING:
			if unit_to_attack:
				var dir = Utils.toroid_direction(global_position, unit_to_attack.global_position, get_parent().world_size)
				var v = dir
				unit_to_attack.apply_damage(power * delta * base_attack_factor)
				for graphics in graphics_array:
					var l: Line2D = graphics.get_node("Laser")
					l.visible = true
					l.points[1].x = v.x
					l.points[1].y = v.y
			else:
				mode = UnitShared.ActionMode.FREE
				
		UnitShared.ActionMode.FREE:
			for graphics in graphics_array:
				graphics.get_node("ShieldRing").visible = true
				graphics.get_node("SpeedRing").visible = true
				graphics.get_node("PowerRing").visible = true
				graphics.get_node("ConduitArea").visible = false
				graphics.get_node("Laser").visible = false
			pass
		_:
			# ActionMode.FREE eller annat
			pass

func set_selected(selected: bool) -> void:
	is_selected = selected
	if selected:
		self.add_to_group("selected_units")
		for graphics: Node2D in graphics_array:
			graphics.get_node("Selected").visible = true
	else:
		for graphics: Node2D in graphics_array:
			graphics.get_node("Selected").visible = false
		self.remove_from_group("selected_units")

func set_destination(pos: Vector2) -> void:
	if mode == UnitShared.ActionMode.FREE or mode == UnitShared.ActionMode.ATTACKING:
		mode = UnitShared.ActionMode.FREE
		destination = pos
		unit_to_attack = null
	

func request_attack(unit: Unit):
	if mode == UnitShared.ActionMode.FREE or mode == UnitShared.ActionMode.ATTACKING:
		if Utils.toroid_distance(global_position, unit.global_position, get_parent().world_size) <= attack_range:
			mode = UnitShared.ActionMode.ATTACKING
			unit_to_attack = unit

func apply_damage(amount: float) -> void:
	energy -= (amount / (defense * base_defense_factor + 1))
	if energy <= 0:
		queue_free()
		
func _update_attributes():
	defense = defense_prop * energy_max
	power = power_prop * energy_max
	speed = speed_prop * energy_max
	
func _update_fsfcircle():
	var np = 64
	var points = PackedVector2Array()
	for p in range(np):
		var v = Vector2(cos(2*PI*p/np), sin(2*PI*p/np))
		v *= fsf * base_conduit_area_factor
		points.append(v)
	for graphics in graphics_array:
		graphics.get_node("FSFCircle").points = points

func _on_area_2d_body_entered(unit: Node2D) -> void:
	if unit is Unit and unit != self:
		if not unit in nearby_units:
			nearby_units.append(unit)
			

func _on_area_2d_body_exited(unit: Node2D) -> void:
	if unit is Unit:
		nearby_units.erase(unit)
	
