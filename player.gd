extends Node2D
class_name Player

var player_energy: float = 10000.0

@export var player_color: Color = Color.DEEP_PINK
var world_size: Vector2
var unit_scene = preload("res://unit.tscn")
@onready var unit_spawner = $UnitSpawner

var id: int

func _enter_tree() -> void:
	world_size = get_parent().world_size
	pass
	#if not is_multiplayer_authority(): return
	#print("Player: et, peer_id = ", multiplayer.get_unique_id(), " authority = ", get_multiplayer_authority())
	#print("Player: et, id = ", id)
	#set_multiplayer_authority(id, true)

func _ready() -> void:
	print("Player: ready, peer_id = ", multiplayer.get_unique_id(), " authority = ", get_multiplayer_authority())
	if is_multiplayer_authority():
		get_parent().player = self
		print("Authority was here")
		var cam : Camera2D = $"../Camera2D"
		cam.make_current()
		#spawn_initial_unit()
		spawn_unit(1000, .34, .3, .3, Vector2.ZERO).energy = 1000
	else:
		print("Authority was not here")
	
	add_to_group("players")
	#var sp = "/root/Player_" + str(multiplayer.get_unique_id())
	#var name = self.name  # Förväntas vara t.ex. "Player_3"
	#unit_spawner.spawn_path = NodePath("/root/" + name)
	
	# Debugutskrift för att se vem som har authority
	
	# Om denna nod är min lokalt (klientens unika ID == authority),
	# då spawnar jag min enhet:
	#if get_multiplayer_authority() == multiplayer.get_unique_id():
		#spawn_initial_unit()
		
#func spawn_initial_unit():
	#print("Player: spawn, peer_id = ", multiplayer.get_unique_id(), " authority = ", get_multiplayer_authority())
	##if is_multiplayer_authority():
	#var unit = unit_scene.instantiate()
	#unit.global_position = Vector2.ZERO
	#unit.energy = 1000
	#unit.energy_max = 1000
	#unit.player = self
	#add_child(unit, true)
	
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
	add_child(new_unit, true)
	get_parent()._add_unit(new_unit)
	return new_unit

@rpc("authority", "call_local", "reliable", 0)
func set_player_energy(value: float) -> void:
	player_energy = value

@rpc("authority", "call_local", "reliable", 0)
func add_player_energy(value: float) -> void:
	player_energy += value
	
@rpc("authority", "call_local", "reliable", 0)
func dec_player_energy(value: float) -> void:
	player_energy -= value
