extends CharacterBody2D

var space
@export var speed = 20

func _ready() -> void:
	add_to_group("units")
	var t = Timer.new()
	t.wait_time = 2.0
	t.one_shot = false  # Om du vill att den ska loopa, sätt till false
	add_child(t)  # Lägg till timern i scenen
	t.start()
	t.timeout.connect(_change_direction)  # Korrekt sätt att ansluta signalen
	_change_direction()

func _physics_process(_delta):
	space = calc_free_space_factor(global_position)
	queue_redraw()
	move_and_slide()
	global_position = Utils.wrap_position(global_position)


func _draw():
	draw_circle(Vector2.ZERO, space, Color.RED, false, 2, true)

func _change_direction():
	velocity = Vector2(randi_range(-100, 100), randi_range(-100, 100))
	velocity = velocity.normalized()
	velocity *= speed

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
		if member != self:  # Hoppa över oss själva
			var d = toroid_distance(globpos, member.global_position, world_size)
			fsf += 1.0 / d
	fsf = 1.0 / fsf
	fsf = pow(fsf, 1.5) / 2.0
	return fsf
