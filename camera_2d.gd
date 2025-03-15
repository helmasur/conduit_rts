extends Camera2D

@export var move_speed: float = 500.0  # Hastighet i pixlar per sekund
@export var edge_scroll_speed: float = 400.0  # Hastighet när musen vid kanten
@export var edge_margin: int = 20  # Hur nära kanten musen måste vara

var screen_size: Vector2  # Storleken på spelets fönster

func _ready():
	screen_size = get_viewport_rect().size

func _process(delta):
	var direction := Vector2.ZERO

	# Tangentbordsstyrning
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x += 1

	# Normalisera så diagonala rörelser inte blir snabbare
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Muskantrörelse
	var mouse_pos = get_viewport().get_mouse_position()

	if mouse_pos.x < edge_margin:
		direction.x -= 1
	elif mouse_pos.x > screen_size.x - edge_margin:
		direction.x += 1

	if mouse_pos.y < edge_margin:
		direction.y -= 1
	elif mouse_pos.y > screen_size.y - edge_margin:
		direction.y += 1

	# Flytta kameran
	position += direction * move_speed * delta
