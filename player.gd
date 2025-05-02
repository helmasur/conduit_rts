extends Node2D
class_name Player

@export var player_energy: float = 10000.0
@export var player_id := 0
@export var player_units: Array[int] = []
@export var selected_units: Array[int] = []:
	set(value):
		selected_units = value            # OK, loopar inte rekursivt
		for uid in player_units:          # rör bara våra egna units
			var u := get_node_or_null(str(uid)) as Unit
			if u:
				u.set_selected(uid in selected_units)

@export var player_color: Color = Color.DEEP_PINK
var world_size: Vector2
var unit_scene = preload("res://unit.tscn")
@onready var unit_spawner = $UnitSpawner

#var muid: int # multiplayer user id

func _enter_tree() -> void:
	world_size = get_parent().world_size
	#muid = int(name)
	pass

func _ready() -> void:
	print("Player: ready, peer_id = ", multiplayer.get_unique_id(), " authority = ", get_multiplayer_authority())
	player_id = int(name)
	if player_id == multiplayer.get_unique_id():
		get_parent().player = self
		#set_multiplayer_authority(multiplayer.get_unique_id())
		
	#if is_multiplayer_authority():
		#get_parent().player = self
		#print("Authority was here")
		#var cam : Camera2D = $"../Camera2D"
		#cam.make_current()
		##spawn_initial_unit()
		#spawn_unit(1, .34, .3, .3, Vector2.ZERO).energy = 1
	#else:
		#print("Authority was not here")
		
	if multiplayer.is_server():
		spawn_unit(1, .333, .333, .333, Vector2.ZERO).energy = 1
		
	add_to_group("players")
	
func spawn_unit(e: float, h: float, p: float, s: float, pos: Vector2) -> Unit:
	var new_unit = unit_scene.instantiate() as Unit
	new_unit.global_position = pos
	new_unit.energy_max = e
	new_unit.defense_prop = h
	new_unit.power_prop = p
	new_unit.speed_prop = s
	new_unit.target_defense_prop = h
	new_unit.target_power_prop = p
	new_unit.target_speed_prop = s
	new_unit.unit_id = get_parent().next_unit_id
	new_unit.player = self
	get_parent().next_unit_id += 1
	add_child(new_unit, true)
	#get_parent()._add_unit(new_unit)

	return new_unit
	
#func _set_selected_units(ids: Array[int]) -> void:
	#selected_units = ids
	## highlight: slå av/på .set_selected() på alla units
	#for u in get_tree().get_nodes_in_group("units"):
		#u.set_selected(u.unit_id in selected_units)


@rpc("authority", "call_local", "reliable", 0)
func set_player_energy(value: float) -> void:
	player_energy = value

@rpc("authority", "call_local", "reliable", 0)
func add_player_energy(value: float) -> void:
	player_energy += value
	
@rpc("authority", "call_local", "reliable", 0)
func dec_player_energy(value: float) -> void:
	player_energy -= value
