extends CharacterBody2D

# --- Variables del Jefe (Editables desde el Inspector) ---
@export var vida_maxima: int = 500
@export var velocidad_movimiento: float = 60.0
@export var rango_persecucion: float = 300.0 # Distancia para empezar a perseguir
@export var rango_ataque: float = 70.0      # Distancia para detenerse y atacar
@export var dano_por_contacto: int = 25
@export var fuerza_empuje: float = 250.0

# --- Variables Internas ---
var vida_actual: int
var esta_muerto := false
var puede_atacar := true
var jugador: CharacterBody2D = null
var estado_actual: String = "idle" # Estados: idle, walk, attack, hurt, dead

# --- Nodos (para no escribir "$" a cada rato) ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea


func _ready() -> void:
	vida_actual = vida_maxima
	
	# Busca al jugador
	jugador = get_tree().get_first_node_in_group("jugador")
	if not is_instance_valid(jugador):
		printerr("Jefe: No se encontró al jugador. El jefe se desactivará.")
		set_physics_process(false) # Desactiva el jefe si no hay jugador
		return
	
	# Conecta las señales (IMPORTANTE)
	damage_area.body_entered.connect(_on_DamageArea_body_entered)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	
	cambiar_estado("idle")


func _physics_process(_delta: float) -> void:
	# El jefe no hace nada si está muerto, herido o atacando
	if estado_actual in ["hurt", "attack", "dead"]:
		# Mantenemos una pequeña gravedad para que no flote si está en el aire
		if not is_on_floor():
			velocity.y += 980 * _delta
		move_and_slide()
		return
		
	if not is_instance_valid(jugador):
		cambiar_estado("idle")
		return

	# --- LÓGICA DE DECISIÓN (IA) ---
	var distancia_al_jugador = global_position.distance_to(jugador.global_position)
	
	if distancia_al_jugador <= rango_ataque:
		cambiar_estado("attack")
	elif distancia_al_jugador <= rango_persecucion:
		cambiar_estado("walk")
	else:
		cambiar_estado("idle")

	# --- EJECUCIÓN DEL ESTADO ---
	match estado_actual:
		"idle":
			velocity.x = move_toward(velocity.x, 0, velocidad_movimiento)
		"walk":
			perseguir_jugador()
	
	# Voltear el sprite para que siempre mire al jugador
	if abs(jugador.global_position.x - global_position.x) > 1.0:
		animated_sprite.flip_h = jugador.global_position.x < global_position.x
		
	# Mantenemos una pequeña gravedad para que no flote si está en el aire
	if not is_on_floor():
		velocity.y += 980 * _delta

	move_and_slide()

# --- MÁQUINA DE ESTADOS ---
func cambiar_estado(nuevo_estado: String):
	if estado_actual == nuevo_estado or esta_muerto:
		return
	
	estado_actual = nuevo_estado
	
	match estado_actual:
		"idle":
			animated_sprite.play("idle")
		"walk":
			animated_sprite.play("walk")
		"attack":
			atacar()
		"hurt":
			animated_sprite.play("hurt")
		"dead":
			morir()

# --- ACCIONES ---
func perseguir_jugador():
	if not is_instance_valid(jugador):
		return
	var direccion = global_position.direction_to(jugador.global_position)
	velocity.x = direccion.x * velocidad_movimiento

func atacar():
	if not puede_atacar or esta_muerto:
		return
	
	puede_atacar = false
	velocity = Vector2.ZERO # Se detiene para atacar
	animated_sprite.play("attack")
	# El daño se hará a través del hitbox del ataque o con el DamageArea

func recibir_dano(cantidad: int) -> void:
	if esta_muerto or estado_actual == "hurt":
		return
		
	vida_actual -= cantidad
	print("Vida del jefe: ", vida_actual, "/", vida_maxima)
	
	if vida_actual <= 0:
		cambiar_estado("dead")
	else:
		cambiar_estado("hurt")

func morir():
	esta_muerto = true
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	damage_area.get_node("CollisionShape2D").set_deferred("disabled", true)
	
	if animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
	else:
		queue_free()

# --- MANEJO DE SEÑALES ---
func _on_animation_finished() -> void:
	var anim_name = animated_sprite.animation
	
	if anim_name == "attack":
		estado_actual = "idle" # Vuelve a un estado neutral
		await get_tree().create_timer(0.5).timeout # Pequeño cooldown
		puede_atacar = true
			
	if anim_name == "hurt":
		estado_actual = "idle" # Vuelve a un estado neutral
		
	if anim_name == "death":
		queue_free()

# --- ÁREA DE DAÑO (Para daño por contacto) ---
func _on_DamageArea_body_entered(body: Node) -> void:
	if body.is_in_group("jugador"):
		if body.has_method("bajar_vida"):
			body.bajar_vida(dano_por_contacto)
			aplicar_empuje(body)

func aplicar_empuje(jugador_body: CharacterBody2D) -> void:
	var direccion_empuje = (jugador_body.global_position - global_position).normalized()
	jugador_body.velocity = direccion_empuje * fuerza_empuje
	jugador_body.move_and_slide()
