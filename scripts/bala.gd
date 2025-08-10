# Script para la bala usando Area2D
extends Area2D

var velocidad := 50.0
var daño := 25
var direccion := 1
var ya_colisiono := false

func _ready() -> void:
	add_to_group("balas")
	print("=== BALA CREADA ===")
	print("Posición inicial: ", global_position)
	print("Velocidad: ", velocidad)
	
	# Verificar estructura de nodos
	if has_node("Sprite2D"):
		print("✅ Sprite2D encontrado")
	else:
		print("❌ ERROR: No se encontró Sprite2D")
	
	# Conectar señales de Area2D
	body_entered.connect(_on_body_entered)
	
	# Destruir bala después de 5 segundos
	var timer = get_tree().create_timer(0.7)
	timer.timeout.connect(_destruir_por_tiempo)

func _destruir_por_tiempo() -> void:
	print("Bala destruida por tiempo")
	queue_free()

func _physics_process(delta: float) -> void:
	if ya_colisiono:
		return
	
	# MOVIMIENTO: Mover la bala manualmente
	var posicion_anterior = global_position.x
	global_position.x += velocidad * direccion * delta
	
	# Debug cada 60 frames (1 segundo aprox)
	if Engine.get_process_frames() % 60 == 0:
		print("🚀 Bala moviéndose:")
		print("  - Posición anterior: ", posicion_anterior)
		print("  - Posición actual: ", global_position.x)
		print("  - Dirección: ", direccion)
		print("  - Velocidad: ", velocidad)

func set_direccion(nueva_direccion: int) -> void:
	print("=== SET_DIRECCION LLAMADA ===")
	print("Nueva dirección: ", nueva_direccion)
	
	direccion = nueva_direccion
	
	# Voltear sprite si va hacia la izquierda
	if has_node("Sprite2D"):
		if direccion < 0:
			$Sprite2D.flip_h = true
			print("✅ Sprite volteado para izquierda")
		else:
			$Sprite2D.flip_h = false
			print("✅ Sprite normal para derecha")
	else:
		print("❌ ERROR: No se puede voltear sprite - Sprite2D no encontrado")
	
	print("Dirección final configurada: ", direccion)

func _on_body_entered(body: Node) -> void:
	if ya_colisiono:
		return
	
	print("=== COLISIÓN DETECTADA ===")
	print("Cuerpo: ", body.name)
	print("Grupos del cuerpo: ", body.get_groups())
	
	# IGNORAR al jugador por completo (no procesar como colisión)
	if body.is_in_group("jugador"):
		print("Ignorando colisión con jugador")
		return  # ← No hacer ya_colisiono = true
	
	ya_colisiono = true
	
	# Si toca un enemigo
	if body.is_in_group("enemigos"):
		print("¡Impacto con enemigo!")
		if body.has_method("recibir_daño"):
			body.recibir_daño(daño)
			print("Daño aplicado: ", daño)
		queue_free()
	
	# Si toca el suelo u otro objeto sólido
	elif not body.is_in_group("balas"):
		print("Bala impactó objeto sólido: ", body.name)
		queue_free()
