extends Control

# Rutas de los niveles - AJUSTA ESTAS RUTAS A TUS ARCHIVOS
const NIVEL_1 = "res://nivel_1 Nando/escenario/San_Cristobal.tscn"
const NIVEL_2 = "res://nivel_2/escenario/Santa_Cruz.tscn" 
const NIVEL_3 = "res://nivel_lava/nivel_lava.tscn"
const NIVEL_5 = "res://nivel_5/escenario/Isabella.tscn"
const MENU_PRINCIPAL = "res://Menus/MenuPrincipal.tscn"  # Ajusta la ruta
const CREDITOS = "res://UI/CreditScreen.tscn"  # ← NUEVA RUTA DE CRÉDITOS

# Sistema de guardado simple
const SAVE_FILE = "user://save_game.dat"

func _ready():
	# Conectar las señales de los botones
	$VBoxContainer/Button.pressed.connect(_on_nueva_partida_pressed)
	$VBoxContainer/Button2.pressed.connect(_on_continuar_partida_pressed) 
	$VBoxContainer/Button3.pressed.connect(_on_creditos_pressed)  # ← NUEVO BOTÓN
	$VBoxContainer/Button4.pressed.connect(_on_menu_principal_pressed)
	$VBoxContainer/Button5.pressed.connect(_on_salir_pressed)  # ← BOTÓN MOVIDO
	
	# Verificar si hay partida guardada para habilitar/deshabilitar "Continuar"
	_verificar_partida_guardada()

func _verificar_partida_guardada():
	if not FileAccess.file_exists(SAVE_FILE):
		$VBoxContainer/Button2.disabled = true
		$VBoxContainer/Button2.text = "CONTINUAR PARTIDA (No disponible)"
	else:
		$VBoxContainer/Button2.disabled = false
		$VBoxContainer/Button2.text = "CONTINUAR PARTIDA"

# NUEVA PARTIDA - Empezar desde el nivel 1
func _on_nueva_partida_pressed():
	print("🎮 Iniciando nueva partida...")
	
	# Borrar partida anterior si existe
	if FileAccess.file_exists(SAVE_FILE):
		DirAccess.remove_absolute(SAVE_FILE)
	
	# Guardar progreso inicial
	_guardar_progreso(1)
	
	# Ir al primer nivel
	get_tree().change_scene_to_file(NIVEL_1)

# CONTINUAR PARTIDA - Cargar el último nivel jugado
func _on_continuar_partida_pressed():
	print("📂 Continuando partida...")
	
	var ultimo_nivel = _cargar_progreso()
	
	match ultimo_nivel:
		1:
			get_tree().change_scene_to_file(NIVEL_1)
		2:
			get_tree().change_scene_to_file(NIVEL_2)
		3:
			get_tree().change_scene_to_file(NIVEL_3)
		4:
			get_tree().change_scene_to_file(NIVEL_5)
		_:
			print("⚠️ Error: Nivel no reconocido, iniciando desde nivel 1")
			get_tree().change_scene_to_file(NIVEL_1)

# ===== NUEVA FUNCIÓN: CRÉDITOS =====
func _on_creditos_pressed():
	print("🎬 Mostrando créditos...")
	get_tree().change_scene_to_file(CREDITOS)

# MENU PRINCIPAL - Volver al menú principal
func _on_menu_principal_pressed():
	print("🏠 Volviendo al menú principal...")
	get_tree().change_scene_to_file(MENU_PRINCIPAL)

# SALIR - Cerrar el juego
func _on_salir_pressed():
	print("👋 Saliendo del juego...")
	get_tree().quit()

# SISTEMA DE GUARDADO SIMPLE
func _guardar_progreso(nivel: int):
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		var save_data = {
			"ultimo_nivel": nivel,
			"fecha": Time.get_datetime_string_from_system()
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("💾 Progreso guardado: Nivel ", nivel)
	else:
		print("❌ Error al guardar progreso")

func _cargar_progreso() -> int:
	if not FileAccess.file_exists(SAVE_FILE):
		return 1  # Si no hay archivo, empezar desde nivel 1
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			print("📂 Progreso cargado: Nivel ", save_data.get("ultimo_nivel", 1))
			return save_data.get("ultimo_nivel", 1)
		else:
			print("❌ Error al parsear datos guardados")
			return 1
	else:
		print("❌ Error al leer archivo de guardado")
		return 1

# FUNCIÓN PARA LLAMAR DESDE OTROS SCRIPTS
# Usar cuando el jugador complete un nivel
static func guardar_nivel_completado(nivel: int):
	var save_file = "user://save_game.dat"
	var file = FileAccess.open(save_file, FileAccess.WRITE)
	if file:
		var save_data = {
			"ultimo_nivel": nivel + 1,  # Siguiente nivel
			"fecha": Time.get_datetime_string_from_system()
		}
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("💾 Nivel completado guardado: Siguiente nivel ", nivel + 1)
