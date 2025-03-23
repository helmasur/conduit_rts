extends Control
class_name TriangleControl

signal attribute_changed(h: float, s: float, p: float)

@export var color_a: Color = Color.RED : set = _set_color_a
@export var color_b: Color = Color.GREEN : set = _set_color_b
@export var color_c: Color = Color.BLUE : set = _set_color_c

@export var circle_radius: float = 10.0

# Interna variabler
var circle_pos: Vector2 = Vector2.ZERO
var point_pos: Vector2 = Vector2.ZERO
var dragging: bool = false
var highlight: bool = false  
var current_h: float = 0.33
var current_s: float = 0.33
var current_p: float = 0.34

# Hörn på triangeln (beräknas i _ready)
var A: Vector2
var B: Vector2
var C: Vector2

func _ready() -> void:
	# Beräkna triangeln en gång
	_update_triangle_vertices()
	# Startposition i mitten
	circle_pos = (A + B + C) / 3.0
	#set_mouse_filter(Control.MOUSE_FILTER_PASS)
	set_process_input(true)

func _update_triangle_vertices() -> void:
	#var rect_size = get_rect().size
	var rect_size = _get_minimum_size()
	A = Vector2(0, 0)
	B = Vector2(rect_size.x, 0)
	C = Vector2(rect_size.x * 0.5, rect_size.y)

func _get_minimum_size() -> Vector2:
	var aspect_ratio = 0.866
	var min_w = custom_minimum_size.x
	var min_h = min_w * aspect_ratio
	if min_h > custom_minimum_size.y:
		min_h = custom_minimum_size.y
		min_w = min_h / aspect_ratio
	return Vector2(min_w, min_h)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if dragging and event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			_move_circle(event.position)
		else:
			highlight = event.position.distance_to(circle_pos) <= circle_radius
		queue_redraw()

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _point_in_triangle(event.position):
				dragging = true
				_move_circle(event.position)
			highlight = event.position.distance_to(circle_pos) <= circle_radius
		else:
			dragging = false
		queue_redraw()

func _move_circle(mouse_pos: Vector2) -> void:
	var clamped = _closest_point_in_triangle(mouse_pos)
	circle_pos = clamped

	var bary = _point_to_barycentric(clamped)
	current_h = bary.x
	current_s = bary.y
	current_p = bary.z

	emit_signal("attribute_changed", current_h, current_s, current_p)
	queue_redraw()

func _point_in_triangle(pt: Vector2) -> bool:
	var bary = _point_to_barycentric(pt)
	return bary.x >= 0 and bary.y >= 0 and bary.z >= 0

func _closest_point_in_triangle(pt: Vector2) -> Vector2:
	var bary = _point_to_barycentric(pt)
	bary = bary.clamp(Vector3.ZERO, Vector3.ONE) 
	var sum = bary.x + bary.y + bary.z
	if sum > 0:
		bary /= sum
	else:
		bary = Vector3(0.33, 0.33, 0.34)
	return _bary_to_point(bary.x, bary.y, bary.z)

func _point_to_barycentric(pt: Vector2) -> Vector3:
	var v0 = B - A
	var v1 = C - A
	var v2 = pt - A

	var d00 = v0.dot(v0)
	var d01 = v0.dot(v1)
	var d11 = v1.dot(v1)
	var d20 = v2.dot(v0)
	var d21 = v2.dot(v1)
	var denom = d00 * d11 - d01 * d01
	if denom == 0:
		return Vector3(0, 0, 0)

	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	return Vector3(u, v, w)

func _bary_to_point(u: float, v: float, w: float) -> Vector2:
	return A * u + B * v + C * w

func _draw_triangle_gradient() -> void:
	draw_polygon(
		PackedVector2Array([A, B, C]),
		PackedColorArray([color_a, color_b, color_c])
	)

func _draw_circle() -> void:
	if highlight:
		draw_circle(circle_pos, circle_radius, Color(1,1,1,0.4))
	draw_circle(circle_pos, circle_radius, Color.BLACK, false, 1.5, true)
	
func _draw_point() -> void:
	draw_circle(point_pos, 1.5, Color.BLACK, true, -1.0, true)

func _draw() -> void:
	_draw_triangle_gradient()
	_draw_point()
	_draw_circle()

# Gör att vi kan ändra färger i Inspector och se ändringen direkt
func _set_color_a(value: Color) -> void:
	color_a = value
	queue_redraw()

func _set_color_b(value: Color) -> void:
	color_b = value
	queue_redraw()

func _set_color_c(value: Color) -> void:
	color_c = value
	queue_redraw()

func set_handle(h: float, p: float, s: float) -> void:
	var total = h + s + p
	if total == 0:
		return  # Undvik division med noll

	# Normalisera så att h + s + p = 1
	var u = h / total
	var v = s / total
	var w = p / total

	# Flytta handtaget till rätt position i triangeln
	circle_pos = _bary_to_point(u, v, w)

	# Uppdatera interna värden
	current_h = u
	current_s = v
	current_p = w

	emit_signal("attribute_changed", current_h, current_p, current_s)
	queue_redraw()

func set_point(h: float, p: float, s: float) -> void:
	var total = h + s + p
	if total == 0:
		return  # Undvik division med noll
	
	# Normalisera så att h + s + p = 1
	var u = h / total
	var v = s / total
	var w = p / total
	
	# Flytta handtaget till rätt position i triangeln
	point_pos = _bary_to_point(u, v, w)
	
	queue_redraw()
