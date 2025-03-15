extends Node2D

func _ready() -> void:
	print_tree()
	var unit_scene = preload("res://unit.tscn")
	var unit_one = unit_scene.instantiate()
	add_child(unit_one)
	unit_one.build_finished()
