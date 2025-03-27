extends Node2D
class_name TriTileMap

@export var base_color: Color = Color.from_hsv(0.33, 0.6, 0.7) : set = _regenerate
@export var h_variance: float = 0.05 : set = _regenerate
@export var s_variance: float = 0.1 : set = _regenerate
@export var v_variance: float = 0.1 : set = _regenerate
@export var side_length: float = 64.0 : set = _regenerate

var mesh: Mesh = null
var tiles_x: int = 0
var tiles_y: int = 0

func _ready() -> void:
	_regenerate()

func _regenerate(_v = null) -> void:
	_generate_mesh()

func _generate_mesh() -> void:
	# 1) Hämta world_size från Player-syskon
	var root = get_tree().current_scene
	var player = root.get_node_or_null("Player")
	if player == null:
		printerr("No sibling 'Player' node found. Cannot compute tile size.")
		mesh = null
		queue_redraw()
		return

	var w = player.world_size.x
	var h = player.world_size.y

	# 2) Räkna ut hur många tile-kolumner och rader som behövs
	var tri_height = side_length * sqrt(3) * 0.5

	tiles_x = int(floor(w / side_length))

	tiles_y = int(floor(h / tri_height))

	if tiles_x <= 0 or tiles_y <= 0:
		mesh = null
		queue_redraw()
		return

	# 3) Skapa arrays för att bygga mesh
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices = PackedVector2Array()
	var colors   = PackedColorArray()
	var indices  = PackedInt32Array()

	var idx = 0

	for y in range(tiles_y):
		for x in range(tiles_x):
			var offset_x = x * side_length * 0.5
			var offset_y = y * tri_height * 0.5

			var is_up = ((x + y) % 2) == 0

			# Koordinater för en "grund-triangel"
			var a = Vector2(0, 0)
			var b = Vector2(side_length, 0)
			var c = Vector2(side_length * 0.5, tri_height)

			var p1 = (a if is_up else c)
			var p2 = (b if is_up else a)
			var p3 = (c if is_up else b)

			var base_pos = Vector2(offset_x, offset_y)
			vertices.append(base_pos + p1)
			vertices.append(base_pos + p2)
			vertices.append(base_pos + p3)

			var color = _get_color(x, y)
			colors.append(color)
			colors.append(color)
			colors.append(color)

			indices.append(idx)
			indices.append(idx+1)
			indices.append(idx+2)
			idx += 3

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR]  = colors
	arrays[Mesh.ARRAY_INDEX]  = indices

	var new_mesh = ArrayMesh.new()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = new_mesh

	queue_redraw()

func _draw() -> void:
	if mesh:
		draw_mesh(mesh, null)

func _get_color(x: int, y: int) -> Color:
	# Samma slump + posmod för ev. wrap.
	var world_size = Vector2i(tiles_x, tiles_y)
	var key = Vector2i(posmod(x, world_size.x), posmod(y, world_size.y))

	var rand = RandomNumberGenerator.new()
	rand.seed = hash(key)

	var hh = wrapf(base_color.h + rand.randf_range(-h_variance, h_variance), 0.0, 1.0)
	var ss = clamp(base_color.s + rand.randf_range(-s_variance, s_variance), 0.0, 1.0)
	var vv = clamp(base_color.v + rand.randf_range(-v_variance, v_variance), 0.0, 1.0)

	return Color.from_hsv(hh, ss, vv)
