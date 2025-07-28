extends CharacterBody2D

var jugador: Node2D = null
var puede_atacar := true
var jugadores_en_area := []  # Lista de jugadores en el área
const DISTANCIA_ATAQUE := 30.0
const TIEMPO_ENTRE_ATAQUES := 1.0
const TIEMPO_ENTRE_EMPUJES := 0.3
const FUERZA_EMPUJE := 100.0  # Fuerza constante para el empuje

func _ready() -> void:
	# Buscar el jugador
	jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		jugador = get_tree().get_root().get_node_or_null("Nivel2/jugador")
	
	if jugador == null:
		printerr("Jugador no encontrado")
	else:
		print("Jugador encontrado: ", jugador.name)
	
	# Configurar DamageArea
	if has_node("DamageArea"):
		$DamageArea.body_entered.connect(_on_DamageArea_body_entered)
		$DamageArea.body_exited.connect(_on_DamageArea_body_exited)
	else:
		printerr("DamageArea no encontrada")
	
	# Configurar animación
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("idle")
	else:
		printerr("AnimatedSprite2D no encontrada")
	
	# Timer para empuje continuo
	var timer_empuje = Timer.new()
	timer_empuje.name = "TimerEmpuje"
	timer_empuje.wait_time = TIEMPO_ENTRE_EMPUJES
	timer_empuje.timeout.connect(_aplicar_empuje_continuo)
	add_child(timer_empuje)
	timer_empuje.start()

func _physics_process(_delta: float) -> void:
	if jugador == null:
		return
	
	if not is_instance_valid(jugador):
		jugador = get_tree().get_first_node_in_group("jugador")
		return
	
	var distancia := global_position.distance_to(jugador.global_position)
	var en_rango := distancia <= DISTANCIA_ATAQUE
	
	if en_rango:
		if puede_atacar:
			atacar()
		elif has_node("AnimatedSprite2D") and $AnimatedSprite2D.animation != "atacar":
			$AnimatedSprite2D.play("atacar")
	else:
		if has_node("AnimatedSprite2D") and $AnimatedSprite2D.animation != "idle":
			$AnimatedSprite2D.play("idle")

func atacar() -> void:
	if not has_node("AnimatedSprite2D"):
		return
	
	puede_atacar = false
	print("=== INICIANDO ATAQUE ===")
	
	if $AnimatedSprite2D.sprite_frames.has_animation("atacar"):
		$AnimatedSprite2D.play("atacar")
	else:
		printerr("Animación 'atacar' no encontrada")
		$AnimatedSprite2D.play("idle")
	
	# Cooldown para el próximo ataque
	await get_tree().create_timer(TIEMPO_ENTRE_ATAQUES).timeout
	puede_atacar = true
	print("=== ATAQUE DISPONIBLE ===")

func _on_DamageArea_body_entered(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name == "jugador") and not jugadores_en_area.has(body):
		jugadores_en_area.append(body)
		print("Jugador entró en área: ", body.name)

func _on_DamageArea_body_exited(body: Node) -> void:
	if (body.is_in_group("jugador") or body.name == "jugador") and jugadores_en_area.has(body):
		jugadores_en_area.erase(body)
		print("Jugador salió del área: ", body.name)

func _aplicar_empuje_continuo() -> void:
	if jugadores_en_area.is_empty():
		return
	
	print("=== APLICANDO EMPUJE CONTINUO ===")
	
	for jugador_body in jugadores_en_area:
		if not is_instance_valid(jugador_body):
			jugadores_en_area.erase(jugador_body)
			continue
		
		# Aplicar daño
		if jugador_body.has_method("bajar_vida"):
			jugador_body.bajar_vida(25)
		elif jugador_body.has_method("take_damage"):
			jugador_body.take_damage(25)
		
		# Aplicar empuje
		aplicar_empuje(jugador_body)

func aplicar_empuje(jugador_body: Node) -> void:
	var direccion_empuje = (jugador_body.global_position - global_position).normalized()
	
	if jugador_body is CharacterBody2D:
		# Para CharacterBody2D
		jugador_body.velocity = direccion_empuje * FUERZA_EMPUJE
		jugador_body.move_and_slide()  # Esto es esencial para que funcione
		print("Empuje aplicado (CharacterBody2D)")
	elif jugador_body is RigidBody2D:
		# Para RigidBody2D
		jugador_body.apply_central_impulse(direccion_empuje * FUERZA_EMPUJE)
		print("Empuje aplicado (RigidBody2D)")
	else:
		printerr("Tipo de cuerpo no compatible para empuje: ", jugador_body.get_class())
