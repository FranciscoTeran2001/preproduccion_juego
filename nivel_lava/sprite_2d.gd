extends Sprite2D

func _on_body_entered(body):
	if body.has_method("activar_armadura"):
		body.activar_armadura()
		queue_free()
