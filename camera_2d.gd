extends Camera2D

@export var base_move_speed: float = 500.0  # Grundhastighet i pixlar per sekund
@export var base_edge_scroll_speed: float = 0.0  # Grundhastighet för muskantrörelse
@export var edge_margin: int = 20  # Hur nära kanten musen måste vara

var zoom_levels: Array = [2.0, 1.0, 0.5, 0.25, 0.125, 0.0625]  # Zoomsteg
var zoom_index: int = 1  # Startar på 1x zoom

var move_speed: float
var edge_scroll_speed: float
var screen_size: Vector2

func _ready():
	screen_size = get_viewport_rect().size
	update_zoom()  # Sätt startzoom och hastighet

func _process(delta):
	screen_size = get_viewport_rect().size

	var move_dir := Vector2.ZERO
	var edge_dir := Vector2.ZERO

	# Tangentbordsstyrning
	if Input.is_action_pressed("move_up"):
		move_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		move_dir.y += 1
	if Input.is_action_pressed("move_left"):
		move_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		move_dir.x += 1

	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()

	# Muskantrörelse
	var mouse_pos = get_viewport().get_mouse_position()

	if mouse_pos.x < edge_margin:
		edge_dir.x -= 1
	elif mouse_pos.x > screen_size.x - edge_margin:
		edge_dir.x += 1

	if mouse_pos.y < edge_margin:
		edge_dir.y -= 1
	elif mouse_pos.y > screen_size.y - edge_margin:
		edge_dir.y += 1

	if edge_dir != Vector2.ZERO:
		edge_dir = edge_dir.normalized()

	# Lägg ihop båda rörelserna, med olika hastighet
	position += (move_dir * move_speed + edge_dir * edge_scroll_speed) * delta
	global_position = Utils.wrap_position(global_position)



func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and zoom_index > 0:
			zoom_index -= 1  # Zooma in
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and zoom_index < zoom_levels.size() - 1:
			zoom_index += 1  # Zooma ut

		update_zoom()  # Uppdatera zoom och hastighet

func update_zoom():
	var zoom_factor = zoom_levels[zoom_index]
	zoom = Vector2(zoom_factor, zoom_factor)

	# Justera hastighet baserat på zoomnivå
	move_speed = base_move_speed / zoom_factor
	edge_scroll_speed = base_edge_scroll_speed / zoom_factor
