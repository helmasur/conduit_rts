extends Node2D
class_name Player

var player_energy: float = 100.0

@export var player_color: Color = Color.DEEP_PINK
@export var world_size = Vector2(2048, 2048)
var unit_scene = preload("res://unit.tscn")
@onready var unit_spawner = $UnitSpawner

var id: int

func _enter_tree() -> void:
	pass
	#if not is_multiplayer_authority(): return
	#print("Player: et, peer_id = ", multiplayer.get_unique_id(), " authority = ", get_multiplayer_authority())
	#print("Player: et, id = ", id)
	#set_multiplayer_authority(id, true)

func _ready() -> void:
	print("Player: ready, peer_id = ", multiplayer.get_unique_id(), " authority = ", get_multiplayer_authority())
	if is_multiplayer_authority():
		print("Authority was here")
		var cam : Camera2D = $"../Camera2D"
		cam.make_current()
		spawn_initial_unit()
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
		
func spawn_initial_unit():
	print("Player: spawn, peer_id = ", multiplayer.get_unique_id(), " authority = ", get_multiplayer_authority())
	#if is_multiplayer_authority():
	var unit = unit_scene.instantiate()
	unit.global_position = Vector2.ZERO
	unit.energy = 1000
	unit.target_energy = 1000
	unit.player = self
	add_child(unit)

@rpc("authority", "call_local", "reliable", 0)
func set_player_energy(value: float) -> void:
	player_energy = value

@rpc("authority", "call_local", "reliable", 0)
func add_player_energy(value: float) -> void:
	player_energy += value
	
@rpc("authority", "call_local", "reliable", 0)
func dec_player_energy(value: float) -> void:
	player_energy -= value
