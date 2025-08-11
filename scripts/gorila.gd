# Script del Gorila Tutorial - FUNCIONAL
extends CharacterBody2D

# Estados del gorila
enum Estado {
	PATRULLANDO,
	PERSIGUIENDO,
	ATACANDO,
	MUERTO
}

# Variables principales
var jugador: Node2D = null
var puede_atacar := true
var jugadores_en_area := []
var estado_actual := Estado.PATRULLANDO
var esta_muerto := false

# Sistema de vida (fácil para tutorial)
var vida := 2
var vida_maxima := 2

# Sistema de patrullaje
var patrol_direction: int = 1
var patrol_start_position: Vector2
var patrol_timer: float = 0.0

# Configuración tutorial (más fácil)
const PATROL_SPEED = 15.0
const CHASE_SPEED = 30.0
const PATROL_DISTANCE = 30.0
const DETECTION_RADIUS = 60.0
const ATTACK_DISTANCE = 20.0
const ATTACK_DAMAGE = 15
const ATTACK_COOLDOWN = 2.0
const GRAVITY = 300.0

# Timer para ataques
var attack_timer: Timer

func _ready() -> void:
	print("🦍 Gorila tutorial iniciando...")
	
	# Configuración inicial
	add_to_group("enemigos")
	add_to_group("gorila_tutorial")
	patrol_start_position = global_position
	
	# Buscar jugador
	buscar_jugador()
	
	# Configurar Area2D para detección de jugador
	configurar_area_deteccion()
	
	# Crear timer de ataque
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_cooldown_finished)
	add_child(attack_timer)
	
	print("🦍 Gorila listo - Vida: ", vida)

func buscar_jugador() -> void:
	jugador = get_tree().get_first_node_in_group("jugador")
	
	if jugador == null:
		# Buscar en diferentes posibles ubicaciones
		var posibles_rutas = [
			"../jugador",
			"../../jugador", 
			"../../../jugador",
			"/root/Tutorial/jugador",
			"/root/Main/jugador"
		]
		
		for ruta in posibles_rutas:
			jugador = get_node_or_null(ruta)
			if jugador != null:
				break
	
	if jugador != null:
		print("🦍 Jugador encontrado: ", jugador.name)
	else:
		print("🦍 ⚠️ Jugador no encontrado")

func configurar_area_deteccion() -> void:
	if has_node("Area2D"):
		var area = $Area2D
		# Conectar señales manualmente
		if not area.body_entered.is_connected(_on_area_body_entered):
			area.body_entered.connect(_on_area_body_entered)
		if not area.body_exited.is_connected(_on_area_body_exited):
			area.body_exited.connect(_on_area_body_exited)
		print("🦍 Area2D configurada correctamente")
	else:
		print("🦍 ❌ Area2D no encontrada")

func _physics_process(delta: float) -> void:
	if esta_muerto:
		return
	
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Buscar jugador si se perdió
	if jugador == null or not is_instance_valid(jugador):
		buscar_jugador()
		if jugador == null:
			return
	
	# Detectar jugador por distancia
	detectar_jugador_por_distancia()
	
	# Comportamiento según estado
	match estado_actual:
		Estado.PATRULLANDO:
			comportamiento_patrulla(delta)
		Estado.PERSIGUIENDO:
			comportamiento_persecucion()
		Estado.ATACANDO:
			comportamiento_ataque()
		Estado.MUERTO:
			velocity.x = 0
	
	move_and_slide()
	actualizar_animacion()
	actualizar_direccion_sprite()

func detectar_jugador_por_distancia() -> void:
	if jugador == null or esta_muerto:
		return
	
	var distancia = global_position.distance_to(jugador.global_position)
	
	# Cambiar estados según distancia
	if distancia <= ATTACK_DISTANCE and puede_atacar:
		if estado_actual != Estado.ATACANDO:
			cambiar_estado(Estado.ATACANDO)
	elif distancia <= DETECTION_RADIUS:
		if estado_actual == Estado.PATRULLANDO:
			cambiar_estado(Estado.PERSIGUIENDO)
	else:
		if estado_actual == Estado.PERSIGUIENDO:
			cambiar_estado(Estado.PATRULLANDO)

func comportamiento_patrulla(delta: float) -> void:
	patrol_timer -= delta
	
	# Cambiar dirección ocasionalmente o al llegar al límite
	var distance_from_start = global_position.x - patrol_start_position.x
	
	if abs(distance_from_start) >= PATROL_DISTANCE or patrol_timer <= 0:
		patrol_direction *= -1
		patrol_timer = randf_range(2.0, 4.0)
	
	# Movimiento de patrulla
	velocity.x = patrol_direction * PATROL_SPEED

func comportamiento_persecucion() -> void:
	if jugador == null:
		return
	
	# Moverse hacia el jugador
	var direccion = sign(jugador.global_position.x - global_position.x)
	velocity.x = direccion * CHASE_SPEED

func comportamiento_ataque() -> void:
	# Detenerse para atacar
	velocity.x = 0
	
	if puede_atacar:
		ejecutar_ataque()

func ejecutar_ataque() -> void:
	puede_atacar = false
	print("🦍 ¡GORILA ATACANDO!")
	
	# Hacer daño a jugadores en el área
	for jugador_en_area in jugadores_en_area:
		if is_instance_valid(jugador_en_area) and jugador_en_area.has_method("bajar_vida"):
			print("🦍 Golpeando al jugador!")
			jugador_en_area.bajar_vida(ATTACK_DAMAGE)
	
	# Iniciar cooldown
	attack_timer.start()

func cambiar_estado(nuevo_estado: Estado) -> void:
	if estado_actual == nuevo_estado:
		return
	
	var estado_anterior = estado_actual
	estado_actual = nuevo_estado
	
	print("🦍 Estado: ", Estado.keys()[estado_anterior], " -> ", Estado.keys()[nuevo_estado])

func actualizar_animacion() -> void:
	if not has_node("AnimatedSprite2D"):
		return
	
	var sprite = $AnimatedSprite2D
	
	match estado_actual:
		Estado.PATRULLANDO, Estado.PERSIGUIENDO:
			if sprite.animation != "gorila_caminata":
				sprite.play("gorila_caminata")
		Estado.ATACANDO:
			if sprite.animation != "gorila_ataque":
				sprite.play("gorila_ataque")
		Estado.MUERTO:
			if sprite.animation != "gorila_muerte":
				sprite.play("gorila_muerte")

func actualizar_direccion_sprite() -> void:
	if velocity.x > 0:
		$AnimatedSprite2D.flip_h = false
	elif velocity.x < 0:
		$AnimatedSprite2D.flip_h = true

# ===== SEÑALES DEL AREA2D =====

func _on_area_body_entered(body: Node) -> void:
	print("🦍 Cuerpo entró en área: ", body.name, " - Grupos: ", body.get_groups())
	
	# Verificar si es el jugador
	if body.is_in_group("jugador") or body.name.to_lower().contains("jugador"):
		if not jugadores_en_area.has(body):
			jugadores_en_area.append(body)
			print("🦍 ¡Jugador detectado en área de ataque!")
	
	# Verificar si es una bala del jugador
	if body.is_in_group("bala_jugador") or body.name.to_lower().contains("bala"):
		print("🦍 ¡Gorila golpeado por bala!")
		recibir_daño(1)
		if is_instance_valid(body):
			body.queue_free()

func _on_area_body_exited(body: Node) -> void:
	print("🦍 Cuerpo salió del área: ", body.name)
	
	if body.is_in_group("jugador") or body.name.to_lower().contains("jugador"):
		if jugadores_en_area.has(body):
			jugadores_en_area.erase(body)
			print("🦍 Jugador salió del área de ataque")

func _on_attack_cooldown_finished() -> void:
	puede_atacar = true
	print("🦍 Cooldown de ataque terminado")
	
	# Si ya no hay jugador cerca, cambiar estado
	if jugadores_en_area.is_empty():
		detectar_jugador_por_distancia()

# ===== SISTEMA DE DAÑO =====

func recibir_daño(cantidad: int = 1) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("🦍 Gorila recibió ", cantidad, " de daño. Vida restante: ", vida)
	
	# Efecto visual de daño
	efecto_daño()
	
	if vida <= 0:
		morir()
	else:
		# Mostrar animación de daño brevemente
		if has_node("AnimatedSprite2D") and $AnimatedSprite2D.sprite_frames.has_animation("gorila_hurt"):
			$AnimatedSprite2D.play("gorila_hurt")
			await get_tree().create_timer(0.3).timeout

func efecto_daño() -> void:
	if not has_node("AnimatedSprite2D"):
		return
	
	var sprite = $AnimatedSprite2D
	var color_original = sprite.modulate
	
	sprite.modulate = Color(1, 0.2, 0.2)  # Rojo
	await get_tree().create_timer(0.2).timeout
	sprite.modulate = color_original

func morir() -> void:
	if esta_muerto:
		return
	
	esta_muerto = true
	cambiar_estado(Estado.MUERTO)
	
	print("🦍 ¡Gorila tutorial eliminado!")
	print("🎓 ¡Tutorial de combate completado!")
	
	# Desactivar colisiones
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	if has_node("Area2D/CollisionShape2D2"):
		$Area2D/CollisionShape2D2.set_deferred("disabled", true)
	
	# Detener timers
	if attack_timer:
		attack_timer.stop()
	
	# Limpiar referencias
	jugadores_en_area.clear()
	velocity = Vector2.ZERO
	
	# Reproducir animación de muerte
	if has_node("AnimatedSprite2D") and $AnimatedSprite2D.sprite_frames.has_animation("gorila_muerte"):
		$AnimatedSprite2D.play("gorila_muerte")
		await $AnimatedSprite2D.animation_finished
	else:
		await get_tree().create_timer(2.0).timeout
	
	queue_free()

# ===== FUNCIONES DE DEBUG =====

func debug_info() -> void:
	print("🦍 === DEBUG GORILA ===")
	print("Estado actual: ", Estado.keys()[estado_actual])
	print("Vida: ", vida)
	print("Puede atacar: ", puede_atacar)
	print("Jugadores en área: ", jugadores_en_area.size())
	print("Jugador referencia: ", jugador)
	if jugador:
		print("Distancia al jugador: ", global_position.distance_to(jugador.global_position))

# Llamar cada pocos segundos para debug
func _on_debug_timer_timeout() -> void:
	debug_info()
