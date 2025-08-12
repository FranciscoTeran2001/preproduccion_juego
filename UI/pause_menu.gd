extends Control

# Señal que le "gritará" al nivel que el jugador quiere reanudar el juego.
signal resume_game

# Conectaremos el botón "Reanudar" a esta función.
func _on_button_resume_pressed():
	# No des-pausamos aquí. Solo avisamos al nivel que debe hacerlo.
	emit_signal("resume_game")

# Conectaremos el botón "Salir" a esta función.
func _on_button_quit_pressed():
	# Antes de cambiar de escena, siempre es buena idea quitar la pausa.
	print("Botón de salir presionado. El juego se cerraría ahora.")
	get_tree().quit()
