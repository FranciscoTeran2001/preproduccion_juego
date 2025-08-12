extends CharacterBody2D

# ============ CONFIGURACIÓN SIMPLE ============
@export var speed: float = 25.0
@export var detection_range: float = 10.0
@export var patrol_distance: float = 7.0

# ========== SISTEMA DE VIDA ==========
var vida := 50
var vida_maxima := 50
var esta_muerto := false

# ========== VARIABLES DE ATAQUE MEJORADAS ==========
var puede_atacar := true
var jugadores_en_area := []
const DISTANCIA_ATAQUE := 8.0
const TIEMPO_ENTRE_ATAQUES := 1.2
const DISTANCIA_PERSECUCION := 10.0
const TIEMPO_ENTRE_EMPUJES := 0.3
const FUERZA_EMPUJE := 200.0
const DANIO_POR_ATAQUE := 25

# ========== NUEVO: SISTEMA DE ATURDIMIENTO ==========
var esta_aturdido := false
var tiempo_aturdimiento := 0.0
const DURACION_ATURDIMIENTO := 0.8  # Segundos de aturdimiento

# Variables internas
var jugador: Node2D = null
var estado: String = "patrulla"
var estado_anterior: String = "patrulla"  # NUEVO: Para recordar estado anterior
var time_elapsed: float = 0.0
var attack_timer: float = 0.0

# Sistema de patrullaje fijo
var punto_izquierdo: Vector2
var punto_derecho: Vector2
var yendo_a_derecha: bool = true

# Variables para naturalidad
var speed_variation: float = 0.0

# Referencias a nodos
@onready var sprite = $AnimatedSprite2D
@onready var audio_ataque: AudioStreamPlayer2D = $AudioAtaque
@onready var audio_damage: AudioStreamPlayer2D = $AudioDamage 
@onready var audio_muerte: AudioStreamPlayer2D = $AudioMuerte

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
	
	# Configurar audio inicial
	configurar_audio()
	
	# Timer para empuje continuo
	var timer_empuje = Timer.new()
	timer_empuje.name = "TimerEmpuje"
	timer_empuje.wait_time = TIEMPO_ENTRE_EMPUJES
	timer_empuje.timeout.connect(_aplicar_empuje_continuo)
	add_child(timer_empuje)
	timer_empuje.start()
	
	# Establecer puntos fijos de patrullaje
	punto_izquierdo = Vector2(global_position.x - patrol_distance, global_position.y)
	punto_derecho = Vector2(global_position.x + patrol_distance, global_position.y)
	
	# Dirección inicial aleatoria
	yendo_a_derecha = randf() > 0.5
	
	sprite.play("idle")

# ========== CONFIGURACIÓN DE AUDIO ==========
func configurar_audio() -> void:
	# Verificar que los nodos de audio existan
	if not has_node("AudioAtaque"):
		print("Advertencia: Nodo AudioAtaque no encontrado")
	else:
		audio_ataque.volume_db = -5.0  # Ajustar volumen
	
	if not has_node("AudioDamage"):
		print("Advertencia: Nodo AudioDamage no encontrado")
	else:
		audio_damage.volume_db = -8.0
	
	if not has_node("AudioMuerte"):
		print("Advertencia: Nodo AudioMuerte no encontrado")
	else:
		audio_muerte.volume_db = -3.0

func _physics_process(delta):
	# No hacer nada si está muerto
	if esta_muerto:
		return
	
	time_elapsed += delta
	
	# NUEVO: Actualizar timer de aturdimiento
	if esta_aturdido:
		tiempo_aturdimiento -= delta
		if tiempo_aturdimiento <= 0:
			esta_aturdido = false
			print("=== SERPIENTE YA NO ESTÁ ATURDIDA ===")
			# Volver al estado anterior o idle
			if estado_anterior == "ataca":
				sprite.play("attack")
			elif estado_anterior == "persigue" or estado_anterior == "persigue_agresivo":
				sprite.play("walk")
			else:
				sprite.play("idle")
		else:
			# Mantenerse aturdido (no hacer nada más)
			velocity.x = 0
			return
	
	# Actualizar timer de ataque
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			puede_atacar = true
			print("=== SERPIENTE ATAQUE DISPONIBLE ===")
		
	if not is_on_floor():
		velocity.y += 980 * delta
	
	ia_con_ataque_mejorada()
	move_and_slide()

# ========== IA MEJORADA CON ATAQUE ==========
func ia_con_ataque_mejorada():
	if esta_muerto or esta_aturdido:
		return
		
	var distancia = INF
	if jugador and is_instance_valid(jugador):
		distancia = global_position.distance_to(jugador.global_position)

	# LÓGICA MEJORADA: Más agresiva y pegajosa
	if distancia <= DISTANCIA_ATAQUE:
		# Está en rango de ataque
		atacar_mejorado()
	elif distancia <= DISTANCIA_PERSECUCION:
		# Sigue persiguiendo hasta estar más cerca
		perseguir_agresivo()
	elif distancia <= detection_range:
		# Detectado pero lejos, perseguir normal
		perseguir()
	else:
		# Lejos o sin jugador, patrullar
		patrullar()
	
	# Debug menos spam
	if int(time_elapsed) % 2 == 0:  # Solo cada 2 segundos
		print("📡 Estado: ", estado, " | Distancia: ", int(distancia), " | Puede atacar: ", puede_atacar, " | Aturdido: ", esta_aturdido)

# ========== ATAQUE MEJORADO ==========
func atacar_mejorado():
	if esta_muerto or esta_aturdido:
		return
		
	estado = "ataca"
	
	if not jugador:
		return
	
	# NUEVO: Seguir moviéndose hacia el jugador mientras ataca
	var direccion_x = sign(jugador.global_position.x - global_position.x)
	velocity.x = direccion_x * (speed * 0.3)  # Movimiento lento mientras ataca
	
	# MEJORADO: Reproducir sonido cada vez que puede atacar
	if puede_atacar:
		print("=== SERPIENTE INICIANDO ATAQUE ===")
		puede_atacar = false
		attack_timer = TIEMPO_ENTRE_ATAQUES  # Establecer cooldown
		
		# NUEVO: Reproducir sonido de ataque CADA VEZ
		_reproducir_sonido_ataque()
		
		# Reproducir animación de ataque
		if sprite.sprite_frames.has_animation("attack"):
			sprite.play("attack")
		else:
			sprite.play("idle")
		
		# Orientar hacia el jugador
		sprite.flip_h = direccion_x > 0
		
	elif sprite.animation != "attack" and not puede_atacar:
		# Mantener animación de ataque durante cooldown
		sprite.play("attack")
		sprite.flip_h = direccion_x > 0

# ========== REPRODUCIR SONIDO DE ATAQUE ==========
func _reproducir_sonido_ataque() -> void:
	if has_node("AudioAtaque") and audio_ataque.stream != null:
		# Variación aleatoria en el pitch para más variedad
		audio_ataque.pitch_scale = randf_range(0.8, 1.2)
		audio_ataque.play()
		print("🔊 Reproduciendo sonido de ataque de serpiente")
	else:
		print("No se puede reproducir sonido de ataque")

# ========== SISTEMA DE DAÑO MEJORADO ==========
func recibir_daño(cantidad: int) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("Serpiente recibió ", cantidad, " de daño. Vida restante: ", vida)
	
	# NUEVO: Reproducir sonido de daño
	_reproducir_sonido_damage()
	
	# Guardar estado actual antes del aturdimiento
	estado_anterior = estado
	
	# Activar aturdimiento
	esta_aturdido = true
	tiempo_aturdimiento = DURACION_ATURDIMIENTO
	velocity.x = 0  # Detener inmediatamente
	
	# Reproducir animación de hurt
	efecto_daño_mejorado()
	
	if vida <= 0:
		morir()

# ========== REPRODUCIR SONIDO DE DAÑO ==========
func _reproducir_sonido_damage() -> void:
	if has_node("AudioDamage") and audio_damage.stream != null:
		audio_damage.pitch_scale = randf_range(0.9, 1.1)
		audio_damage.play()
		print("🔊 Reproduciendo sonido de daño de serpiente")
	else:
		print("No se puede reproducir sonido de daño")

# ========== EFECTO VISUAL DE DAÑO MEJORADO ==========
func efecto_daño_mejorado() -> void:
	if not sprite:
		return
	
	print("=== SERPIENTE RECIBIENDO DAÑO - ANIMACIÓN HURT ===")
	
	# Reproducir animación de hurt
	if sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")
		print("✅ Reproduciendo animación HURT")
	else:
		print("❌ Animación 'hurt' no encontrada")
		# Parpadeo rojo como respaldo
		parpadeo_rojo()

# ========== PARPADEO ROJO (RESPALDO) ==========
func parpadeo_rojo() -> void:
	var color_original = sprite.modulate
	sprite.modulate = Color(1, 0.2, 0.2)  # Rojo
	
	# Crear un timer para restaurar el color
	var timer = Timer.new()
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.timeout.connect(func(): 
		if sprite:
			sprite.modulate = color_original
		timer.queue_free()
	)
	add_child(timer)
	timer.start()

# ========== MUERTE ==========
func morir() -> void:
	if esta_muerto:
		return
		
	esta_muerto = true
	puede_atacar = false
	esta_aturdido = false  # Ya no importa el aturdimiento
	velocity = Vector2.ZERO
	
	print("¡Serpiente eliminada!")
	
	# NUEVO: Reproducir sonido de muerte
	_reproducir_sonido_muerte()
	
	# Detener el timer de empuje
	if has_node("TimerEmpuje"):
		$TimerEmpuje.stop()
	
	# Detener otros sonidos
	if has_node("AudioAtaque"):
		audio_ataque.stop()
	
	# Reproducir animación de muerte
	if sprite and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
		await sprite.animation_finished
	else:
		print("Animación 'death' no encontrada")
		await get_tree().create_timer(1.0).timeout
	
	# Eliminar la serpiente
	queue_free()

# ========== REPRODUCIR SONIDO DE MUERTE ==========
func _reproducir_sonido_muerte() -> void:
	if has_node("AudioMuerte") and audio_muerte.stream != null:
		audio_muerte.pitch_scale = randf_range(0.8, 1.0)
		audio_muerte.play()
		print("🔊 Reproduciendo sonido de muerte de serpiente")
	else:
		print("No se puede reproducir sonido de muerte")

# ========== PATRULLA FIJO ENTRE DOS PUNTOS ==========
func patrullar():
	if esta_aturdido:
		return
		
	estado = "patrulla"
	
	# Determinar punto objetivo
	var punto_objetivo = punto_derecho if yendo_a_derecha else punto_izquierdo
	var distancia_al_objetivo = global_position.distance_to(punto_objetivo)
	
	# Si llegó cerca del objetivo, cambiar dirección
	if distancia_al_objetivo < 5.0:
		yendo_a_derecha = !yendo_a_derecha
		print("🔄 Serpiente cambiando dirección - Ahora va a: ", "derecha" if yendo_a_derecha else "izquierda")
	
	# Calcular dirección de movimiento
	var direccion_x = 1 if yendo_a_derecha else -1
	
	# Aplicar variación sutil de velocidad para naturalidad
	speed_variation = sin(time_elapsed * 2.0) * 0.1
	var velocidad_actual = speed * 0.5 * (1.0 + speed_variation)
	
	# Aplicar movimiento
	velocity.x = direccion_x * velocidad_actual
	
	# Animaciones
	if abs(velocity.x) > 3:
		sprite.play("walk")
		sprite.flip_h = velocity.x > 0
	else:
		sprite.play("idle")

# ========== PERSEGUIR AGRESIVO (NUEVO) ==========
func perseguir_agresivo():
	if esta_aturdido:
		return
		
	estado = "persigue_agresivo"
	
	if not jugador:
		return
	
	var direccion_x = sign(jugador.global_position.x - global_position.x)
	var velocidad_agresiva = speed * 1.5  # MÁS RÁPIDO: de 1.0 a 1.5
	
	velocity.x = direccion_x * velocidad_agresiva
	
	sprite.play("walk")
	sprite.flip_h = velocity.x > 0

# ========== PERSEGUIR SIMPLE ==========
func perseguir():
	if esta_aturdido:
		return
		
	estado = "persigue"
	
	if not jugador:
		return
	
	var direccion_x = sign(jugador.global_position.x - global_position.x)
	var velocidad_persecucion = speed * 1.2  # MÁS RÁPIDO: de 0.8 a 1.2
	
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

# ========== EMPUJE CONTINUO MEJORADO ==========
func _aplicar_empuje_continuo() -> void:
	if jugadores_en_area.is_empty() or esta_muerto or esta_aturdido:
		return
	
	# NUEVO: Solo aplicar empuje si está en estado de ataque
	if estado != "ataca":
		return
	
	print("=== SERPIENTE APLICANDO EMPUJE CONTINUO ===")
	
	for jugador_body in jugadores_en_area:
		if not is_instance_valid(jugador_body):
			jugadores_en_area.erase(jugador_body)
			continue
		
		# Aplicar daño
		if jugador_body.has_method("bajar_vida"):
			jugador_body.bajar_vida(DANIO_POR_ATAQUE)
		elif jugador_body.has_method("take_damage"):
			jugador_body.take_damage(DANIO_POR_ATAQUE)
		
		# Aplicar empuje
		aplicar_empuje(jugador_body)

# ========== EMPUJE ==========
func aplicar_empuje(jugador_body: Node) -> void:
	if esta_muerto or esta_aturdido:
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



# ========== FUNCIÓN LEGACY (mantener compatibilidad) ==========
func recibir_danio(cantidad: float):
	recibir_daño(int(cantidad))
