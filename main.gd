extends Node2D

var selected_unit: Node = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var camera = $Camera2D
		var click_pos = camera.get_global_mouse_position()
		if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
			# Hämta musposition i "världskoordinater".
			# Om du har en Camera2D med custom transform kan du behöva göra:
			print(click_pos)
			#var click_pos = event.position
			_handle_left_click(click_pos)

		elif event.button_index == MouseButton.MOUSE_BUTTON_RIGHT:
			if selected_unit:
				_handle_right_click(click_pos)

func _handle_left_click(world_pos: Vector2) -> void:
	# 1) Avmarkera eventuell tidigare vald enhet
	if selected_unit:
		selected_unit.set_selected(false)
		selected_unit = null

	# 2) Skapa query-objekt för punktintersektion
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = world_pos
	# Om du vill styra vilka lager du vill träffa:
	#query.collision_layer = 1
	#query.collision_mask = 2147483647  # ex. alla lager
	# query.max_results = 10  # default är 32

	# 3) Kör intersect_point
	var results = space_state.intersect_point(query)
	print(results)

	if results.size() > 0:
		# Ta den första träffen
		var hit = results[0]
		var collider = hit.collider
		# Om den collider vi träffade är en enhet, markera den
		if collider is CharacterBody2D:
			collider.set_selected(true)
			selected_unit = collider

func _handle_right_click(world_pos: Vector2) -> void:
	# Be den valda enheten att förflytta sig
	selected_unit.set_destination(world_pos)
