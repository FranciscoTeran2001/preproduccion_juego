extends CharacterBody2D

# ============ CONFIGURACIÓN SIMPLE ============
@export var speed: float = 40.0
@export var detection_range: float = 20.0
@export var patrol_distance: float = 30.0  # Distancia total de patrullaje (ida y vuelta)

# ========== SISTEMA DE VIDA ==========
var vida := 50  # 2 balas para morir
var vida_maxima := 50
var esta_muerto := false

# ========== VARIABLES DE ATAQUE ==========
var puede_atacar := true
var jugadores_en_area := []
const DISTANCIA_ATAQUE := 0.1
const TIEMPO_ENTRE_ATAQUES := 1.0
const TIEMPO_ENTRE_EMPUJES := 0.3
const FUERZA_EMPUJE := 200.0
const DANIO_POR_ATAQUE := 25

# Variables internas
var jugador: Node2D = null
var estado: String = "patrulla"
var time_elapsed: float = 0.0

# Sistema de patrullaje fijo
var punto_izquierdo: Vector2
var punto_derecho: Vector2
var yendo_a_derecha: bool = true

# Variables para naturalidad
var speed_variation: float = 0.0

@onready var sprite = $AnimatedSprite2D

func _ready():
	print("=== SERPIENTE INICIANDO ===")
	
	# AGREGAR AL GRUPO DE ENEMIGOS PARA LAS BALAS
	add_to_group("enemigos")
	
	# Buscar jugador
	jugador = get_tree().get_first_node_in_group("jugador")
	if not jugador:
		jugador = get_tree().get_first_node_in_group("player")
	
	if jugador:
		print("✅ Jugador encontrado: ", jugador.name)
	else:
		print("❌ No hay jugador")
	
	# Configurar DamageArea
	if has_node("DamageArea"):
		$DamageArea.body_entered.connect(_on_DamageArea_body_entered)
		$DamageArea.body_exited.connect(_on_DamageArea_body_exited)
	else:
		printerr("DamageArea no encontrada")
	
	# Timer para empuje continuo
	var timer_empuje = Timer.new()
	timer_empuje.name = "TimerEmpuje"
	timer_empuje.wait_time = TIEMPO_ENTRE_EMPUJES
	timer_empuje.timeout.connect(_aplicar_empuje_continuo)
	add_child(timer_empuje)
	timer_empuje.start()
	
	# Punto inicial de patrulla
	# Establecer puntos fijos de patrullaje
	punto_izquierdo = Vector2(global_position.x - patrol_distance, global_position.y)
	punto_derecho = Vector2(global_position.x + patrol_distance, global_position.y)
	
	# Dirección inicial aleatoria
	yendo_a_derecha = randf() > 0.5
	
	sprite.play("idle")

func _physics_process(delta):
	# No hacer nada si está muerto
	if esta_muerto:
		return
	
	time_elapsed += delta  # Para variaciones naturales
		
	if not is_on_floor():
		velocity.y += 980 * delta
	
	ia_con_ataque(delta)
	move_and_slide()

# ========== IA CON ATAQUE ==========
func ia_con_ataque(delta):
	if esta_muerto:
		return
		
	var distancia = INF
	if jugador:
		distancia = global_position.distance_to(jugador.global_position)

	if distancia == DISTANCIA_ATAQUE:
		atacar()
	elif distancia < detection_range:
		perseguir()
	else:
		patrullar(delta)
	
	print("📡 Estado: ", estado, " | Distancia al jugador: ", distancia)

# ========== SISTEMA DE DAÑO ==========
func recibir_daño(cantidad: int) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("Serpiente recibió ", cantidad, " de daño. Vida restante: ", vida)
	
	# Efecto visual de daño
	efecto_daño()
	
	if vida <= 0:
		morir()

# ========== EFECTO VISUAL DE DAÑO ==========
func efecto_daño() -> void:
	if not sprite:
		return
		
	# Reproducir animación de daño si existe
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
		await sprite.animation_finished
		# Volver a la animación anterior si no está muerto
		if not esta_muerto:
			sprite.play("idle")
	else:
		# Parpadeo rojo si no hay animación de daño
		var color_original = sprite.modulate
		sprite.modulate = Color(1, 0.2, 0.2)
		await get_tree().create_timer(0.1).timeout
		sprite.modulate = color_original

# ========== MUERTE ==========
func morir() -> void:
	if esta_muerto:
		return
		
	esta_muerto = true
	puede_atacar = false
	velocity = Vector2.ZERO
	
	print("¡Serpiente eliminada!")
	
	# Detener el timer de empuje
	if has_node("TimerEmpuje"):
		$TimerEmpuje.stop()
	
	# Reproducir animación de muerte
	if sprite and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	else:
		print("Animación 'death' no encontrada")
	
	# Eliminar la serpiente
	queue_free()

# ========== ATAQUE ==========
func atacar():
	if esta_muerto:
		return
		
	estado = "ataca"
	
	if not jugador:
		return
	
	velocity.x = 0
	
	if puede_atacar:
		print("=== SERPIENTE INICIANDO ATAQUE ===")
		puede_atacar = false
		
		if sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")
		else:
			sprite.play("idle")
		
		var direccion_jugador = sign(jugador.global_position.x - global_position.x)
		sprite.flip_h = direccion_jugador > 0
		
		await get_tree().create_timer(TIEMPO_ENTRE_ATAQUES).timeout
		puede_atacar = true
		print("=== SERPIENTE ATAQUE DISPONIBLE ===")
	elif sprite.animation != "attack":
		sprite.play("attack")

# ========== PATRULLA FIJO ENTRE DOS PUNTOS ==========
func patrullar(delta):
	estado = "patrulla"
	
	# Determinar punto objetivo
	var punto_objetivo = punto_derecho if yendo_a_derecha else punto_izquierdo
	var distancia_al_objetivo = global_position.distance_to(punto_objetivo)
	
	# Si llegó cerca del objetivo, cambiar dirección
	if distancia_al_objetivo < 5.0:
		yendo_a_derecha = !yendo_a_derecha
		print("🔄 Cambiando dirección - Ahora va a: ", "derecha" if yendo_a_derecha else "izquierda")
	
	# Calcular dirección de movimiento
	var direccion_x = 1 if yendo_a_derecha else -1
	
	# Aplicar variación sutil de velocidad para naturalidad
	speed_variation = sin(time_elapsed * 2.0) * 0.1  # 10% de variación
	var velocidad_actual = speed * 0.5 * (1.0 + speed_variation)
	
	# Aplicar movimiento
	velocity.x = direccion_x * velocidad_actual
	
	# Animaciones
	if abs(velocity.x) > 3:
		sprite.play("walk")
		sprite.flip_h = velocity.x > 0
	else:
		sprite.play("idle")

# ========== PERSEGUIR SIMPLE ==========
func perseguir():
	estado = "persigue"
	
	if not jugador:
		return
	
	var direccion_x = sign(jugador.global_position.x - global_position.x)
	var velocidad_persecucion = speed * 0.5
	
	velocity.x = direccion_x * velocidad_persecucion
	
	sprite.play("walk")
	sprite.flip_h = velocity.x > 0

# ========== ÁREA DE DAÑO ==========
func _on_DamageArea_body_entered(body: Node) -> void:
	if esta_muerto:
		return
		
	if (body.is_in_group("jugador") or body.name == "jugador") and not jugadores_en_area.has(body):
		jugadores_en_area.append(body)
		print("Jugador entró en área de serpiente: ", body.name)

func _on_DamageArea_body_exited(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name == "jugador") and jugadores_en_area.has(body):
		jugadores_en_area.erase(body)
		print("Jugador salió del área de serpiente: ", body.name)

# ========== EMPUJE CONTINUO ==========
func _aplicar_empuje_continuo() -> void:
	if jugadores_en_area.is_empty() or esta_muerto:
		return
	
	print("=== SERPIENTE APLICANDO EMPUJE CONTINUO ===")
	
	for jugador_body in jugadores_en_area:
		if not is_instance_valid(jugador_body):
			jugadores_en_area.erase(jugador_body)
			continue
		
		if jugador_body.has_method("bajar_vida"):
			jugador_body.bajar_vida(DANIO_POR_ATAQUE)
		elif jugador_body.has_method("take_damage"):
			jugador_body.take_damage(DANIO_POR_ATAQUE)
		
		aplicar_empuje(jugador_body)

# ========== EMPUJE ==========
func aplicar_empuje(jugador_body: Node) -> void:
	if esta_muerto:
		return
		
	var direccion_x = sign(jugador_body.global_position.x - global_position.x)
	var direccion_empuje = Vector2(direccion_x, 0).normalized()
	
	if jugador_body is CharacterBody2D:
		jugador_body.velocity = direccion_empuje * FUERZA_EMPUJE
		jugador_body.move_and_slide()
		print("Empuje aplicado (CharacterBody2D)")
	elif jugador_body is RigidBody2D:
		jugador_body.apply_central_impulse(direccion_empuje * FUERZA_EMPUJE)
		print("Empuje aplicado (RigidBody2D)")

# ========== FUNCIONES PLACEHOLDER ==========
func _on_area_detector_body_entered(body: Node2D) -> void:
	pass

func _on_area_detector_body_exited(body: Node2D) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	pass

func _on_area_2d_body_exited(body: Node2D) -> void:
	pass

# ========== FUNCIÓN LEGACY (mantener compatibilidad) ==========
func recibir_danio(cantidad: float):
	recibir_daño(int(cantidad))
