extends Control
class_name TriangleControl

signal attribute_changed(h: float, s: float, p: float)

@export var color_a: Color = Color.RED
@export var color_b: Color = Color.GREEN
@export var color_c: Color = Color.BLUE

@export var circle_radius: float = 10.0

# Antalet steg i mosaiken för triangel-fyllningen.
# Ju högre värde, desto finare övertoning, men desto fler draw_polygon-anrop.
@export var SUBDIVISIONS: int = 30

# Interna variabler
var circle_pos: Vector2 = Vector2.ZERO
var dragging: bool = false
var highlight: bool = false  # True om muspekaren är ovanför cirkeln
var current_h: float = 0.33
var current_s: float = 0.33
var current_p: float = 0.34

func _ready() -> void:
	# Börja med att placera cirkeln i mitten av triangeln
	var rect_size = get_rect().size
	circle_pos = Vector2(rect_size.x * 0.5, rect_size.y * 0.5)
	set_mouse_filter(Control.MOUSE_FILTER_PASS)
	# Se till att vi får input-event i _gui_input
	set_process_input(true)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Kolla om vi drar
		if dragging and event.button_mask & MOUSE_BUTTON_MASK_LEFT != 0:
			_move_circle(event.position)
		else:
			# Kolla om cirkeln är highlightad
			highlight = (event.position.distance_to(circle_pos) <= circle_radius)
		queue_redraw()

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Börja drag om vi klickar någonstans i triangeln
				if _point_in_triangle(event.position):
					dragging = true
					_move_circle(event.position)
				# Kolla highlight
				highlight = (event.position.distance_to(circle_pos) <= circle_radius)
			else:
				# Släpp
				dragging = false
			queue_redraw()

func _move_circle(mouse_pos: Vector2) -> void:
	# Placera cirkeln i (mouse_pos) men clamp:a till triangeln
	var clamped = _closest_point_in_triangle(mouse_pos)
	circle_pos = clamped

	# Uppdatera barycentrisk fördelning
	var bary = _point_to_barycentric(clamped)
	current_h = bary.x
	current_s = bary.y
	current_p = bary.z

	emit_signal("attribute_changed", current_h, current_s, current_p)

	queue_redraw()

func _point_in_triangle(pt: Vector2) -> bool:
	# En snabb check: Om barycentriska koordinater är alla >= 0, är punkten i triangeln
	var bary = _point_to_barycentric(pt)
	return bary.x >= 0 and bary.y >= 0 and bary.z >= 0

func _closest_point_in_triangle(pt: Vector2) -> Vector2:
	# Gör en enkel “barycentrisk clamp”.
	var bary = _point_to_barycentric(pt)
	# clamp barycentriska koordinater så att 0 <= x,y,z <= 1, sum = 1
	if bary.x < 0: bary.x = 0
	if bary.y < 0: bary.y = 0
	if bary.z < 0: bary.z = 0
	var sum = bary.x + bary.y + bary.z
	if sum > 0:
		bary.x /= sum
		bary.y /= sum
		bary.z /= sum
	else:
		# Fallback: sätt alla till 1/3 var
		bary.x = 0.33
		bary.y = 0.33
		bary.z = 0.34

	return _bary_to_point(bary.x, bary.y, bary.z)

func _point_to_barycentric(pt: Vector2) -> Vector3:
	# Här gör vi barycentrisk beräkning i en triangel med hörn:
	#   A = (0, 0)
	#   B = (size.x, 0)
	#   C = (size.x/2, size.y)
	# Returnerar (x, y, z) => x + y + z = 1
	var rect_size = get_rect().size
	var A = Vector2(0, 0)
	var B = Vector2(rect_size.x, 0)
	var C = Vector2(rect_size.x * 0.5, rect_size.y)

	var v0 = B - A
	var v1 = C - A
	var v2 = pt - A

	var d00 = v0.dot(v0)
	var d01 = v0.dot(v1)
	var d11 = v1.dot(v1)
	var d20 = v2.dot(v0)
	var d21 = v2.dot(v1)
	var denom = (d00 * d11 - d01 * d01)
	if denom == 0:
		# Om triangeln har noll area (size = 0?), fallback
		return Vector3(0, 0, 0)

	var v = (d11 * d20 - d01 * d21) / denom
	var w = (d00 * d21 - d01 * d20) / denom
	var u = 1.0 - v - w
	# (u, v, w) motsvarar andel av A, B, C
	# Returnerar i ordning (Health, Speed, Power) i exempelsyfte
	return Vector3(u, v, w)

func _bary_to_point(u: float, v: float, w: float) -> Vector2:
	var rect_size = get_rect().size
	var A = Vector2(0, 0)
	var B = Vector2(rect_size.x, 0)
	var C = Vector2(rect_size.x * 0.5, rect_size.y)
	return A * u + B * v + C * w

func _draw_triangle_gradient() -> void:
	var rect_size = get_rect().size
	var A = Vector2(0, 0)
	var B = Vector2(rect_size.x, 0)
	var C = Vector2(rect_size.x * 0.5, rect_size.y)

	draw_polygon(
		PackedVector2Array([A, B, C]),
		PackedColorArray([color_a, color_b, color_c])
	)


func _mix_three(colA: Color, colB: Color, colC: Color, bary: Vector3) -> Color:
	var sum = bary.x + bary.y + bary.z
	if sum == 0:
		return colA
	# Normera
	var u = bary.x / sum
	var v = bary.y / sum
	var w = bary.z / sum
	return colA * u + colB * v + colC * w

func _draw_circle() -> void:
	# Ritar en fyllning och ev. en kant
	if highlight:
		draw_circle(circle_pos, circle_radius, Color(1,1,1,0.4))
	draw_circle(circle_pos, circle_radius, Color.BLACK, false, 2.0)

func _draw() -> void:
	_draw_triangle_gradient()
	_draw_circle()
