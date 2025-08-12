# Script del Jefe Nivel 1 - Tutorial (similar al gorila pero más fuerte)
extends CharacterBody2D

# Estados del jefe
enum Estado {
	PATRULLANDO,
	PERSIGUIENDO,
	ATACANDO,
	MUERTO
}

# Variables del jefe
var jugador: Node2D = null
var puede_atacar := true
var jugadores_en_area := []
var estado_actual := Estado.PATRULLANDO

# Sistema de vida (JEFE: más resistente que gorila)
var vida := 100  # vs 3 del gorila (jefe más fuerte)
var vida_maxima := 100
var esta_muerto := false

# Sistema de patrullaje (JEFE: similar al gorila)
var patrol_direction: int = 1  # 1 para derecha, -1 para izquierda
var patrol_start_position: Vector2
var patrol_timer: float = 0.0
var rng = RandomNumberGenerator.new()

# Configuración (JEFE: similar al gorila pero ligeramente más rápido)
@export var patrol_speed: float = 12.0  # vs 10.0 del gorila (ligeramente más rápido)
@export var chase_speed: float = 15.0   # vs 10.0 del gorila (más rápido en persecución)
@export var patrol_distance: float = 30.0  # vs 25.0 del gorila (área ligeramente más grande)
@export var detection_radius: float = 15.0  # vs 10.0 del gorila (detecta un poco más lejos)

# Constantes (JEFE: ataques similares al gorila pero más fuertes)
const DISTANCIA_ATAQUE := 12.0  # vs 4.8 del gorila (ligeramente más lejos)
const TIEMPO_ENTRE_ATAQUES := 1.5  # vs 1.0 del gorila (un poco más lento)
const TIEMPO_ENTRE_EMPUJES := 1.0  # vs 1.2 del gorila (ligeramente más rápido)
const FUERZA_EMPUJE := 750.0  # vs 600.0 del gorila (más fuerte)

# Referencias a nodos (CON audio para jefe)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_ataque: AudioStreamPlayer2D = get_node_or_null("AudioAtaque")
@onready var audio_muerte: AudioStreamPlayer2D = get_node_or_null("AudioMuerte")
@onready var audio_daño: AudioStreamPlayer2D = get_node_or_null("AudioDaño")

func _ready() -> void:
	# Agregar a grupo de enemigos
	add_to_group("enemigos")
	add_to_group("jefe_tutorial")
	
	# Guardar posición inicial para patrullaje
	patrol_start_position = global_position
	rng.randomize()
	# Timer similar al gorila
	patrol_timer = rng.randf_range(1.5, 3.0)
	
	# Buscar el jugador (método idéntico al gorila)
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		jugador = get_tree().get_root().get_node_or_null("Nivel1/jugador")
	
	if jugador == null:
		printerr("👑 Jefe: Jugador no encontrado")
	else:
		print("👑 Jefe encontró al jugador: ", jugador.name)
	
	# Configurar DamageArea (idéntico al gorila)
	if has_node("DamageArea"):
		$DamageArea.body_entered.connect(_on_damage_area_body_entered)
		$DamageArea.body_exited.connect(_on_damage_area_body_exited)
	else:
		printerr("👑 DamageArea no encontrada")
	
	# Configurar audio
	configurar_audio()
	
	# Timer para empuje continuo (similar al gorila)
	var timer_empuje = Timer.new()
	timer_empuje.name = "TimerEmpuje"
	timer_empuje.wait_time = TIEMPO_ENTRE_EMPUJES
	timer_empuje.timeout.connect(_aplicar_empuje_continuo)
	add_child(timer_empuje)
	timer_empuje.start()
	
	# Iniciar patrullando
	cambiar_estado(Estado.PATRULLANDO)
	print("👑 Jefe tutorial listo - Vida: ", vida)

func configurar_audio() -> void:
	if not has_node("AudioAtaque"):
		print("👑 Advertencia: Nodo AudioAtaque no encontrado")
	else:
		audio_ataque.volume_db = -3.0
		print("👑 ✅ AudioAtaque configurado")
	
	if not has_node("AudioMuerte"):
		print("👑 Advertencia: Nodo AudioMuerte no encontrado")
	else:
		audio_muerte.volume_db = -1.0
		print("👑 ✅ AudioMuerte configurado")
	
	if not has_node("AudioDaño"):
		print("👑 Advertencia: Nodo AudioDaño no encontrado")
	else:
		audio_daño.volume_db = -5.0
		print("👑 ✅ AudioDaño configurado")

func _physics_process(delta: float) -> void:
	if esta_muerto:
		return
	
	# Verificar si el jugador sigue válido (idéntico al gorila)
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return
	
	# Lógica según el estado (idéntica al gorila)
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
	# Usar animación de caminata del jefe
	if animated_sprite.animation != "caminata_jefe":
		animated_sprite.play("caminata_jefe")
	
	# Calcular distancia desde posición inicial (idéntico al gorila)
	var distance_from_start = global_position.x - patrol_start_position.x
	
	# PATRULLAJE NATURAL: Cambiar dirección al llegar a los límites (idéntico al gorila)
	if abs(distance_from_start) >= patrol_distance:
		# Ha llegado al límite, cambiar dirección
		patrol_direction = -sign(distance_from_start)  # Cambiar hacia el centro
		patrol_timer = rng.randf_range(1.5, 3.0)  # Igual que gorila
	
	# Cambiar dirección aleatoriamente (idéntico al gorila)
	patrol_timer -= delta
	if patrol_timer <= 0:
		# Ocasionalmente cambiar dirección aleatoriamente
		if rng.randf() < 0.3:  # 30% de probabilidad como gorila
			patrol_direction *= -1
		patrol_timer = rng.randf_range(3.0, 5.0)  # Igual que gorila
	
	# Cambiar dirección al tocar pared (idéntico al gorila)
	if is_on_wall():
		patrol_direction *= -1
		patrol_timer = rng.randf_range(1.0, 2.0)
	
	# Movimiento de patrullaje (similar al gorila pero ligeramente más rápido)
	velocity.x = patrol_direction * (patrol_speed * 0.7)  # Similar al gorila
	
	# Verificar si el jugador está cerca (idéntico al gorila)
	if jugador:
		var distancia = global_position.distance_to(jugador.global_position)
		if distancia <= detection_radius:
			print("👑 ¡Jefe detectó al jugador! Cambiando a persecución")
			cambiar_estado(Estado.PERSIGUIENDO)

func comportamiento_persecucion() -> void:
	# Usar animación de caminata del jefe (más rápida)
	if animated_sprite.animation != "caminata_jefe":
		animated_sprite.play("caminata_jefe")
	
	# Acelerar animación (similar al gorila)
	animated_sprite.speed_scale = 1.3  # vs 1.2 del gorila (ligeramente más rápido)
	
	var distancia = global_position.distance_to(jugador.global_position)
	
	# Verificar si está en rango de ataque (idéntico al gorila)
	if distancia <= DISTANCIA_ATAQUE:
		cambiar_estado(Estado.ATACANDO)
		return
	
	# Verificar si perdió al jugador (idéntico al gorila)
	if distancia > detection_radius:
		print("👑 Jefe perdió al jugador, volviendo a patrullar")
		cambiar_estado(Estado.PATRULLANDO)
		return
	
	# Perseguir al jugador (similar al gorila pero más rápido)
	var direccion_jugador = (jugador.global_position - global_position).normalized()
	velocity.x = direccion_jugador.x * chase_speed

func comportamiento_ataque() -> void:
	# Restaurar velocidad de animación
	animated_sprite.speed_scale = 1.0
	
	var distancia = global_position.distance_to(jugador.global_position)
	
	# Si el jugador se alejó demasiado, volver a perseguir o patrullar (idéntico al gorila)
	if distancia > DISTANCIA_ATAQUE * 1.5:  # Un poco de margen
		if distancia <= detection_radius:
			cambiar_estado(Estado.PERSIGUIENDO)
		else:
			cambiar_estado(Estado.PATRULLANDO)
		return
	
	# SEGUIR AL JUGADOR MIENTRAS ATACA (como el gorila)
	var direccion_jugador = (jugador.global_position - global_position).normalized()
	velocity.x = direccion_jugador.x * (chase_speed * 0.3)  # 30% de velocidad mientras ataca
	
	# Atacar si puede (idéntico al gorila)
	if puede_atacar:
		atacar()

func cambiar_estado(nuevo_estado: Estado) -> void:
	var estado_anterior = estado_actual
	estado_actual = nuevo_estado
	
	print("👑 Jefe Estado: ", Estado.keys()[estado_anterior], " -> ", Estado.keys()[nuevo_estado])
	
	# Resetear animación al cambiar estado (idéntico al gorila)
	animated_sprite.speed_scale = 1.0
	
	match nuevo_estado:
		Estado.PATRULLANDO:
			patrol_timer = rng.randf_range(1.5, 3.0)  # Igual que gorila
			animated_sprite.play("caminata_jefe")
		Estado.PERSIGUIENDO:
			animated_sprite.play("caminata_jefe")
		Estado.ATACANDO:
			# Se maneja en comportamiento_ataque()
			pass
		Estado.MUERTO:
			animated_sprite.play("muerte_jefe1")
			velocity = Vector2.ZERO

func actualizar_direccion_sprite() -> void:
	# Idéntico al gorila
	if velocity.x > 0:
		animated_sprite.flip_h = true
	elif velocity.x < 0:
		animated_sprite.flip_h = false

# ===== FUNCIONES DE COMBATE DEL JEFE (BASADAS EN EL GORILA) =====

func atacar() -> void:
	if esta_muerto:
		return
	
	puede_atacar = false
	print("👑 === JEFE ATACANDO ===")
	
	# Reproducir sonido de ataque
	_reproducir_sonido_ataque()
	
	# Alternar entre dos ataques del jefe
	var ataque_aleatorio = rng.randi_range(1, 2)
	if ataque_aleatorio == 1:
		if animated_sprite.sprite_frames.has_animation("enemigo_final_nivel1"):
			animated_sprite.play("enemigo_final_nivel1")
		else:
			printerr("👑 Animación 'enemigo_final_nivel1' no encontrada")
			animated_sprite.play("inactivo")
	else:
		if animated_sprite.sprite_frames.has_animation("jefe_ataque2"):
			animated_sprite.play("jefe_ataque2")
		else:
			printerr("👑 Animación 'jefe_ataque2' no encontrada")
			animated_sprite.play("inactivo")
	
	# Cooldown para el próximo ataque (ligeramente más lento que gorila)
	await get_tree().create_timer(TIEMPO_ENTRE_ATAQUES).timeout
	puede_atacar = true

func _reproducir_sonido_ataque() -> void:
	if audio_ataque != null and audio_ataque.stream != null:
		audio_ataque.pitch_scale = randf_range(0.7, 1.0)  # Más grave que gorila
		audio_ataque.play()
		print("👑 🔊 Jefe atacando con sonido")
	else:
		print("👑 ⚠️ No se pudo reproducir sonido de ataque")

func recibir_daño(cantidad: int = 1) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("👑 Jefe recibió ", cantidad, " de daño. Vida restante: ", vida)
	
	# Reproducir sonido de daño
	_reproducir_sonido_daño()
	
	# Efecto visual de daño (similar al gorila)
	efecto_daño()
	
	if vida <= 0:
		morir()
	else:
		# Mostrar animación de daño del jefe
		if animated_sprite.sprite_frames.has_animation("daño_jefe1"):
			var animacion_anterior = animated_sprite.animation
			animated_sprite.play("daño_jefe1")
			await get_tree().create_timer(0.5).timeout
			if not esta_muerto:
				animated_sprite.play(animacion_anterior)

func _reproducir_sonido_daño() -> void:
	if audio_daño != null and audio_daño.stream != null:
		audio_daño.pitch_scale = randf_range(0.8, 1.1)
		audio_daño.play()
		print("👑 🔊 Jefe recibiendo daño")
	else:
		print("👑 ⚠️ No se pudo reproducir sonido de daño")

func efecto_daño() -> void:
	# Idéntico al gorila pero rojo más intenso
	if not has_node("AnimatedSprite2D"):
		return
		
	var sprite = $AnimatedSprite2D
	var color_original = sprite.modulate
	sprite.modulate = Color(1, 0.1, 0.1)  # Rojo más intenso que gorila
	await get_tree().create_timer(0.15).timeout  # Un poco más largo
	sprite.modulate = color_original

func morir() -> void:
	if esta_muerto:
		return
		
	esta_muerto = true
	puede_atacar = false
	cambiar_estado(Estado.MUERTO)
	
	print("👑 ¡JEFE TUTORIAL DERROTADO!")
	print("🎉 ¡TUTORIAL COMPLETADO CON ÉXITO!")
	
	# Reproducir sonido de muerte épico
	_reproducir_sonido_muerte()
	
	# Detener timer de empuje (idéntico al gorila)
	if has_node("TimerEmpuje"):
		$TimerEmpuje.stop()
	
	# Reproducir animación de muerte (del jefe)
	if animated_sprite.sprite_frames.has_animation("muerte_jefe1"):
		animated_sprite.play("muerte_jefe1")
		await animated_sprite.animation_finished
	else:
		await get_tree().create_timer(1.5).timeout  # Un poco más tiempo que gorila
	
	queue_free()

func _reproducir_sonido_muerte() -> void:
	if audio_muerte != null and audio_muerte.stream != null:
		audio_muerte.pitch_scale = randf_range(0.6, 0.8)  # Más grave que gorila
		audio_muerte.play()
		print("👑 🔊 Sonido épico de muerte del jefe")
	else:
		print("👑 ⚠️ No se pudo reproducir sonido de muerte")

# ===== SEÑALES DEL AREA DE DAÑO (IDÉNTICAS AL GORILA) =====

func _on_damage_area_body_entered(body: Node) -> void:
	if esta_muerto:
		return
		
	if (body.is_in_group("jugador") or body.name == "jugador") and not jugadores_en_area.has(body):
		jugadores_en_area.append(body)
		print("👑 Jugador entró en área de ataque del jefe: ", body.name)

	# Verificar si es una bala del jugador (IGUAL QUE EL GORILA)
	if body.is_in_group("bala_jugador") or body.name.to_lower().contains("bala"):
		print("👑 ¡Jefe golpeado por bala!")
		recibir_daño(1)
		if is_instance_valid(body):
			body.queue_free()

func _on_damage_area_body_exited(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name == "jugador") and jugadores_en_area.has(body):
		jugadores_en_area.erase(body)
		print("👑 Jugador salió del área de ataque del jefe: ", body.name)

func _aplicar_empuje_continuo() -> void:
	if jugadores_en_area.is_empty() or esta_muerto:
		return
	
	# Solo aplicar empuje si está en estado de ataque (idéntico al gorila)
	if estado_actual != Estado.ATACANDO:
		return
	
	print("👑 === JEFE APLICANDO EMPUJE ===")
	
	for jugador_body in jugadores_en_area:
		if not is_instance_valid(jugador_body):
			jugadores_en_area.erase(jugador_body)
			continue
		
		# Aplicar daño (JEFE: más daño que gorila)
		if jugador_body.has_method("bajar_vida"):
			jugador_body.bajar_vida(20)  # vs 15 del gorila
			print("👑 Jefe hizo 20 puntos de daño")
		elif jugador_body.has_method("take_damage"):
			jugador_body.take_damage(20)
		
		# Aplicar empuje
		aplicar_empuje(jugador_body)

func aplicar_empuje(jugador_body: Node) -> void:
	# Idéntico al gorila pero con más fuerza
	if esta_muerto:
		return
		
	var direccion_empuje = (jugador_body.global_position - global_position).normalized()
	
	if jugador_body is CharacterBody2D:
		jugador_body.velocity = direccion_empuje * FUERZA_EMPUJE
		jugador_body.move_and_slide()
		print("👑 Empuje del jefe aplicado (CharacterBody2D)")
	elif jugador_body is RigidBody2D:
		jugador_body.apply_central_impulse(direccion_empuje * FUERZA_EMPUJE)
		print("👑 Empuje del jefe aplicado (RigidBody2D)")
	else:
		printerr("👑 Tipo de cuerpo no compatible para empuje: ", jugador_body.get_class())
