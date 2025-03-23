extends Node2D

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
		
