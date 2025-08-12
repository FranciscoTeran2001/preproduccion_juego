# Script para un nivel del juego (ej: san_cristobal.gd, nivel_lava.gd, etc.)
extends Node2D

# -----------------
#  1. PRECARGAS
# -----------------
# Precargamos las escenas de UI que vamos a necesitar en este nivel.
# Asegúrate de que las rutas sean exactas.
const PauseMenu = preload("res://UI/PauseMenu.tscn")
const GameOverScreen = preload("res://UI/game_over.tscn")

# -----------------
#  2. VARIABLES
# -----------------
# Guardaremos la instancia del menú de pausa aquí para poder borrarla después.
var pause_menu_instance = null


# -----------------------------------------------
#  3. LÓGICA DE GAME OVER (Ya la tenías)
# -----------------------------------------------
# Esta función se activa cuando el personaje emite la señal "player_died".
func _on_jugador_player_died():
	# Ocultamos la interfaz del nivel (la barra de vida, etc.).
	if has_node("CanvasLayer"):
		$CanvasLayer.hide()

	# Creamos la instancia de la pantalla de Game Over.
	var game_over_instance = GameOverScreen.instantiate()
	game_over_instance.level_path_to_reload = get_tree().current_scene.scene_file_path
	
	# La añadimos al CanvasLayer para que se muestre correctamente.
	$CanvasLayer.add_child(game_over_instance)

	# Pausamos el juego.
	get_tree().paused = true


# ----------------------------------------------------
#  4. LÓGICA DE PAUSA (La parte nueva)
# ----------------------------------------------------
# Godot llama a esta función cada vez que se presiona una tecla o se hace un clic.
# Es el lugar ideal para escuchar por la acción de "pausa".
func _unhandled_input(event: InputEvent):
	# Verificamos si la acción presionada es la que creamos en el Mapa de Entrada.
	if event.is_action_pressed("pause"):
		# Si el juego ya está en pausa, lo reanudamos.
		if get_tree().paused:
			resume_the_game()
		# Si no está en pausa, lo pausamos.
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
