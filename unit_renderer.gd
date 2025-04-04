extends Node2D

@export var world_size: Vector2 = Vector2(1024, 1024)
@export var mesh_size: float = 30.0

@onready var mm_instance := $MultiMeshInstance2D

# Alla enheter lagras här
var units_data: Array = []

# Förbered 9 offsets för torus:
# (0,0) och +/- world_size.x/y i en 3x3-grid
var _toroid_offsets = [
	Vector2(0, 0),
	Vector2(world_size.x, 0),
	Vector2(-world_size.x, 0),
	Vector2(0, world_size.y),
	Vector2(0, -world_size.y),
	Vector2(world_size.x, world_size.y),
	Vector2(world_size.x, -world_size.y),
	Vector2(-world_size.x, world_size.y),
	Vector2(-world_size.x, -world_size.y),
]

func _ready():
	# Skapa MultiMesh och anslut den till MultiMeshInstance2D
	var mm = MultiMesh.new()

	# Skapa en enkel QuadMesh (fyrkant) med storlek mesh_size×mesh_size
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(mesh_size, mesh_size)

	mm.mesh = quad_mesh
	mm.use_colors = true

	# Tilldelar MultiMesh till vår MultiMeshInstance2D
	mm_instance.multimesh = mm

func register_unit(unit: Unit):
	var mm = mm_instance.multimesh
	var old_count = mm.instance_count
	mm.instance_count = old_count + 9
	
	# Skapa 9 nya instanser och spara indexen i Unit-objektet
	var index_array = []
	for i in range(9):
		var instance_index = old_count + i
		index_array.append(instance_index)
	unit.multimesh_instance_indices = index_array

	# Lägg till enheten i vår interna lista
	units_data.append(unit)


func _process(_delta: float) -> void:
	# Uppdatera transform + färg på alla enheter
	var mm = mm_instance.multimesh
	for u in units_data:
		if u == null:
			continue
		# Hämta var enhetens 9 instanser bor
		var idx_array = u.multimesh_instance_indices
		if not idx_array:
			continue

		# T.ex. spelarfärg ändras (om du vill stötta dynamisk färg)
		var c = u.player_color

		# Sätt transform för var och en av de nio offsetsen
		for i in range(9):
			var instance_idx = idx_array[i]
			var offset = _toroid_offsets[i]
			var xf = Transform2D()
			xf.origin = u.global_position + offset
			mm.set_instance_transform_2d(instance_idx, xf)
			mm.set_instance_color(instance_idx, c)
