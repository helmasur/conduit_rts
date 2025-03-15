extends Node2D

func _ready() -> void:
	print_tree()
	
	for n in range(10):
		add_child(get_child(0).duplicate())
		
