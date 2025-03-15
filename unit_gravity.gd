extends Area2D

@export var gravity_strength: float = 200.0  # Justerbar gravitationskraft
@export var gravity_radius: float = 100.0  # Hur långt fältet sträcker sig

func _ready():
	gravity_point = true  # Fältet är en punktkälla
	gravity_space_override = Area2D.SPACE_OVERRIDE_COMBINE  # Summan av alla fält
	gravity_direction = Vector2.ZERO  # Fält pekar alltid mot mittpunkten
	gravity_point_unit_distance = gravity_radius
	gravity = gravity_strength
