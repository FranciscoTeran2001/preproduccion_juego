extends Area2D

var jugador_en_contacto := false

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	start_danio_continuo()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("jugador"):
		jugador_en_contacto = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("jugador"):
		jugador_en_contacto = false

func start_danio_continuo() -> void:
	await get_tree().process_frame  # Espera 1 frame para asegurar que todo esté listo
	while true:
		if jugador_en_contacto:
			var jugadores = get_overlapping_bodies()
			for body in jugadores:
				if body.is_in_group("jugador"):
					body.bajar_vida(10)  # Daño cada cierto tiempo
		await get_tree().create_timer(0.4).timeout  # Cada 0.4 segundo
