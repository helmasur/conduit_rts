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
func calc_free_space_factor(globpos: Vector2) -> float:
	var fsf = 0.0
	var group_name = "units"  # Ändra till den grupp som innehåller dina enheter
	var members = get_tree().get_nodes_in_group(group_name)
	var world_size = Vector2(2048, 2048)
	
	for member in members:
		if globpos != member.global_position:  # Hoppa över oss själva
			var d = toroid_distance(globpos, member.global_position, world_size)
			fsf += 1.0 / d
	fsf = 1.0 / fsf
	fsf = pow(fsf, 1.5) / 2.0
	return fsf
