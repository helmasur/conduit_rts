# utils.gd
class_name Utils

static func wrap_position(pos: Vector2) -> Vector2:
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
static func toroid_distance(p1: Vector2, p2: Vector2, world_size: Vector2) -> float:
	var dx = abs(p1.x - p2.x)
	if dx > world_size.x / 2:
		dx = world_size.x - dx
	var dy = abs(p1.y - p2.y)
	if dy > world_size.y / 2:
		dy = world_size.y - dy
	return sqrt(dx * dx + dy * dy)

static func toroid_direction(from: Vector2, to: Vector2, world_size: Vector2) -> Vector2:
	var dx = to.x - from.x
	var dy = to.y - from.y

	# Wrap i X-led
	if abs(dx) > world_size.x / 2:
		if dx > 0:
			dx -= world_size.x
		else:
			dx += world_size.x

	# Wrap i Y-led
	if abs(dy) > world_size.y / 2:
		if dy > 0:
			dy -= world_size.y
		else:
			dy += world_size.y

	return Vector2(dx, dy)


# Funktion för att räkna ut ett "free space factor" baserat på avståndet till andra enheter,
# anpassat för en toroid värld (2048x2048).
static func calc_free_space_factor(pos: Vector2, world_size: Vector2, units: Array) -> float:
	var dist_max = sqrt(2.0) * world_size.x / 2.0
	var fsf = 1.0
	#var units = get_tree().get_nodes_in_group("units")
	
	for unit in units:
		if pos != unit.global_position:  # Hoppa över oss själva
			var dist = toroid_distance(pos, unit.global_position, world_size)
			fsf += 1 - (dist / dist_max)
	fsf = 1.0 / fsf
	fsf = sin(fsf*PI/2.0)
	return fsf

static func get_toroid_offsets(world_size: Vector2) -> Array[Vector2]:
	return [
		Vector2(-world_size.x, -world_size.y),
		Vector2(0, -world_size.y),
		Vector2(world_size.x, -world_size.y),
		Vector2(-world_size.x, 0),
		Vector2(world_size.x, 0),
		Vector2(-world_size.x, world_size.y),
		Vector2(0, world_size.y),
		Vector2(world_size.x, world_size.y),
		Vector2(0, 0)
	]

static func get_toroid_copies(world_size: Vector2) -> Array[Vector2]:
	return [
		Vector2(-world_size.x, -world_size.y),
		Vector2(0, -world_size.y),
		Vector2(world_size.x, -world_size.y),
		Vector2(-world_size.x, 0),
		Vector2(world_size.x, 0),
		Vector2(-world_size.x, world_size.y),
		Vector2(0, world_size.y),
		Vector2(world_size.x, world_size.y)
	]

static func get_unit_at_wrapped_position(pos: Vector2, world_size: Vector2) -> Node:
	var space_state = Engine.get_main_loop().root.world_2d.direct_space_state
	var query = PhysicsPointQueryParameters2D.new()

	for offset in get_toroid_offsets(world_size):
		query.position = pos + offset
		var results = space_state.intersect_point(query)
		if results.size() > 0:
			for result in results:
				if result.collider.is_in_group("units"):
					return result.collider
	return null
