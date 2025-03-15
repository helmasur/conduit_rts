extends Area2D

#@export var gravity_strength: float = 100.0  # Justerbar gravitationskraft
#@export var gravity_radius: float = 100.0  # Hur långt fältet sträcker sig

func _ready():
	pass
	#gravity_point = true  # Fältet är en punktkälla
	#gravity_direction = Vector2.ZERO  # Fält pekar alltid mot mittpunkten
	#gravity_point_unit_distance = gravity_radius
	#gravity = gravity_strength

func _process(_delta: float) -> void:
	position = get_parent().get_child(0).position
