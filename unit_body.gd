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
	space = Utils.calc_free_space_factor(global_position)
	queue_redraw()
	move_and_slide()
	global_position = Utils.wrap_position(global_position)


func _draw():
	draw_circle(Vector2.ZERO, space, Color.RED, false, 2, true)

func _change_direction():
	velocity = Vector2(randi_range(-100, 100), randi_range(-100, 100))
	velocity = velocity.normalized()
	velocity *= speed
