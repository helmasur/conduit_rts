extends CharacterBody2D

var gravity_vector := Vector2.ZERO  # Sparar senaste gravitationsvektorn

func _physics_process(delta):
	gravity_vector = get_gravity()  # Hämta gravitationsfältets riktning
	queue_redraw()  # Ber Godot att rita om noden

	# Om du bara vill läsa av fältet och inte påverkas:
	velocity = Vector2.ZERO
	move_and_slide()

func _draw():
	if gravity_vector.length() > 0:
		var start = Vector2.ZERO
		var end = gravity_vector * 0.5  # Skala upp vektorn för bättre synlighet
		
		# Rita linjen
		draw_line(start, end, Color.RED, 2)

		# Rita pilhuvudet
		var arrow_size = 10
		var perp = gravity_vector.normalized().orthogonal() * (arrow_size / 2)
		draw_line(end, end - gravity_vector.normalized() * arrow_size + perp, Color.RED, 2)
		draw_line(end, end - gravity_vector.normalized() * arrow_size - perp, Color.RED, 2)
