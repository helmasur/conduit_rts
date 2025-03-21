extends Node2D

var selected_unit: Node = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var camera = $Camera2D
		var click_pos = camera.get_global_mouse_position()
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			_handle_left_click(click_pos)

		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			if selected_unit:
				_handle_right_click(click_pos)

func _handle_left_click(world_pos: Vector2) -> void:
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
		if collider is Control:
			return
		if collider is CharacterBody2D:
			if selected_unit:
				selected_unit.set_selected(false)
			collider.set_selected(true)
			selected_unit = collider
	else:
		for unit in get_tree().get_nodes_in_group("selected_units"):
			unit.set_selected(false)
			selected_unit = null
		

func _handle_right_click(world_pos: Vector2) -> void:
	# Be den valda enheten att förflytta sig
	selected_unit.set_destination(world_pos)
