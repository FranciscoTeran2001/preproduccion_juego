extends AnimatableBody2D

# CONFIGURACIÓN DE MOVIMIENTO
@export var velocidad := 50.0
@export var distancia := 15.0
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
var tween_movimiento: Tween

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
	
	print("Posición inicial: ", posicion_inicial)
	print("Posición final: ", posicion_final)
	print("Distancia: ", distancia)

func configurar_posiciones() -> void:
	posicion_inicial = global_position
	var offset = direccion_inicial.normalized() * distancia
	posicion_final = posicion_inicial + offset
	objetivo_actual = posicion_final
	
	print("📍 Configurando movimiento:")
	print("  - Desde: ", posicion_inicial)
	print("  - Hasta: ", posicion_final)
	print("  - Dirección: ", direccion_inicial)

func iniciar_movimiento() -> void:
	if esta_moviendo:
		return
	
	esta_moviendo = true
	print("🚀 Iniciando movimiento de plataforma")
	
	match tipo_movimiento:
		TipoMovimiento.LINEAL:
			_iniciar_movimiento_lineal()
		TipoMovimiento.SUAVE:
			_iniciar_movimiento_suave()
		TipoMovimiento.ELASTICO:
			_iniciar_movimiento_elastico()

func detener_movimiento() -> void:
	esta_moviendo = false
	if tween_movimiento:
		tween_movimiento.kill()
	print("⏹️ Movimiento de plataforma detenido")

# MOVIMIENTO LINEAL usando _physics_process
func _physics_process(delta: float) -> void:
	if not esta_moviendo or esta_pausado or tipo_movimiento != TipoMovimiento.LINEAL:
		return
	
	_procesar_movimiento_lineal(delta)

func _iniciar_movimiento_lineal() -> void:
	objetivo_actual = posicion_final if direccion_actual == 1 else posicion_inicial

func _procesar_movimiento_lineal(delta: float) -> void:
	var distancia_objetivo = global_position.distance_to(objetivo_actual)
	
	# Si llegamos al objetivo
	if distancia_objetivo < 2.0:
		global_position = objetivo_actual
		_cambiar_objetivo_lineal()
		return
	
	# Mover hacia el objetivo
	var direccion_movimiento = (objetivo_actual - global_position).normalized()
	global_position += direccion_movimiento * velocidad * delta

func _cambiar_objetivo_lineal() -> void:
	# Cambiar dirección
	direccion_actual *= -1
	objetivo_actual = posicion_final if direccion_actual == 1 else posicion_inicial
	
	# Aplicar pausa
	if pausa_en_extremos > 0:
		esta_pausado = true
		timer_pausa.wait_time = pausa_en_extremos
		timer_pausa.start()
	
	# Verificar si debe seguir moviéndose
	if detectar_jugador and not jugador_encima:
		detener_movimiento()

# MOVIMIENTO SUAVE usando Tween
func _iniciar_movimiento_suave() -> void:
	_ejecutar_movimiento_suave()

func _ejecutar_movimiento_suave() -> void:
	if not esta_moviendo:
		return
	
	var objetivo = posicion_final if direccion_actual == 1 else posicion_inicial
	var distancia_objetivo = global_position.distance_to(objetivo)
	var tiempo_movimiento = distancia_objetivo / velocidad
	
	# Crear tween para movimiento suave
	tween_movimiento = create_tween()
	tween_movimiento.set_ease(Tween.EASE_IN_OUT)
	tween_movimiento.set_trans(Tween.TRANS_SINE)
	
	# Animar hacia el objetivo
	tween_movimiento.tween_property(self, "global_position", objetivo, tiempo_movimiento)
	await tween_movimiento.finished
	
	if not esta_moviendo:
		return
	
	# Cambiar dirección
	direccion_actual *= -1
	
	# Pausa
	if pausa_en_extremos > 0:
		esta_pausado = true
		timer_pausa.wait_time = pausa_en_extremos
		timer_pausa.start()
		await timer_pausa.timeout
		esta_pausado = false
	
	# Verificar si debe continuar
	if detectar_jugador and not jugador_encima:
		detener_movimiento()
		return
	
	# Continuar el movimiento
	_ejecutar_movimiento_suave()

# MOVIMIENTO ELÁSTICO usando Tween
func _iniciar_movimiento_elastico() -> void:
	_ejecutar_movimiento_elastico()

func _ejecutar_movimiento_elastico() -> void:
	if not esta_moviendo:
		return
	
	var objetivo = posicion_final if direccion_actual == 1 else posicion_inicial
	var distancia_objetivo = global_position.distance_to(objetivo)
	var tiempo_movimiento = distancia_objetivo / velocidad
	
	# Crear tween con efecto elástico
	tween_movimiento = create_tween()
	tween_movimiento.set_ease(Tween.EASE_OUT)
	tween_movimiento.set_trans(Tween.TRANS_ELASTIC)
	
	tween_movimiento.tween_property(self, "global_position", objetivo, tiempo_movimiento)
	await tween_movimiento.finished
	
	if not esta_moviendo:
		return
	
	direccion_actual *= -1
	
	if pausa_en_extremos > 0:
		esta_pausado = true
		timer_pausa.wait_time = pausa_en_extremos
		timer_pausa.start()
		await timer_pausa.timeout
		esta_pausado = false
	
	if detectar_jugador and not jugador_encima:
		detener_movimiento()
		return
	
	# Continuar el movimiento
	_ejecutar_movimiento_elastico()

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
		
		# Opcional: detener después de un delay
		if detectar_jugador:
			await get_tree().create_timer(2.0).timeout
			if not jugador_encima:
				detener_movimiento()

# FUNCIONES DE CONTROL EXTERNO
func cambiar_velocidad(nueva_velocidad: float) -> void:
	velocidad = nueva_velocidad
	print("⚡ Velocidad cambiada a: ", velocidad)

func cambiar_direccion() -> void:
	direccion_actual *= -1
	objetivo_actual = posicion_final if direccion_actual == 1 else posicion_inicial
	print("🔄 Dirección invertida")

func ir_a_posicion_inicial() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicion_inicial, 1.0)
	await tween.finished
	direccion_actual = 1
	objetivo_actual = posicion_final
	print("🏠 Plataforma regresada a posición inicial")

func ir_a_posicion_final() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicion_final, 1.0)
	await tween.finished
	direccion_actual = -1
	objetivo_actual = posicion_inicial
	print("🎯 Plataforma movida a posición final")

# FUNCIONES DE DEBUG
func mostrar_info() -> void:
	print("=== INFO DE PLATAFORMA ===")
	print("Posición actual: ", global_position)
	print("Está moviendo: ", esta_moviendo)
	print("Dirección actual: ", direccion_actual)
	print("Jugador encima: ", jugador_encima)
	print("Está pausado: ", esta_pausado)

func _input(event: InputEvent) -> void:
	# Debug controls (opcional)
	if event.is_action_pressed("ui_accept"):  # Barra espaciadora
		if esta_moviendo:
			detener_movimiento()
		else:
			iniciar_movimiento()
	
	if event.is_action_pressed("ui_up"):
		mostrar_info()
