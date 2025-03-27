extends Node2D
class_name Player

var player_energy: float = 100.0

@export var player_color: Color = Color.DEEP_PINK
@export var world_size = Vector2(2048, 2048)
var unit_scene = preload("res://unit.tscn")

func _ready() -> void:
	add_to_group("players")
	print("Player ready: ", multiplayer.get_unique_id())

func spawn_initial_unit():
	var unit = unit_scene.instantiate()
	unit.global_position = Vector2.ZERO
	unit.energy = 1000
	unit.target_energy = 1000
	#unit.world_size = world_size
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
