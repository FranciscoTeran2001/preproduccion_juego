extends CharacterBody2D

@export var speed := 20.0
@export var detection_range := 30.0
@export var patrol_distance_min := 20.0
@export var patrol_distance_max := 40.0
const LIMITE_PERSECUCION := 100.0

var jugador: Node2D = null
var punto_patrulla: Vector2 = Vector2.ZERO
var estado := "patrulla"
var tiempo_patrulla := 0.0

var puede_atacar := true
var jugadores_en_area := []
const DISTANCIA_ATAQUE := 1.0
const TIEMPO_ENTRE_ATAQUES := 1.0
const TIEMPO_ENTRE_EMPUJES := 0.3
const FUERZA_EMPUJE := 200.0
const DANIO_POR_ATAQUE := 25

@onready var sprite = $AnimatedSprite2D
var raycast_suelo: RayCast2D = null

func _ready():
	# Inicializar raycast_suelo (agregalo en el editor o con esto)
	if not has_node("Raycast_suelo"):
		raycast_suelo = RayCast2D.new()
		raycast_suelo.name = "Raycast_suelo"
		raycast_suelo.position = Vector2(10, 10)
		raycast_suelo.target_position = Vector2(16, 0)
		raycast_suelo.enabled = true
		add_child(raycast_suelo)
	else:
		raycast_suelo = $Raycast_suelo

	jugador = get_tree().get_first_node_in_group("jugador")
	if not jugador:
		jugador = get_tree().get_first_node_in_group("player")

	if has_node("DamageArea"):
		$DamageArea.body_entered.connect(_on_DamageArea_body_entered)
		$DamageArea.body_exited.connect(_on_DamageArea_body_exited)
	else:
		printerr("DamageArea no encontrada - no podrá atacar")

	var timer_empuje = Timer.new()
	timer_empuje.name = "TimerEmpuje"
	timer_empuje.wait_time = TIEMPO_ENTRE_EMPUJES
	timer_empuje.timeout.connect(_aplicar_empuje_continuo)
	add_child(timer_empuje)
	timer_empuje.start()

	# IMPORTANTE: inicializar el punto patrulla con uno NUEVO que sea distinto de la posición actual
	nuevo_punto_patrulla()
	sprite.play("attack")  # animación que usás para moverse

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += 980 * delta
	else:
		velocity.y = 0

	ia_con_ataque(delta)
	move_and_slide()

	# Siempre mantén la animación attack para que mueva patas
	if sprite.animation != "attack":
		sprite.play("attack")

func ia_con_ataque(delta):
	if not jugador:
		patrullar(delta)
		return

	var distancia = global_position.distance_to(jugador.global_position)

	if distancia <= DISTANCIA_ATAQUE:
		atacar()
	elif distancia < detection_range:
		perseguir()
	else:
		patrullar(delta)

func atacar():
	estado = "ataca"
	if not jugador:
		return

	velocity.x = 0
	if puede_atacar:
		puede_atacar = false
		var direccion_jugador = sign(jugador.global_position.x - global_position.x)
		sprite.flip_h = direccion_jugador > 0

		await get_tree().create_timer(TIEMPO_ENTRE_ATAQUES).timeout
		puede_atacar = true

func patrullar(delta):
	estado = "patrulla"
	tiempo_patrulla += delta

	var distancia_punto = global_position.distance_to(punto_patrulla)

	# Si ya llegó o tiempo se acabó, busca nuevo punto
	if tiempo_patrulla > 3.0 or distancia_punto < 10:
		nuevo_punto_patrulla()
		tiempo_patrulla = 0.0

	# Mover hacia el punto patrulla
	var direccion = (punto_patrulla - global_position).normalized()
	velocity.x = direccion.x * speed * 0.4
	sprite.flip_h = velocity.x < 0

func perseguir():
	estado = "persigue"
	if not jugador:
		return

	var direccion = (jugador.global_position - global_position).normalized()
	velocity.x = direccion.x * speed * 0.6
	sprite.flip_h = velocity.x < 0

func nuevo_punto_patrulla():
	var distancia = randf_range(patrol_distance_min, patrol_distance_max)
	var direccion = 1 if randf() > 0.5 else -1
	punto_patrulla = global_position + Vector2(distancia * direccion, 0)
	print("Nuevo punto patrulla:", punto_patrulla)

func _on_DamageArea_body_entered(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name == "jugador") and not jugadores_en_area.has(body):
		jugadores_en_area.append(body)

func _on_DamageArea_body_exited(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name == "jugador") and jugadores_en_area.has(body):
		jugadores_en_area.erase(body)

func _aplicar_empuje_continuo() -> void:
	if jugadores_en_area.is_empty():
		return

	for jugador_body in jugadores_en_area:
		if not is_instance_valid(jugador_body):
			jugadores_en_area.erase(jugador_body)
			continue

		if jugador_body.has_method("bajar_vida"):
			jugador_body.bajar_vida(DANIO_POR_ATAQUE)
		elif jugador_body.has_method("take_damage"):
			jugador_body.take_damage(DANIO_POR_ATAQUE)
		elif jugador_body.has_method("recibir_danio"):
			jugador_body.recibir_danio(DANIO_POR_ATAQUE)

		aplicar_empuje(jugador_body)

func aplicar_empuje(jugador_body: Node) -> void:
	var direccion_x = sign(jugador_body.global_position.x - global_position.x)
	var direccion_empuje = Vector2(direccion_x, 0).normalized()

	if jugador_body is CharacterBody2D:
		jugador_body.velocity += direccion_empuje * (FUERZA_EMPUJE * 0.5)
		jugador_body.move_and_slide()
	elif jugador_body is RigidBody2D:
		jugador_body.apply_central_impulse(direccion_empuje * FUERZA_EMPUJE)

func recibir_danio(cantidad: float):
	queue_free()
