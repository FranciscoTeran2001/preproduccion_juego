extends AnimatableBody2D

# CONFIGURACIÓN DE MOVIMIENTO
@export var velocidad := 50.0
@export var distancia := -15.0
@export var direccion_inicial := Vector2.RIGHT
@export var pausa_en_extremos := 0.5
@export var auto_iniciar := true

# CONFIGURACIÓN AVANZADA
@export var tipo_movimiento: TipoMovimiento = TipoMovimiento.LINEAL
@export var detectar_jugador := false

enum TipoMovimiento {
	LINEAL,
	SUAVE,
	ELASTICO
}

# VARIABLES INTERNAS
var posicion_inicial: Vector2
var posicion_final: Vector2
var esta_moviendo := false
var direccion_actual := 1
var esta_pausado := false
var jugador_encima := false
var objetivo_actual: Vector2
var timer_pausa: Timer

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	print("=== PLATAFORMA MÓVIL INICIALIZADA ===")
	
	# Crear timer para pausas
	timer_pausa = Timer.new()
	timer_pausa.wait_time = pausa_en_extremos
	timer_pausa.one_shot = true
	timer_pausa.timeout.connect(_on_pausa_terminada)
	add_child(timer_pausa)
	
	# Configurar posiciones
	configurar_posiciones()
	
	# Iniciar movimiento
	if auto_iniciar:
		iniciar_movimiento()

func configurar_posiciones() -> void:
	posicion_inicial = global_position
	var offset = direccion_inicial.normalized() * distancia
	posicion_final = posicion_inicial + offset
	objetivo_actual = posicion_final

func iniciar_movimiento() -> void:
	if esta_moviendo:
		return
	
	esta_moviendo = true
	print("🚀 Iniciando movimiento de plataforma")

func detener_movimiento() -> void:
	esta_moviendo = false
	print("⏹️ Movimiento detenido")

func _physics_process(delta: float) -> void:
	if not esta_moviendo or esta_pausado:
		return
	
	match tipo_movimiento:
		TipoMovimiento.LINEAL:
			_movimiento_lineal_physics(delta)
		TipoMovimiento.SUAVE:
			_movimiento_suave_physics(delta)
		TipoMovimiento.ELASTICO:
			_movimiento_elastico_physics(delta)

func _movimiento_lineal_physics(delta: float) -> void:
	# Calcular distancia al objetivo
	var distancia_objetivo = global_position.distance_to(objetivo_actual)
	
	# Si llegamos al objetivo
	if distancia_objetivo < 2.0:
		global_position = objetivo_actual
		_cambiar_objetivo()
		return
	
	# Mover hacia el objetivo
	var direccion_movimiento = (objetivo_actual - global_position).normalized()
	global_position += direccion_movimiento * velocidad * delta

func _movimiento_suave_physics(delta: float) -> void:
	# Implementación similar pero con interpolación suave
	var distancia_objetivo = global_position.distance_to(objetivo_actual)
	
	if distancia_objetivo < 2.0:
		global_position = objetivo_actual
		_cambiar_objetivo()
		return
	
	# Movimiento suave usando lerp
	var factor_suavizado = min(velocidad * delta / distancia_objetivo, 1.0)
	global_position = global_position.lerp(objetivo_actual, factor_suavizado)

func _movimiento_elastico_physics(delta: float) -> void:
	# Usar tween para movimiento elástico
	if not esta_moviendo:
		return
		
	var distancia_objetivo = global_position.distance_to(objetivo_actual)
	
	if distancia_objetivo < 2.0:
		global_position = objetivo_actual
		_cambiar_objetivo_con_elastico()

func _cambiar_objetivo() -> void:
	# Cambiar dirección
	direccion_actual *= -1
	objetivo_actual = posicion_final if direccion_actual == 1 else posicion_inicial
	
	# Aplicar pausa si está configurada
	if pausa_en_extremos > 0:
		esta_pausado = true
		timer_pausa.start()
	
	# Verificar si debe seguir moviéndose
	if detectar_jugador and not jugador_encima:
		detener_movimiento()

func _cambiar_objetivo_con_elastico() -> void:
	direccion_actual *= -1
	var nuevo_objetivo = posicion_final if direccion_actual == 1 else posicion_inicial
	
	# Crear tween elástico
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	
	var tiempo = global_position.distance_to(nuevo_objetivo) / velocidad
	tween.tween_property(self, "global_position", nuevo_objetivo, tiempo)
	
	await tween.finished
	objetivo_actual = nuevo_objetivo
	
	if pausa_en_extremos > 0:
		esta_pausado = true
		timer_pausa.start()

func _on_pausa_terminada() -> void:
	esta_pausado = false

# DETECCIÓN DE JUGADOR
func _on_jugador_entro(body: Node) -> void:
	if body.is_in_group("jugador"):
		jugador_encima = true
		print("👤 Jugador subió a la plataforma")
		
		if detectar_jugador and not esta_moviendo:
			iniciar_movimiento()

func _on_jugador_salio(body: Node) -> void:
	if body.is_in_group("jugador"):
		jugador_encima = false
		print("👤 Jugador bajó de la plataforma")

# FUNCIONES DE CONTROL
func cambiar_velocidad(nueva_velocidad: float) -> void:
	velocidad = nueva_velocidad

func cambiar_direccion() -> void:
	direccion_actual *= -1
	objetivo_actual = posicion_final if direccion_actual == 1 else posicion_inicial

func ir_a_posicion_inicial() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicion_inicial, 1.0)
	await tween.finished
	direccion_actual = 1
	objetivo_actual = posicion_final

func ir_a_posicion_final() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicion_final, 1.0)
	await tween.finished
	direccion_actual = -1
	objetivo_actual = posicion_inicial
