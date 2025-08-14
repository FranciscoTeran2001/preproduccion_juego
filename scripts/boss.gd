# scripts/boss.gd - Boss con sistema de audio
extends CharacterBody2D

# Estados simples del boss
enum BossState {
	PATRULLANDO,
	PERSIGUIENDO,
	ATACANDO,
	PAUSANDO,
	MUERTO
}

const TIEMPO_PAUSA_ENTRE_ATAQUES := 3.0
var pause_timer := 0.0

# Referencias básicas
@onready var animated_sprite = $AnimatedSprite2D
@onready var damage_area = $DamageArea
@onready var collision_shape = $DamageArea/CollisionShape2D

# ===== NUEVOS NODOS DE AUDIO =====
@onready var audio_hurt = $AudioHurt
@onready var audio_attack = $AudioAttack
@onready var audio_death = $AudioDeath

# Variables básicas
var jugador: Node2D = null
var estado_actual = BossState.PATRULLANDO
var puede_atacar := true
var jugadores_en_area := []
var esta_muerto := false

# Sistema de vida
var vida := 120
var vida_maxima := 120

# Sistema de patrullaje
var patrol_direction: int = 1
var patrol_start_position: Vector2
var patrol_timer: float = 0.0
var rng = RandomNumberGenerator.new()

# Configuración para área pequeña (25 unidades)
var patrol_speed: float = 10.0
var chase_speed: float = 18.0
var patrol_distance: float = 10.0
var detection_radius: float = 18.0

# Constantes de ataque
const DISTANCIA_ATAQUE := 10.0
const TIEMPO_ENTRE_ATAQUES := 2.5
const TIEMPO_ENTRE_EMPUJES := 0.6
const FUERZA_EMPUJE := 100.0
const DANO_BOSS := 30

# Variables de ataques aleatorios
var attack_patterns := ["basico", "doble", "carga", "area"]
var last_attack_time := 0.0
var attack_variety_timer := 0.0

func _ready() -> void:
	print("🦾 Boss simplificado iniciado")
	setup_boss()
	setup_audio()

# ===== NUEVA FUNCIÓN PARA CONFIGURAR AUDIO =====
func setup_audio():
	# Crear nodos de audio si no existen
	if not has_node("AudioHurt"):
		audio_hurt = AudioStreamPlayer2D.new()
		audio_hurt.name = "AudioHurt"
		add_child(audio_hurt)
	
	if not has_node("AudioAttack"):
		audio_attack = AudioStreamPlayer2D.new()
		audio_attack.name = "AudioAttack"
		add_child(audio_attack)
	
	if not has_node("AudioDeath"):
		audio_death = AudioStreamPlayer2D.new()
		audio_death.name = "AudioDeath"
		add_child(audio_death)
	
	# Cargar los archivos de audio (ajusta las rutas según tu proyecto)
	# Ejemplo de rutas - ajústalas según donde tengas tus archivos
	var hurt_sound = load("res://sounds/boss_hurt.ogg")  # o .wav, .mp3
	var attack_sound = load("res://sounds/boss_attack.ogg")
	var death_sound = load("res://sounds/boss_death.ogg")
	
	# Asignar los audios a los nodos
	if hurt_sound:
		audio_hurt.stream = hurt_sound
		audio_hurt.volume_db = -5  # Ajustar volumen si es necesario
	
	if attack_sound:
		audio_attack.stream = attack_sound
		audio_attack.volume_db = -3
	
	if death_sound:
		audio_death.stream = death_sound
		audio_death.volume_db = 0
	
	print("🔊 Sistema de audio del boss configurado")

func setup_boss():
	# Agregar a grupos
	add_to_group("enemies")
	add_to_group("boss")
	add_to_group("enemigos")
	
	# Configurar posición inicial
	patrol_start_position = global_position
	rng.randomize()
	patrol_timer = rng.randf_range(1.0, 3.0)
	
	# Buscar jugador
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		var nivel = get_parent()
		for child in nivel.get_children():
			if child.name.contains("jugador") or child.is_in_group("jugador"):
				jugador = child
				break
	
	if jugador:
		print("✅ Jugador encontrado: ", jugador.name)
	else:
		print("❌ Jugador no encontrado")
	
	# Configurar área de daño
	if damage_area:
		damage_area.body_entered.connect(_on_damage_area_body_entered)
		damage_area.body_exited.connect(_on_damage_area_body_exited)
		print("✅ DamageArea configurada")
	
	# Timer para empuje continuo
	var timer_empuje = Timer.new()
	timer_empuje.name = "TimerEmpuje"
	timer_empuje.wait_time = TIEMPO_ENTRE_EMPUJES
	timer_empuje.timeout.connect(_aplicar_empuje_continuo)
	add_child(timer_empuje)
	timer_empuje.start()
	
	# Configurar recepción de daño
	setup_damage_reception()
	
	cambiar_estado(BossState.PATRULLANDO)

func setup_damage_reception():
	# Área simple para recibir daño
	var hit_area = Area2D.new()
	hit_area.name = "HitArea"
	add_child(hit_area)
	
	var hit_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(20, 25)
	hit_shape.shape = shape
	hit_area.add_child(hit_shape)
	
	hit_area.body_entered.connect(_on_hit_by_projectile)
	hit_area.area_entered.connect(_on_hit_by_area)

func _physics_process(delta: float) -> void:
	if esta_muerto:
		return
	
	# Verificar jugador válido
	if jugador == null or not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		if jugador == null:
			return
	
	attack_variety_timer += delta
	
	# Lógica de estados
	match estado_actual:
		BossState.PATRULLANDO:
			comportamiento_patrulla(delta)
		BossState.PERSIGUIENDO:
			comportamiento_persecucion()
		BossState.ATACANDO:
			comportamiento_ataque()
		BossState.PAUSANDO:
			comportamiento_pausa(delta)
		BossState.MUERTO:
			return
	
	move_and_slide()
	actualizar_direccion_sprite()

func comportamiento_patrulla(delta: float) -> void:
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
	
	# Patrullaje simple
	var distance_from_start = global_position.x - patrol_start_position.x
	
	if abs(distance_from_start) >= patrol_distance:
		patrol_direction = -sign(distance_from_start)
		patrol_timer = rng.randf_range(1.0, 2.0)
	
	patrol_timer -= delta
	if patrol_timer <= 0:
		if rng.randf() < 0.3:
			patrol_direction *= -1
		patrol_timer = rng.randf_range(2.0, 4.0)
	
	if is_on_wall():
		patrol_direction *= -1
	
	velocity.x = patrol_direction * patrol_speed
	
	# Detectar jugador
	if jugador:
		var distancia = global_position.distance_to(jugador.global_position)
		if distancia <= detection_radius:
			print("🎯 Boss detecta jugador")
			cambiar_estado(BossState.PERSIGUIENDO)

func comportamiento_persecucion() -> void:
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
	
	var distancia = global_position.distance_to(jugador.global_position)
	
	# Debug cada 2 segundos
	if int(Engine.get_process_frames()) % 120 == 0:
		print("📏 Distancia: ", int(distancia), " | Necesita: ", DISTANCIA_ATAQUE)
	
	# ¡ATACAR cuando esté MUY CERCA!
	if distancia <= DISTANCIA_ATAQUE:
		print("⚔️ ¡BOSS ATACA! Distancia: ", int(distancia))
		cambiar_estado(BossState.ATACANDO)
		return
	
	# Si se aleja mucho, hacer una pausa antes de volver a patrullar
	if distancia > detection_radius * 1.8:
		print("🤔 Boss pierde al jugador - haciendo pausa")
		cambiar_estado(BossState.PAUSANDO)
		return
	
	# Perseguir al jugador - MENOS AGRESIVO
	var direccion_jugador = (jugador.global_position - global_position).normalized()
	velocity.x = direccion_jugador.x * chase_speed * 0.8  # Más lento

func comportamiento_ataque() -> void:
	# DETENERSE para atacar
	velocity.x = 0
	
	var distancia = global_position.distance_to(jugador.global_position)
	print("💥 Boss atacando - distancia: ", int(distancia))
	
	# Si el jugador se alejó, volver a perseguir
	if distancia > DISTANCIA_ATAQUE * 2:
		print("🏃 Jugador se alejó, volviendo a perseguir")
		cambiar_estado(BossState.PERSIGUIENDO)
		return
	
	# Ejecutar ataque si puede
	if puede_atacar:
		ejecutar_ataque_aleatorio()

func ejecutar_ataque_aleatorio() -> void:
	if esta_muerto:
		return
	
	puede_atacar = false
	
	# ===== REPRODUCIR AUDIO DE ATAQUE =====
	if audio_attack and audio_attack.stream:
		audio_attack.play()
		print("🔊 Reproduciendo audio de ataque")
	
	# Elegir ataque aleatorio
	var attack_type = attack_patterns[rng.randi() % attack_patterns.size()]
	
	# Evitar repetir el mismo ataque muy seguido
	if attack_variety_timer < 3.0 and attack_patterns.size() > 1:
		# Intentar un ataque diferente
		for i in range(3):  # Máximo 3 intentos
			var new_attack = attack_patterns[rng.randi() % attack_patterns.size()]
			if new_attack != attack_type:
				attack_type = new_attack
				break
	
	attack_variety_timer = 0.0
	print("🎲 Boss ejecuta ataque aleatorio: ", attack_type)
	
	match attack_type:
		"basico":
			ataque_basico()
		"doble":
			ataque_doble()
		"carga":
			ataque_carga()
		"area":
			ataque_area()
	
	# Cooldown
	await get_tree().create_timer(TIEMPO_ENTRE_ATAQUES).timeout
	puede_atacar = true
	
	# Después del ataque, SIEMPRE hacer una pausa
	print("😴 Boss hace pausa después del ataque")
	cambiar_estado(BossState.PAUSANDO)

# ===== TIPOS DE ATAQUES (con audio ya incluido) =====

func ataque_basico() -> void:
	print("🗡️ Ataque básico")
	animated_sprite.play("attack")
	
	# Flash visual
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(1.5, 1.5, 1.5, 1)
	get_tree().create_timer(0.2).timeout.connect(func():
		if animated_sprite:
			animated_sprite.modulate = original_modulate
	)

func ataque_doble() -> void:
	print("⚔️ Ataque doble")
	for i in range(2):
		animated_sprite.play("attack")
		# Reproducir audio en cada golpe
		if audio_attack and audio_attack.stream:
			audio_attack.play()
		await get_tree().create_timer(0.5).timeout

func ataque_carga() -> void:
	print("🚀 Ataque de carga")
	animated_sprite.play("angry2")
	
	# Moverse hacia el jugador rápidamente
	if jugador:
		var direccion = (jugador.global_position - global_position).normalized()
		velocity = direccion * chase_speed * 2
		move_and_slide()
	
	# Flash rojo
	animated_sprite.modulate = Color(2, 0.5, 0.5, 1)
	get_tree().create_timer(0.3).timeout.connect(func():
		if animated_sprite:
			animated_sprite.modulate = Color.WHITE
		velocity = Vector2.ZERO
	)

func ataque_area() -> void:
	print("💥 Ataque de área")
	animated_sprite.play("angry2")
	
	# Aumentar área de daño temporalmente
	if collision_shape and collision_shape.shape:
		if collision_shape.shape is CapsuleShape2D:
			var original_radius = collision_shape.shape.radius
			collision_shape.shape.radius = original_radius * 1.8
			
			get_tree().create_timer(1.5).timeout.connect(func():
				if collision_shape and collision_shape.shape:
					collision_shape.shape.radius = original_radius
			)

func comportamiento_pausa(delta: float) -> void:
	# DETENERSE completamente durante la pausa
	velocity.x = 0
	
	# Animación de pensativo/alerta
	if animated_sprite.animation != "angry1":
		animated_sprite.play("angry1")
	
	# Contar tiempo de pausa
	pause_timer += delta
	
	# Debug de pausa
	if int(Engine.get_process_frames()) % 60 == 0:  # Cada segundo
		print("😴 Boss pausando... ", int(pause_timer), "/", int(TIEMPO_PAUSA_ENTRE_ATAQUES))
	
	# Terminar pausa
	if pause_timer >= TIEMPO_PAUSA_ENTRE_ATAQUES:
		pause_timer = 0.0
		print("⚡ Boss termina pausa")
		
		# Decidir qué hacer después de la pausa
		if jugador:
			var distancia = global_position.distance_to(jugador.global_position)
			if distancia <= detection_radius:
				print("🎯 Jugador cerca - volviendo a perseguir")
				cambiar_estado(BossState.PERSIGUIENDO)
			else:
				print("🚶 Jugador lejos - volviendo a patrullar")
				cambiar_estado(BossState.PATRULLANDO)
		else:
			cambiar_estado(BossState.PATRULLANDO)

func cambiar_estado(nuevo_estado: BossState) -> void:
	var estado_anterior = estado_actual
	estado_actual = nuevo_estado
	
	print("🔄 Boss: ", BossState.keys()[estado_anterior], " → ", BossState.keys()[nuevo_estado])
	
	match nuevo_estado:
		BossState.PATRULLANDO:
			patrol_timer = rng.randf_range(1.0, 3.0)
		BossState.PERSIGUIENDO:
			pass
		BossState.ATACANDO:
			pass
		BossState.PAUSANDO:
			pause_timer = 0.0  # Resetear timer de pausa
		BossState.MUERTO:
			velocity = Vector2.ZERO

func actualizar_direccion_sprite() -> void:
	if velocity.x > 0:
		animated_sprite.flip_h = true   # Mirando izquierda
	elif velocity.x < 0:
		animated_sprite.flip_h = false  # Mirando derecha

# ===== SISTEMA DE DAÑO (MODIFICADO CON AUDIO) =====

func _on_hit_by_projectile(body):
	if body.name.contains("bala") or body.has_method("get_damage"):
		var damage = 12
		if body.has_method("get_damage"):
			damage = body.get_damage()
		
		recibir_daño(damage)
		
		if body.has_method("queue_free"):
			body.queue_free()

func _on_hit_by_area(area):
	if area.get_parent().name.contains("bala"):
		var damage = 12
		if area.has_method("get_damage"):
			damage = area.get_damage()
		elif area.get_parent().has_method("get_damage"):
			damage = area.get_parent().get_damage()
		
		recibir_daño(damage)
		
		if area.get_parent().has_method("queue_free"):
			area.get_parent().queue_free()

func recibir_daño(cantidad: int) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("💔 Boss recibe ", cantidad, " de daño. Vida: ", vida, "/", vida_maxima)
	
	# ===== REPRODUCIR AUDIO DE HERIDA =====
	if audio_hurt and audio_hurt.stream:
		audio_hurt.play()
		print("🔊 Reproduciendo audio de herida")
	
	# Efecto visual
	var original_modulate = animated_sprite.modulate
	animated_sprite.modulate = Color(2, 0.3, 0.3, 1)
	get_tree().create_timer(0.25).timeout.connect(func():
		if animated_sprite:
			animated_sprite.modulate = original_modulate
	)
	
	if vida <= 0:
		morir()
	else:
		# Si está patrullando y recibe daño, volverse agresivo
		if estado_actual == BossState.PATRULLANDO:
			cambiar_estado(BossState.PERSIGUIENDO)

func morir() -> void:
	if esta_muerto:
		return
	
	esta_muerto = true
	puede_atacar = false
	cambiar_estado(BossState.MUERTO)
	
	print("💀 ¡BOSS DERROTADO!")
	
	# ===== REPRODUCIR AUDIO DE MUERTE =====
	if audio_death and audio_death.stream:
		audio_death.play()
		print("🔊 Reproduciendo audio de muerte")
	
	if has_node("TimerEmpuje"):
		$TimerEmpuje.stop()
	
	# Efectos de muerte
	animated_sprite.modulate = Color(1.5, 0, 0, 1)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 2.5)
	
	# Esperar a que termine la animación de muerte
	await get_tree().create_timer(2.5).timeout
	
	# Cargar la escena de créditos
	print("🎉 ¡Juego completado! Cargando créditos...")
	get_tree().change_scene_to_file("res://UI/CreditScreen.tscn")

# ===== SISTEMA DE EMPUJE =====

func _on_damage_area_body_entered(body: Node) -> void:
	if esta_muerto:
		return
	
	if (body.is_in_group("jugador") or body.name.contains("jugador")) and not jugadores_en_area.has(body):
		jugadores_en_area.append(body)
		print("🎯 Jugador entró en área de daño")

func _on_damage_area_body_exited(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name.contains("jugador")) and jugadores_en_area.has(body):
		jugadores_en_area.erase(body)
		print("👋 Jugador salió del área de daño")

func _aplicar_empuje_continuo() -> void:
	if jugadores_en_area.is_empty() or esta_muerto:
		return
	
	# Solo aplicar daño si está en modo ataque
	if estado_actual != BossState.ATACANDO:
		return
	
	print("💥 Boss aplica daño continuo")
	
	for jugador_body in jugadores_en_area:
		if not is_instance_valid(jugador_body):
			jugadores_en_area.erase(jugador_body)
			continue
		
		# Aplicar daño
		if jugador_body.has_method("bajar_vida"):
			jugador_body.bajar_vida(DANO_BOSS)
		elif jugador_body.has_method("take_damage"):
			jugador_body.take_damage(DANO_BOSS)
		
		# Aplicar empuje
		var direccion_empuje = (jugador_body.global_position - global_position).normalized()
		if jugador_body is CharacterBody2D and "velocity" in jugador_body:
			jugador_body.velocity += direccion_empuje * FUERZA_EMPUJE

func _input(event):
	if event.is_action_pressed("ui_accept"):
		print("=== BOSS DEBUG ===")
		print("Estado: ", BossState.keys()[estado_actual])
		print("Vida: ", vida, "/", vida_maxima)
		print("Puede atacar: ", puede_atacar)
		if estado_actual == BossState.PAUSANDO:
			print("Tiempo pausa: ", int(pause_timer), "/", int(TIEMPO_PAUSA_ENTRE_ATAQUES))
		if jugador:
			var dist = global_position.distance_to(jugador.global_position)
			print("Distancia: ", int(dist))
		print("Jugadores en área: ", jugadores_en_area.size())
		print("==================")
