extends Node2D

var selected_unit: Node = null
var tricon_h: float = .33
@export var player_scene: PackedScene = preload("res://player.tscn")

func _ready():
	_on_game_started()

func _on_game_started():
	if MultiplayerManager.is_host():
		for id in multiplayer.get_peers():
			_add_player(id)

		# Lägg även till dig själv
		_add_player(multiplayer.get_unique_id())

func _add_player(peer_id: int):
	var player = player_scene.instantiate()
	player.name = "Player_%s" % peer_id
	add_child(player)
	player.set_multiplayer_authority(peer_id)
	if peer_id == multiplayer.get_unique_id():
		$CanvasLayer/GUI.player = player
		player.spawn_initial_unit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var camera = $Camera2D
		var click_pos = camera.get_global_mouse_position()
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			click_pos = Utils.wrap_position(click_pos)
			_handle_left_click(click_pos)

		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			if selected_unit:
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
			%TriCon.set_handle(selected_unit.target_health_prop, selected_unit.target_power_prop, selected_unit.target_speed_prop)
	else:
		for unit in get_tree().get_nodes_in_group("selected_units"):
			unit.set_selected(false)
			selected_unit = null
		

func _handle_right_click(world_pos: Vector2) -> void:
	# Be den valda enheten att förflytta sig
	selected_unit.set_destination(world_pos)
