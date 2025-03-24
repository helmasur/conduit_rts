extends Node2D

@export var player_color: Color = Color.DEEP_PINK
@export var player_energy = 10000
@export var world_size = Vector2(2048, 2048)

func _ready() -> void:
	get_parent().print_tree()
	var unit_scene = preload("res://unit.tscn")
	#var unit_one = unit_scene.instantiate()
	#add_child(unit_one)
	#unit_one.build_finished()
	
	for n in range(3):
		var unit = unit_scene.instantiate()
		#unit.build_finished()
		unit.global_position = Vector2(n * 300 + 100, 100)
		unit.energy = 1000
		unit.target_energy = 1000
		add_child(unit)
		
