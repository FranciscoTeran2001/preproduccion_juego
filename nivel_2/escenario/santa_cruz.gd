extends Node2D
const GameOverScreen = preload("res://UI/game_over.tscn")
const PauseMenu = preload("res://UI/PauseMenu.tscn")

var pause_menu_instance = null

func _on_jugador_player_died():
	# 1. Creamos una "copia" o "instancia" de nuestra escena de Game Over.
	#    Para que esto funcione, asegúrate de tener la línea 'const GameOverScreen = preload(...)'
	#    al principio de este mismo script.
	var game_over_instance = GameOverScreen.instantiate()
	game_over_instance.level_path_to_reload = get_tree().current_scene.scene_file_path
	
	# === LÍNEA MODIFICADA ===
	# En lugar de add_child(), usamos la ruta a tu CanvasLayer.
	$CanvasLayer.add_child(game_over_instance)

	get_tree().paused = true

func _unhandled_input(event: InputEvent):
	# PRUEBA 1: ¿Está esta función siquiera ejecutándose?
	print("Tecla presionada, _unhandled_input se activó.")

	if event.is_action_pressed("pause"):
		# PRUEBA 2: ¿Está reconociendo la acción "pause"?
		print("¡ACCIÓN 'PAUSE' DETECTADA!")
		
		if get_tree().paused:
			resume_the_game()
		else:
			pause_the_game()


# Función que se encarga de pausar el juego y mostrar el menú.
func pause_the_game():
	# Pausamos el árbol de escenas.
	get_tree().paused = true
	
	# Creamos una instancia de nuestro menú de pausa.
	pause_menu_instance = PauseMenu.instantiate()
	
	# Conectamos la señal "resume_game" del menú de pausa a nuestra función local.
	# Esto es para que cuando el menú de pausa "grite", este script lo escuche.
	pause_menu_instance.resume_game.connect(resume_the_game)
	
	# Añadimos el menú de pausa al CanvasLayer para que se vea.
	$CanvasLayer.add_child(pause_menu_instance)


# Función que se encarga de reanudar el juego.
func resume_the_game():
	# Quitamos la pausa del árbol de escenas.
	get_tree().paused = false
	
	# Si existe una instancia válida del menú de pausa, la eliminamos.
	# Esto es importante para que no se quede en la memoria.
	if is_instance_valid(pause_menu_instance):
		pause_menu_instance.queue_free()
