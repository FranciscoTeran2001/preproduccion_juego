extends Area2D

func _on_body_entered(body):
	if body.has_method("subir_vida"):
		body.subir_vida(25)
		queue_free()  # La flor desaparece después de dar vida
