extends Node2D
class_name Player

var player_energy: float = 100.0

@export var player_color: Color = Color.DEEP_PINK
@export var world_size = Vector2(2048, 2048)
var unit_scene = preload("res://unit.tscn")
@onready var unit_spawner = $UnitSpawner


func _ready() -> void:
	if not is_multiplayer_authority(): return
	
	
	
	add_to_group("players")
	print("Player ready: ", multiplayer.get_unique_id())
	#var sp = "/root/Player_" + str(multiplayer.get_unique_id())
	#var name = self.name  # Förväntas vara t.ex. "Player_3"
	print(name)
	unit_spawner.spawn_path = NodePath("/root/" + name)
	
	# Debugutskrift för att se vem som har authority
	print("Player node ready. peer_id =", multiplayer.get_unique_id(),
		  "  authority =", get_multiplayer_authority())
	
	# Om denna nod är min lokalt (klientens unika ID == authority),
	# då spawnar jag min enhet:
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		spawn_initial_unit()
		
func spawn_initial_unit():
	print("spawn")
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
