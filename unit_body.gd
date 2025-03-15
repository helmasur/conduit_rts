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

func _physics_process(delta):
	space = calc_free_space_factor()
	queue_redraw()
	move_and_slide()

func _draw():
	draw_circle(Vector2.ZERO, space, Color.RED, false, 1, true)

func _change_direction():
	velocity = Vector2(randi_range(-100, 100), randi_range(-100, 100))
	velocity = velocity.normalized()
	velocity *= speed

func calc_free_space_factor() -> float:
	var sp = 0.0
	var group_name = "units"  # Byt ut mot gruppens namn om det är något annat
	var my_position = global_position
	
	var members = get_tree().get_nodes_in_group(group_name)
	
	for member in members:
		if member != self:  # Undvik att räkna avståndet till sig själv
			sp += 1.0 / my_position.distance_to(member.global_position)
	sp = 1.0 / sp
	sp = pow(sp, 1.5) / 2.0
	#print(sp)
	return sp
