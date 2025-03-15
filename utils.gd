extends Node  # Autoload behöver en nod att existera på, även om vi bara använder funktioner

func wrap_position(pos: Vector2) -> Vector2:
	var world_size = Vector2(2048, 2048)
	
	if pos.x < 0:
		pos.x += world_size.x
	elif pos.x >= world_size.x:
		pos.x -= world_size.x
		
	if pos.y < 0:
		pos.y += world_size.y
	elif pos.y >= world_size.y:
		pos.y -= world_size.y
		
	return pos
