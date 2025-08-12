extends Area2D

@export var destino_nivel: String = "res://nivel_2/escenario/Santa_Cruz.tscn"
@export var mensaje_transicion: String = "¡Avanzando al siguiente nivel!"
@export var delay_cambio: float = 0.1  # Tiempo de espera antes del cambio

var ya_cambio = false  # Evitar múltiples cambios

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("jugador") and not ya_cambio:
		ya_cambio = true
		print("🎯 Jugador entró al portal!")
		cambiar_nivel_automatico()

func cambiar_nivel_automatico():
	# Mostrar mensaje opcional
	mostrar_mensaje_ui(mensaje_transicion)
	
	# Esperar un poco (opcional)
	await get_tree().create_timer(delay_cambio).timeout
	
	# Cambiar de nivel
	print("🚪 Cambiando de nivel automáticamente...")
	get_tree().change_scene_to_file(destino_nivel)

func mostrar_mensaje_ui(texto: String):
	# Crear o mostrar UI de mensaje
	var label = get_tree().get_first_node_in_group("ui_mensaje")
	if label:
		label.text = texto
		label.visible = true
	else:
		# Si no hay label, solo imprimir en consola
		print("💬 ", texto)
