# Script universal para niveles del juego
# Funciona para cualquier nivel (San Cristóbal, Santa Cruz, Isabella, etc.)
extends Node2D

# -----------------
#  1. PRECARGAS
# -----------------
const PauseMenu = preload("res://UI/PauseMenu.tscn")
const GameOverScreen = preload("res://UI/game_over.tscn")

# -----------------
#  2. VARIABLES
# -----------------
var pause_menu_instance = null

# -----------------------------------------------
#  3. LÓGICA DE GAME OVER (MEJORADA)
# -----------------------------------------------
func _on_jugador_player_died():
	print("Jugador murió - Iniciando Game Over")
	
	# Verificamos si existe el CanvasLayer, si no lo creamos
	var canvas_layer = null
	if has_node("CanvasLayer"):
		canvas_layer = $CanvasLayer
		print("CanvasLayer encontrado")
		# SOLO ocultamos la barra de vida, NO todo el CanvasLayer
		if canvas_layer.has_node("BarraVida"):
			canvas_layer.get_node("BarraVida").hide()
			print("Barra de vida ocultada")
	else:
		print("CanvasLayer no encontrado - creando uno nuevo")
		canvas_layer = CanvasLayer.new()
		add_child(canvas_layer)

	# Creamos la instancia de la pantalla de Game Over
	print("Creando GameOver screen")
	var game_over_instance = GameOverScreen.instantiate()
	game_over_instance.level_path_to_reload = get_tree().current_scene.scene_file_path
	
	# La añadimos al CanvasLayer
	canvas_layer.add_child(game_over_instance)
	print("GameOver añadido al CanvasLayer")

	# Pausamos el juego
	get_tree().paused = true
	print("Juego pausado")

# ----------------------------------------------------
#  4. LÓGICA DE PAUSA
# ----------------------------------------------------
func _unhandled_input(event: InputEvent):
	# Verificamos si la acción presionada es la que creamos en el Mapa de Entrada
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_the_game()
		else:
			pause_the_game()

# Función que se encarga de pausar el juego y mostrar el menú
func pause_the_game():
	print("Pausando el juego")
	get_tree().paused = true
	
	# Creamos una instancia de nuestro menú de pausa
	pause_menu_instance = PauseMenu.instantiate()
	
	# Conectamos la señal "resume_game" del menú de pausa a nuestra función local
	pause_menu_instance.resume_game.connect(resume_the_game)
	
	# Usar el CanvasLayer existente o crear uno
	var canvas_layer = null
	if has_node("CanvasLayer"):
		canvas_layer = $CanvasLayer
	else:
		print("CanvasLayer no encontrado para pausa - creando uno nuevo")
		canvas_layer = CanvasLayer.new()
		add_child(canvas_layer)
	
	# Añadimos el menú de pausa al CanvasLayer
	canvas_layer.add_child(pause_menu_instance)
	print("Menú de pausa mostrado")

# Función que se encarga de reanudar el juego
func resume_the_game():
	print("Reanudando el juego")
	# Quitamos la pausa del árbol de escenas
	get_tree().paused = false
	
	# Si existe una instancia válida del menú de pausa, la eliminamos
	if is_instance_valid(pause_menu_instance):
		pause_menu_instance.queue_free()
		pause_menu_instance = null
