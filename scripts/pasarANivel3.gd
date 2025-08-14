extends Area2D

@export var destino_nivel: String = "res://nivel_lava/nivel_lava.tscn"
@export var nivel_completado: int = 2  # Nivel que se acaba de completar
@export var mensaje_transicion: String = "¡Avanzando al Nivel 3!"
@export var delay_cambio: float = 0.1
var ya_cambio = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("jugador") and not ya_cambio:
		ya_cambio = true
		print("🎯 Jugador entró al portal!")
		cambiar_nivel_automatico()

func cambiar_nivel_automatico():
	# GUARDAR PROGRESO ANTES DE CAMBIAR
	guardar_progreso_nivel()
	
	# Mostrar mensaje opcional
	mostrar_mensaje_ui(mensaje_transicion)
	
	# Esperar un poco (opcional)
	await get_tree().create_timer(delay_cambio).timeout
	
	# Cambiar de nivel
	print("🚪 Cambiando de nivel automáticamente...")
	get_tree().change_scene_to_file(destino_nivel)

func guardar_progreso_nivel():
	# Guardar el progreso usando el sistema de guardado
	var save_file = "user://save_game.dat"
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file:
		var save_data = {
			"ultimo_nivel": nivel_completado + 1,  # Siguiente nivel disponible
			"fecha": Time.get_datetime_string_from_system()
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("💾 Nivel ", nivel_completado, " completado! Siguiente nivel desbloqueado: ", nivel_completado + 1)
	else:
		print("❌ Error al guardar progreso")

func mostrar_mensaje_ui(texto: String):
	var label = get_tree().get_first_node_in_group("ui_mensaje")
	if label:
		label.text = texto
		label.visible = true
	else:
		print("💬 ", texto)
