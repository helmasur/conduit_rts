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
	
# Hjälpfunktion för att räkna ut toroidalt avstånd mellan två punkter i en 2048x2048 värld.
func toroid_distance(p1: Vector2, p2: Vector2, world_size: Vector2) -> float:
	var dx = abs(p1.x - p2.x)
	if dx > world_size.x / 2:
		dx = world_size.x - dx
	var dy = abs(p1.y - p2.y)
	if dy > world_size.y / 2:
		dy = world_size.y - dy
	return sqrt(dx * dx + dy * dy)

# Funktion för att räkna ut ett "free space factor" baserat på avståndet till andra enheter,
# anpassat för en toroid värld (2048x2048).
func calc_free_space_factor(pos: Vector2) -> float:
	var dist_max = sqrt(2.0) * GlobalGameState.world_size.x / 2.0
	var fsf = 1.0
	var units = get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if pos != unit.global_position:  # Hoppa över oss själva
			var dist = toroid_distance(pos, unit.global_position, GlobalGameState.world_size)
			fsf += 1 - (dist / dist_max)
	fsf = 1.0 / fsf
	fsf = sin(fsf*PI/2.0)
	return fsf
