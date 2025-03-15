extends Node2D

func _ready() -> void:
	print_tree()
	var unit_scene = preload("res://unit.tscn")
	for i in range(30):
		var unit_instance = unit_scene.instantiate()
		# Justera positionen så att de inte hamnar på exakt samma ställe
		unit_instance.position = Vector2(50 * i, 10)
		add_child(unit_instance)
