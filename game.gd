## game.gd
extends Node2D

var world_size: Vector2
var selected_unit: Unit = null
var tricon_h: float = .33
var player_scene: PackedScene = preload("res://player.tscn")
var player: Player
#var units = [Unit]

var drag_start_position: Vector2
var is_dragging: bool = false
var drag_threshold: float = 10.0  # Minimalt avstånd i pixlar för att betrakta som drag

func _init() -> void:
	world_size = Vector2(2048, 2048)

func _ready():
	for offs in Utils.get_toroid_copies(world_size):
		var copy = $Background.duplicate()
		copy.position = $Background.position+offs
		add_child(copy)
		pass
	#_on_game_started()
		##get_tree().connect("peer_connected", Callable(self, "_on_network_peer_connected"))
		#var mp = get_tree().get_multiplayer()
		#mp.peer_connected.connect(_on_network_peer_connected)

#func _on_network_peer_connected(peer_id: int) -> void:
	#print("Ny klient ansluten med peer_id:", peer_id)
	#_add_player(peer_id)

func _on_server_start():
	if multiplayer.is_server():
		print("Is server")
		multiplayer.peer_connected.connect(_add_player)
		_add_player(multiplayer.get_unique_id())
	

#func _on_game_started():
	#await get_tree().create_timer(.5).timeout
	#if multiplayer.is_server():
		#for id in multiplayer.get_peers():
			#_add_player(id)
		## Lägg även till dig själv
		#_add_player(multiplayer.get_unique_id())

func _add_player(peer_id: int):
	print("Game: add player id, ", peer_id)
	var new_player = player_scene.instantiate()
	new_player.name = str(peer_id)
	new_player.set_multiplayer_authority(peer_id) # Måste göras innan add_child()
	add_child(new_player)
	
#func _add_unit(unit: Unit):
	#units.append(unit)
	#
#func _remove_unit(unit: Unit):
	#units.erase(unit)
	
func _process(_delta: float) -> void:
	$SpawnCursor.global_position = $Camera2D.get_global_mouse_position()
	if is_dragging:
		var camera = $Camera2D
		update_selection_rect(camera.get_global_mouse_position())

func _unhandled_input(event: InputEvent) -> void:
	var camera = $Camera2D
	var mouse_pos = camera.get_global_mouse_position()
	
	# Kontrollera om någon UI-komponent ligger under musen (och om den i så fall är en TriangleControl)
	var ui_under_mouse = get_viewport().gui_get_hovered_control()
	if ui_under_mouse and ui_under_mouse is TriangleControl:
		return

	# Hantera vänster musknapp
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Vid knappnedtryckning: spara startposition och starta dragläge
			drag_start_position = mouse_pos
			is_dragging = true
			# Vi visar inte rektangeln förrän musen rört sig över drag_threshold
		else:
			# Vid knappsläpp: avgör om det är ett drag eller ett vanligt klick
			if is_dragging and drag_start_position.distance_to(mouse_pos) >= drag_threshold:
				perform_drag_selection(drag_start_position, mouse_pos)
			else:
				_handle_left_click(Utils.wrap_position(mouse_pos), Utils.get_unit_at_wrapped_position(mouse_pos, world_size))
			is_dragging = false
			$SelectionRect.visible = false
			$SelectionRect.points = []  # Rensa tidigare rektangelpunkter

	# Uppdatera rektangeln medan musen rör sig under dragläget
	elif event is InputEventMouseMotion and is_dragging:
		if drag_start_position.distance_to(mouse_pos) >= drag_threshold:
			$SelectionRect.visible = true
			update_selection_rect(mouse_pos)

	elif event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and event.pressed:
		var clicked_unit = Utils.get_unit_at_wrapped_position(mouse_pos, world_size)
		var wrapped_pos = Utils.wrap_position(mouse_pos)
		_handle_right_click(wrapped_pos, clicked_unit)

func _handle_left_click(_world_pos: Vector2, clicked_unit: Unit) -> void:
	if clicked_unit:
		if clicked_unit.is_in_group("player_units"):
			if selected_unit:
				selected_unit.set_selected(false)
			clicked_unit.set_selected(true)
			selected_unit = clicked_unit
			clicked_unit.add_to_group("selected_units")
			$SpawnCursor.visible = false
			%TriCon.set_point(selected_unit.defense_prop, selected_unit.power_prop, selected_unit.speed_prop)
			#%TriCon.set_handle(selected_unit.target_defense_prop, selected_unit.target_power_prop, selected_unit.target_speed_prop)
	else:
		$SpawnCursor.visible = true
		# Om inget enhet klickades: rensa markering
		for unit in get_tree().get_nodes_in_group("selected_units"):
			unit.set_selected(false)
		selected_unit = null

func _handle_right_click(world_pos: Vector2, clicked_unit: Unit) -> void:
	#print(selected_unit)
	# Be den valda enheten att förflytta sig
	var selected_units = get_tree().get_nodes_in_group("selected_units")
	if len(selected_units) > 0:
		if clicked_unit:
			for unit: Unit in selected_units:
				unit.request_attack(clicked_unit)
		else:
			for unit: Unit in selected_units:
				unit.set_destination(world_pos)
	else:
		if not clicked_unit:
			var e = %"EnergySlider".value
			player.spawn_unit(e, %TriCon.current_h, %TriCon.current_p, %TriCon.current_s, world_pos).mode = UnitShared.ActionMode.UNDER_CONSTRUCTION
			
func perform_drag_selection(start_pos: Vector2, end_pos: Vector2) -> void:
	#var world_size = Vector2(2048, 2048)
	var raw_diff = end_pos - start_pos
	var diff = raw_diff
	# Applicera wrapping endast om differensen är mindre eller lika med halva världen
	if abs(raw_diff.x) <= world_size.x / 2:
		diff.x = Utils.toroid_direction(start_pos, end_pos, world_size).x
	if abs(raw_diff.y) <= world_size.y / 2:
		diff.y = Utils.toroid_direction(start_pos, end_pos, world_size).y
	var computed_end = start_pos + diff
	
	var top_left = Vector2(min(start_pos.x, computed_end.x), min(start_pos.y, computed_end.y))
	var bottom_right = Vector2(max(start_pos.x, computed_end.x), max(start_pos.y, computed_end.y))
	var selection_rect = Rect2(top_left, bottom_right - top_left)
	
	for unit in get_tree().get_nodes_in_group("player_units"):
		var unit_pos = unit.global_position
		var selected = false
		for offset in Utils.get_toroid_offsets(world_size):
			if selection_rect.has_point(unit_pos + offset):
				selected = true
				break
		unit.set_selected(selected)
		if selected:
			unit.add_to_group("selected_units")
		else:
			unit.remove_from_group("selected_units")

func update_selection_rect(current_position: Vector2) -> void:
	#var world_size = Vector2(2048, 2048)
	var raw_diff = current_position - drag_start_position
	var diff = raw_diff
	if abs(raw_diff.x) <= world_size.x / 2:
		diff.x = Utils.toroid_direction(drag_start_position, current_position, world_size).x
	if abs(raw_diff.y) <= world_size.y / 2:
		diff.y = Utils.toroid_direction(drag_start_position, current_position, world_size).y
	var computed_end = drag_start_position + diff
	
	var top_left = Vector2(min(drag_start_position.x, computed_end.x), min(drag_start_position.y, computed_end.y))
	var bottom_right = Vector2(max(drag_start_position.x, computed_end.x), max(drag_start_position.y, computed_end.y))
	var top_right = Vector2(bottom_right.x, top_left.y)
	var bottom_left = Vector2(top_left.x, bottom_right.y)
	$SelectionRect.points = [top_left, top_right, bottom_right, bottom_left]
