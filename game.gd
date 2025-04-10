## game.gd
extends Node2D

var world_size: Vector2
var selected_unit: Unit = null
var tricon_h: float = .33
var player_scene: PackedScene = preload("res://player.tscn")
var player: Player
var units = [Unit]

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
		var mouse_pos = camera.get_global_mouse_position()

		# Kontrollera UI först
		var ui_under_mouse := get_viewport().gui_get_hovered_control()
		if ui_under_mouse and ui_under_mouse is TriangleControl:
			return

		var clicked_unit = Utils.get_unit_at_wrapped_position(mouse_pos, world_size)

		var wrapped_pos = Utils.wrap_position(mouse_pos)

		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			_handle_left_click(wrapped_pos, clicked_unit)
		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			_handle_right_click(wrapped_pos, clicked_unit)

			
func _handle_left_click(_world_pos: Vector2, clicked_unit: Unit) -> void:
	if clicked_unit:
		if selected_unit:
			selected_unit.set_selected(false)
		clicked_unit.set_selected(true)
		selected_unit = clicked_unit
		%TriCon.set_point(selected_unit.defense_prop, selected_unit.power_prop, selected_unit.speed_prop)
	#%TriCon.set_handle(selected_unit.target_defense_prop, selected_unit.target_power_prop, selected_unit.target_speed_prop)
	else:
		for unit in get_tree().get_nodes_in_group("selected_units"):
			unit.set_selected(false)
			selected_unit = null


func _handle_right_click(world_pos: Vector2, clicked_unit: Unit) -> void:
	#print(selected_unit)
	# Be den valda enheten att förflytta sig
	if selected_unit:
		if clicked_unit:
			selected_unit.request_attack(clicked_unit)
		else:
			selected_unit.set_destination(world_pos)
			
	else:
		if not clicked_unit:
			var e = %"Build energy".value
			if player.player_energy >= e:
				player.player_energy -= e
				player.spawn_unit(e, %TriCon.current_h, %TriCon.current_p, %TriCon.current_s, world_pos).mode = UnitShared.ActionMode.UNDER_CONSTRUCTION
			
	
	
