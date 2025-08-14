extends Control

# --- CONFIGURACIÓN ---
@export var scroll_speed: float = 80.0

# --- NODOS ---
@onready var text_container = $TextContainer
@onready var back_button = $BackButton

# Variable para detectar el contexto
var came_from_menu: bool = false

func _ready():
	# IMPORTANTE: Para que funcione cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Configurar el botón existente
	setup_existing_button()
	
	# Detectar si venimos del menú o del juego
	detect_context()
	
	# 1. POSICIONAR EL TEXTO INICIALMENTE
	var screen_height = get_viewport_rect().size.y
	text_container.position.y = screen_height
	
	# 2. CALCULAR EL DESTINO FINAL
	var end_position_y = -text_container.size.y
	
	# 3. CALCULAR LA DURACIÓN DE LA ANIMACIÓN
	var total_distance = screen_height + text_container.size.y
	var duration = total_distance / scroll_speed
	
	# 4. MOSTRAR EL BOTÓN DESPUÉS DE UN TIEMPO
	show_back_button_after_delay()
	
	# 5. CREAR Y EJECUTAR LA ANIMACIÓN (TWEEN)
	var tween = create_tween()
	
	# Animamos la propiedad "position:y" del contenedor de texto.
	tween.tween_property(text_container, "position:y", end_position_y, duration)
	
	# 6. ESPERAR A QUE TERMINE Y TOMAR ACCIÓN
	await tween.finished
	finish_credits()

# ===== CONFIGURAR EL BOTÓN EXISTENTE =====
func setup_existing_button():
	if back_button:
		print("✅ Botón BackButton encontrado")
		
		# Conectar la señal
		back_button.pressed.connect(_on_back_button_pressed)
		
		# Configurar el texto inicial
		back_button.text = "VOLVER AL MENÚ"
		
		# Mejorar el estilo
		back_button.add_theme_font_size_override("font_size", 16)
		
		# Ocultar inicialmente
		back_button.visible = false
		
		print("🔘 Botón configurado correctamente")
	else:
		print("❌ Error: No se encontró el botón BackButton")

# Detectar de dónde venimos
func detect_context():
	if get_tree().paused:
		came_from_menu = false
		print("🎮 Créditos mostrados después del boss")
	else:
		came_from_menu = true
		print("📖 Créditos mostrados desde el menú")

# Mostrar el botón después de unos segundos
func show_back_button_after_delay():
	await get_tree().create_timer(3.0).timeout
	if back_button:
		back_button.visible = true
		print("🔘 Botón 'Volver al Menú' ahora visible")
		
		# Animación de aparición del botón
		back_button.modulate.a = 0.0
		var button_tween = create_tween()
		button_tween.tween_property(back_button, "modulate:a", 1.0, 0.5)

# Función para cuando se presiona el botón
func _on_back_button_pressed():
	print("🔘 Botón presionado")
	
	# Comportamiento según el contexto
	if came_from_menu:
		print("→ Volviendo al menú principal...")
		return_to_main_menu()
	else:
		print("→ Finalizando juego...")
		quit_game()

func finish_credits():
	if came_from_menu:
		print("Créditos finalizados desde menú - esperando interacción")
		# El botón ya está visible, solo esperamos
	else:
		print("Créditos finalizados después del boss")
		# Cambiar texto del botón para el contexto del boss
		if back_button:
			back_button.text = "FINALIZAR JUEGO"
			if not back_button.visible:
				back_button.visible = true
				print("🔘 Botón 'Finalizar Juego' mostrado")

# Función para volver al menú principal
func return_to_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/menu_jugar.tscn")

# Esta función se encarga de cerrar el juego.
func quit_game():
	get_tree().quit()

# Permitir saltar créditos con teclas
func _input(event: InputEvent):
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		print("⏩ Tecla presionada para saltar créditos")
		
		# Mostrar botón inmediatamente si no está visible
		if back_button and not back_button.visible:
			back_button.visible = true
			back_button.modulate.a = 1.0  # Aparecer completamente
			print("🔘 Botón mostrado inmediatamente por tecla")
			return
		
		# Si ya está visible, actuar como si se presionó
		_on_back_button_pressed()
