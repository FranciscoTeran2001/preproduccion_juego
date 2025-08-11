extends CharacterBody2D

# Estados del enemigo
enum State {
	PATROL,
	CHASE,
	ATTACK,
	DEAD
}

# Variables de configuración
@export var patrol_speed: float = 20.0
@export var chase_speed: float = 80.0
@export var patrol_distance: float = 100.0
@export var detection_radius: float = 80.0
@export var attack_radius: float = 20.0
@export var attack_damage: int = 10
@export var health: int = 100

# Variables de estado
var current_state: State = State.PATROL
var player: CharacterBody2D = null
var patrol_direction: int = 1  # 1 para derecha, -1 para izquierda
var patrol_start_position: Vector2
var can_attack: bool = true
var attack_cooldown: float = 1.5
var attack_timer: float = 0.0

# Referencias a nodos
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea

func _ready():
	# Guardar posición inicial para patrullaje
	patrol_start_position = global_position
	
	# Conectar señales si no están conectadas
	if not damage_area.body_entered.is_connected(_on_damage_area_body_entered):
		damage_area.body_entered.connect(_on_damage_area_body_entered)
	if not damage_area.body_exited.is_connected(_on_damage_area_body_exited):
		damage_area.body_exited.connect(_on_damage_area_body_exited)

func _physics_process(delta):
	if current_state == State.DEAD:
		return
	
	# Actualizar timer de ataque
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			can_attack = true
	
	# Lógica de estados
	match current_state:
		State.PATROL:
			patrol_behavior()
		State.CHASE:
			chase_behavior()
		State.ATTACK:
			attack_behavior()
	
	# Aplicar movimiento
	move_and_slide()
	
	# Actualizar dirección del sprite
	update_sprite_direction()

func patrol_behavior():
	# Cambiar a animación de caminar
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
	
	# Movimiento de patrullaje
	velocity.x = patrol_direction * patrol_speed
	
	# Verificar si debe cambiar dirección
	var distance_from_start = global_position.x - patrol_start_position.x
	
	if abs(distance_from_start) >= patrol_distance:
		patrol_direction *= -1
	
	# Verificar colisiones con paredes
	if is_on_wall():
		patrol_direction *= -1
	
	# Verificar si el jugador está cerca
	if player and player_in_detection_radius():
		change_state(State.CHASE)

func chase_behavior():
	if not player:
		change_state(State.PATROL)
		return
	
	# Cambiar a animación de caminar (más rápida)
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")
	
	# Perseguir al jugador
	var direction_to_player = (player.global_position - global_position).normalized()
	velocity.x = direction_to_player.x * chase_speed
	
	# Verificar si está cerca para atacar
	if player_in_attack_radius() and can_attack:
		change_state(State.ATTACK)
	
	# Verificar si perdió al jugador
	if not player_in_detection_radius():
		change_state(State.PATROL)

func attack_behavior():
	# Detener movimiento durante ataque
	velocity.x = 0
	
	# Cambiar a animación de ataque
	if animated_sprite.animation != "atacar":
		animated_sprite.play("atacar")
		can_attack = false
		attack_timer = attack_cooldown
		
		# Hacer daño al jugador si está en rango
		if player and player_in_attack_radius():
			damage_player()
	
	# Verificar si la animación de ataque terminó
	if animated_sprite.animation == "atacar" and not animated_sprite.is_playing():
		if player and player_in_attack_radius():
			# Seguir atacando si el jugador sigue cerca
			change_state(State.ATTACK)
		elif player and player_in_detection_radius():
			# Volver a perseguir
			change_state(State.CHASE)
		else:
			# Volver a patrullar
			change_state(State.PATROL)

func change_state(new_state: State):
	current_state = new_state
	
	# Lógica especial al cambiar de estado
	match new_state:
		State.PATROL:
			# Cambiar a idle momentáneamente
			animated_sprite.play("idle")
		State.CHASE:
			# Inmediatamente cambiar a walk
			animated_sprite.play("walk")
		State.ATTACK:
			# Se maneja en attack_behavior()
			pass
		State.DEAD:
			animated_sprite.play("dead")
			velocity = Vector2.ZERO

func player_in_detection_radius() -> bool:
	if not player:
		return false
	return global_position.distance_to(player.global_position) <= detection_radius

func player_in_attack_radius() -> bool:
	if not player:
		return false
	return global_position.distance_to(player.global_position) <= attack_radius

func damage_player():
	# Aquí puedes implementar la lógica de daño al jugador
	print("¡Enemigo ataca al jugador! Daño: ", attack_damage)
	
	# Si el jugador tiene un método take_damage, úsalo
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

func take_damage(amount: int):
	health -= amount
	
	if health <= 0:
		die()
	else:
		# Animación de daño si existe
		if animated_sprite.sprite_frames.has_animation("hurt"):
			animated_sprite.play("hurt")

func die():
	current_state = State.DEAD
	animated_sprite.play("dead")
	# Opcional: desactivar colisiones
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)

func update_sprite_direction():
	# Voltear sprite según la dirección del movimiento
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

# Señales del DamageArea
func _on_damage_area_body_entered(body):
	if body.name == "Player" or body.is_in_group("player"):
		player = body

func _on_damage_area_body_exited(body):
	if body == player:
		player = null
