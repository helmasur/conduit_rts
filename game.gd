## game.gd
extends Node2D

var selected_unit: Node = null
var tricon_h: float = .33
@export var player_scene: PackedScene = preload("res://player.tscn")
var player: Player
var units = [Unit]

func _ready():
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
	new_player.id = peer_id
	new_player.set_multiplayer_authority(peer_id) # Måste göras innan add_child()
	add_child(new_player)
	
func _add_unit(unit: Unit):
	units.append(unit)
	
func _remove_unit(unit: Unit):
	units.erase(unit)

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseButton and event.pressed:
		var camera = $Camera2D
		var click_pos = camera.get_global_mouse_position()
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			click_pos = Utils.wrap_position(click_pos)
			_handle_left_click(click_pos)

		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			_handle_right_click(click_pos)

func _handle_left_click(world_pos: Vector2) -> void:
	var ui_under_mouse := get_viewport().gui_get_hovered_control()
	if ui_under_mouse and ui_under_mouse is TriangleControl:
		return  # Ignorera klick på UI-komponenten
	#if ui_under_mouse and ui_under_mouse.is_in_group("ui"): # Sparas, kan vara bra senare.
	
	# Skapa query-objekt för punktintersektion
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	
	# Kör intersect_point
	var results = space_state.intersect_point(query)
	if results.size() > 0:
		# Ta den första träffen
		var hit = results[0]
		var collider = hit.collider
		# Om den collider vi träffade är en enhet, markera den
		if collider is CharacterBody2D:
			if selected_unit:
				selected_unit.set_selected(false)
			collider.set_selected(true)
			selected_unit = collider
			%TriCon.set_point(selected_unit.health_prop, selected_unit.power_prop, selected_unit.speed_prop)
			#%TriCon.set_handle(selected_unit.target_health_prop, selected_unit.target_power_prop, selected_unit.target_speed_prop)
	else:
		for unit in get_tree().get_nodes_in_group("selected_units"):
			unit.set_selected(false)
			selected_unit = null
		

func _handle_right_click(world_pos: Vector2) -> void:
	#print(selected_unit)
	# Be den valda enheten att förflytta sig
	if selected_unit:
		selected_unit.set_destination(world_pos)
	else:
		player.spawn_unit(%"Build energy".value, %TriCon.current_h, %TriCon.current_p, %TriCon.current_s, world_pos).energy = 1000
