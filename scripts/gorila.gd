


# Script del Gorila - IDÉNTICO al enemigo (valores exactos)
extends CharacterBody2D

# Estados simples
enum Estado {
	PATRULLANDO,
	PERSIGUIENDO,
	ATACANDO,
	MUERTO
}

# Variables del enemigo
var jugador: Node2D = null
var puede_atacar := true
var jugadores_en_area := []
var estado_actual := Estado.PATRULLANDO

# Sistema de vida (TUTORIAL: más fácil)
var vida := 3  # vs 50 del enemigo (solo 3 golpes)
var vida_maxima := 3
var esta_muerto := false

# Sistema de patrullaje (TUTORIAL: más lento)
var patrol_direction: int = 1  # 1 para derecha, -1 para izquierda
var patrol_start_position: Vector2
var patrol_timer: float = 0.0
var rng = RandomNumberGenerator.new()

# Configuración (TUTORIAL: más fácil)
@export var patrol_speed: float = 10  # vs 20.0 (40% más lento)
@export var chase_speed: float = 10.0   # vs 80.0 (más de la mitad más lento)
@export var patrol_distance: float = 25.0  # vs 35.0 (área más pequeña)
@export var detection_radius: float = 10.0  # vs 30.0 (un poco más fácil detectar)

# Constantes (TUTORIAL: ataques más suaves)
const DISTANCIA_ATAQUE := 4.8  # vs 25.0 (un poco más cerca)
const TIEMPO_ENTRE_ATAQUES := 1  # vs 1.0 (2.5x más lento)
const TIEMPO_ENTRE_EMPUJES := 1.2  # vs 0.3 (más tiempo para escapar)
const FUERZA_EMPUJE := 600.0  # vs 100.0 (mitad de fuerza)

# Referencias a nodos (CON audio para efectos de sonido)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_ataque: AudioStreamPlayer2D = get_node_or_null("AudioAtaque")
@onready var audio_muerte: AudioStreamPlayer2D = get_node_or_null("AudioMuerte")

func _ready() -> void:
	# Agregar a grupo de enemigos
	add_to_group("enemigos")
	
	# Guardar posición inicial para patrullaje
	patrol_start_position = global_position
	rng.randomize()
	# Inicializar patrullaje con timer más corto para espacio pequeño
	patrol_timer = rng.randf_range(1.5, 3.0)
	
	# Buscar el jugador (método del script anterior que funcionaba)
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		jugador = get_tree().get_root().get_node_or_null("Nivel1/jugador")
	
	if jugador == null:
		printerr("Jugador no encontrado")
	else:
		print("Jugador encontrado: ", jugador.name)
	
	# Configurar DamageArea
	if has_node("DamageArea"):
		$DamageArea.body_entered.connect(_on_damage_area_body_entered)
		$DamageArea.body_exited.connect(_on_damage_area_body_exited)
	else:
		printerr("🦍 DamageArea no encontrada")
	
	# Configurar audio
	configurar_audio()
	
	# Timer para empuje continuo
	var timer_empuje = Timer.new()
	timer_empuje.name = "TimerEmpuje"
	timer_empuje.wait_time = TIEMPO_ENTRE_EMPUJES
	timer_empuje.timeout.connect(_aplicar_empuje_continuo)
	add_child(timer_empuje)
	timer_empuje.start()
	
	# Iniciar patrullando
	cambiar_estado(Estado.PATRULLANDO)

func configurar_audio() -> void:
	if not has_node("AudioAtaque"):
		print("🦍 Advertencia: Nodo AudioAtaque no encontrado")
	else:
		audio_ataque.volume_db = -5.0
		print("🦍 ✅ AudioAtaque configurado")
	
	if not has_node("AudioMuerte"):
		print("🦍 Advertencia: Nodo AudioMuerte no encontrado")
	else:
		audio_muerte.volume_db = -3.0
		print("🦍 ✅ AudioMuerte configurado")

func _physics_process(delta: float) -> void:
	if esta_muerto:
		return
	
	# Verificar si el jugador sigue válido
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return
	
	# Lógica según el estado
	match estado_actual:
		Estado.PATRULLANDO:
			comportamiento_patrulla(delta)
		Estado.PERSIGUIENDO:
			comportamiento_persecucion()
		Estado.ATACANDO:
			comportamiento_ataque()
		Estado.MUERTO:
			return
	
	# Aplicar movimiento
	move_and_slide()
	
	# Actualizar dirección del sprite
	actualizar_direccion_sprite()

func comportamiento_patrulla(delta: float) -> void:
	# Usar animación walk
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
	
	# Calcular distancia desde posición inicial
	var distance_from_start = global_position.x - patrol_start_position.x
	
	# PATRULLAJE NATURAL: Cambiar dirección al llegar a los límites
	if abs(distance_from_start) >= patrol_distance:
		# Ha llegado al límite, cambiar dirección
		patrol_direction = -sign(distance_from_start)  # Cambiar hacia el centro
		patrol_timer = rng.randf_range(1.5, 3.0)  # Tiempo más corto para espacio pequeño
	
	# Cambiar dirección aleatoriamente (menos frecuente para ser más natural)
	patrol_timer -= delta
	if patrol_timer <= 0:
		# Ocasionalmente cambiar dirección aleatoriamente
		if rng.randf() < 0.3:  # 30% de probabilidad de cambio aleatorio
			patrol_direction *= -1
		patrol_timer = rng.randf_range(3.0, 5.0)  # Tiempo más largo entre cambios aleatorios
	
	# Cambiar dirección al tocar pared
	if is_on_wall():
		patrol_direction *= -1
		patrol_timer = rng.randf_range(1.0, 2.0)
	
	# Movimiento de patrullaje (velocidad más lenta para espacio pequeño)
	velocity.x = patrol_direction * (patrol_speed * 0.7)  # 30% más lento para ser más natural
	
	# Verificar si el jugador está cerca
	if jugador:
		var distancia = global_position.distance_to(jugador.global_position)
		if distancia <= detection_radius:
			print("🦍 ¡Jugador detectado! Cambiando a persecución")
			cambiar_estado(Estado.PERSIGUIENDO)

func comportamiento_persecucion() -> void:
	# Usar animación walk (más rápida)
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
	
	# NO acelerar tanto la animación para tutorial
	animated_sprite.speed_scale = 1.2  # vs 1.5 del enemigo
	
	var distancia = global_position.distance_to(jugador.global_position)
	
	# Verificar si está en rango de ataque
	if distancia <= DISTANCIA_ATAQUE:
		cambiar_estado(Estado.ATACANDO)
		return
	
	# Verificar si perdió al jugador
	if distancia > detection_radius:
		print("🦍 Jugador perdido, volviendo a patrullar")
		cambiar_estado(Estado.PATRULLANDO)
		return
	
	# Perseguir al jugador
	var direccion_jugador = (jugador.global_position - global_position).normalized()
	velocity.x = direccion_jugador.x * chase_speed

func comportamiento_ataque() -> void:
	# Detener movimiento
	velocity.x = 0
	
	# Restaurar velocidad de animación
	animated_sprite.speed_scale = 1.0
	
	var distancia = global_position.distance_to(jugador.global_position)
	
	# Si el jugador se alejó demasiado, volver a perseguir o patrullar
	if distancia > DISTANCIA_ATAQUE * 1.5:  # Un poco de margen
		if distancia <= detection_radius:
			cambiar_estado(Estado.PERSIGUIENDO)
		else:
			cambiar_estado(Estado.PATRULLANDO)
		return
	
	# Atacar si puede
	if puede_atacar:
		atacar()

func cambiar_estado(nuevo_estado: Estado) -> void:
	var estado_anterior = estado_actual
	estado_actual = nuevo_estado
	
	print("🦍 Estado: ", Estado.keys()[estado_anterior], " -> ", Estado.keys()[nuevo_estado])
	
	# Resetear animación al cambiar estado
	animated_sprite.speed_scale = 1.0
	
	match nuevo_estado:
		Estado.PATRULLANDO:
			patrol_timer = rng.randf_range(1.5, 3.0)  # Timer más corto para espacio pequeño
			animated_sprite.play("walk")
		Estado.PERSIGUIENDO:
			animated_sprite.play("walk")
		Estado.ATACANDO:
			# Se maneja en comportamiento_ataque()
			pass
		Estado.MUERTO:
			animated_sprite.play("dead")
			velocity = Vector2.ZERO

func actualizar_direccion_sprite() -> void:
	if velocity.x > 0:
		animated_sprite.flip_h = true
	elif velocity.x < 0:
		animated_sprite.flip_h = false
		
# ===== FUNCIONES DEL SCRIPT ANTERIOR QUE FUNCIONABAN =====

func atacar() -> void:
	if esta_muerto:
		return
	
	puede_atacar = false
	print("🦍 === ATACANDO GORILA TUTORIAL ===")
	
	# Reproducir sonido de ataque
	_reproducir_sonido_ataque()
	
	if animated_sprite.sprite_frames.has_animation("atacar"):
		animated_sprite.play("atacar")
	else:
		printerr("🦍 Animación 'atacar' no encontrada")
		animated_sprite.play("idle")
	
	# Cooldown para el próximo ataque
	await get_tree().create_timer(TIEMPO_ENTRE_ATAQUES).timeout
	puede_atacar = true

func _reproducir_sonido_ataque() -> void:
	if audio_ataque != null and audio_ataque.stream != null:
		audio_ataque.pitch_scale = randf_range(0.8, 1.2)
		audio_ataque.play()
		print("🦍 🔊 Reproduciendo sonido de ataque")
	else:
		print("🦍 ⚠️ No se pudo reproducir sonido de ataque")

func recibir_daño(cantidad: int) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("🦍 Gorila recibió ", cantidad, " de daño. Vida restante: ", vida)
	
	efecto_daño()
	
	if vida <= 0:
		morir()

func efecto_daño() -> void:
	if not has_node("AnimatedSprite2D"):
		return
		
	var sprite = $AnimatedSprite2D
	var color_original = sprite.modulate
	sprite.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = color_original

func morir() -> void:
	if esta_muerto:
		return
		
	esta_muerto = true
	puede_atacar = false
	cambiar_estado(Estado.MUERTO)
	
	print("🦍 ¡Gorila tutorial eliminado!")
	print("🎓 ¡Tutorial de combate completado!")
	
	# Reproducir sonido de muerte
	_reproducir_sonido_muerte()
	
	if has_node("TimerEmpuje"):
		$TimerEmpuje.stop()
	
	if animated_sprite.sprite_frames.has_animation("dead"):
		animated_sprite.play("dead")
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(1.0).timeout
	
	queue_free()

func _reproducir_sonido_muerte() -> void:
	if audio_muerte != null and audio_muerte.stream != null:
		audio_muerte.pitch_scale = randf_range(0.8, 1.0)
		audio_muerte.play()
		print("🦍 🔊 Reproduciendo sonido de muerte")
	else:
		print("🦍 ⚠️ No se pudo reproducir sonido de muerte")

func _on_damage_area_body_entered(body: Node) -> void:
	if esta_muerto:
		return
		
	if (body.is_in_group("jugador") or body.name == "jugador") and not jugadores_en_area.has(body):
		jugadores_en_area.append(body)
		print("🦍 Jugador entró en área: ", body.name)

func _on_damage_area_body_exited(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name == "jugador") and jugadores_en_area.has(body):
		jugadores_en_area.erase(body)
		print("🦍 Jugador salió del área: ", body.name)

func _aplicar_empuje_continuo() -> void:
	if jugadores_en_area.is_empty() or esta_muerto:
		return
	
	# Solo aplicar empuje si está en estado de ataque
	if estado_actual != Estado.ATACANDO:
		return
	
	print("🦍 === APLICANDO EMPUJE TUTORIAL ===")
	
	for jugador_body in jugadores_en_area:
		if not is_instance_valid(jugador_body):
			jugadores_en_area.erase(jugador_body)
			continue
		
		# Aplicar daño (TUTORIAL: menos daño)
		if jugador_body.has_method("bajar_vida"):
			jugador_body.bajar_vida(15)  # vs 25 del enemigo
		elif jugador_body.has_method("take_damage"):
			jugador_body.take_damage(15)
		
		# Aplicar empuje
		aplicar_empuje(jugador_body)

func aplicar_empuje(jugador_body: Node) -> void:
	if esta_muerto:
		return
		
	var direccion_empuje = (jugador_body.global_position - global_position).normalized()
	
	if jugador_body is CharacterBody2D:
		jugador_body.velocity = direccion_empuje * FUERZA_EMPUJE
		jugador_body.move_and_slide()
		print("🦍 Empuje tutorial aplicado (CharacterBody2D)")
	elif jugador_body is RigidBody2D:
		jugador_body.apply_central_impulse(direccion_empuje * FUERZA_EMPUJE)
		print("🦍 Empuje tutorial aplicado (RigidBody2D)")
	else:
		printerr("🦍 Tipo de cuerpo no compatible para empuje: ", jugador_body.get_class())
