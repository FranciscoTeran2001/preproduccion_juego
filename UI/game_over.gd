extends Control

# Esta variable la llena el script del nivel cuando morimos.
# Contiene la ruta de la escena a recargar, ej: "res://san_cristobal.tscn"
var level_path_to_reload: String


# Función para el botón de SALIR
func _on_button_salir_pressed():
	print("Botón de salir presionado. El juego se cerraría ahora.")
	get_tree().quit()


func _on_button_repetir_pressed():
	print("Botón de repetir presionado. Intentando recargar:", level_path_to_reload)
	
	get_tree().paused = false
	get_tree().change_scene_to_file(level_path_to_reload)
