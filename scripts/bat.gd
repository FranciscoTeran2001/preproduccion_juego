extends CharacterBody2D

@export var speed: float = 80.0
@export var detection_range: float = 250.0
@export var damage: float = 10.0
@export var knockback_force: float = 250.0

enum State { CHASING, RETREATING }
var current_state = State.CHASING

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_area: Area2D = $DamageArea

var player: Node2D = null
var chase_timer: Timer
var retreat_timer: Timer

func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING

	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("⚠️ No se encontró jugador con grupo 'player'")

	sprite.play("attack")

	chase_timer = Timer.new()
	chase_timer.wait_time = 3.0
	chase_timer.one_shot = true
	chase_timer.timeout.connect(_start_retreating)
	add_child(chase_timer)

	retreat_timer = Timer.new()
	retreat_timer.wait_time = 1.5
	retreat_timer.one_shot = true
	retreat_timer.timeout.connect(_start_chasing)
	add_child(retreat_timer)

	damage_area.body_entered.connect(_on_damage_area_body_entered)

	_start_chasing()

func _physics_process(delta: float) -> void:
	if not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detection_range:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction: Vector2

	if current_state == State.CHASING:
		direction = (player.global_position - global_position).normalized()
	else:
		direction = (global_position - player.global_position).normalized()

	velocity = direction * speed
	move_and_slide()

	if velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _start_chasing() -> void:
	current_state = State.CHASING
	chase_timer.start()

func _start_retreating() -> void:
	current_state = State.RETREATING
	retreat_timer.start()

func _on_damage_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			var knockback_dir = (body.global_position - global_position).normalized()
			body.take_damage(damage, knockback_dir * knockback_force)

func take_damage(amount: float, knockback_vector: Vector2 = Vector2.ZERO):
	print("Murciélago recibió daño y murió.")
	queue_free()
