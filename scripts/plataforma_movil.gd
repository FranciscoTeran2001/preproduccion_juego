extends AnimatableBody2D

# CONFIGURACIÓN DE MOVIMIENTO
@export var velocidad := 50.0  # Velocidad de movimiento
@export var distancia := 15.0  # Distancia total a recorrer
@export var direccion_inicial := Vector2.RIGHT  # Dirección inicial (RIGHT, LEFT, UP, DOWN)
@export var pausa_en_extremos := 0.5  # Segundos de pausa al llegar a los extremos
@export var auto_iniciar := true  # Si inicia automáticamente

# CONFIGURACIÓN AVANZADA
@export var tipo_movimiento: TipoMovimiento = TipoMovimiento.LINEAL
@export var detectar_jugador := false  # Si debe activarse solo cuando el jugador esté cerca

enum TipoMovimiento {
	LINEAL,      # Movimiento constante
	SUAVE,       # Movimiento con curvas suaves
	ELASTICO     # Movimiento con rebote
}

# VARIABLES INTERNAS
var posicion_inicial: Vector2
var posicion_final: Vector2
var esta_moviendo := false
var direccion_actual := 1  # 1 = hacia adelante, -1 = hacia atrás
var esta_pausado := false
var jugador_encima := false

# NODOS

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	print("=== PLATAFORMA MÓVIL INICIALIZADA ===")
	
	# Configurar posiciones inicial y final
	configurar_posiciones()
	

	
	# Iniciar movimiento si está configurado
	if auto_iniciar:
		iniciar_movimiento()
	
	print("Posición inicial: ", posicion_inicial)
	print("Posición final: ", posicion_final)
	print("Distancia: ", distancia)

func configurar_posiciones() -> void:
	posicion_inicial = global_position
	
	# Calcular posición final según dirección y distancia
	var offset = direccion_inicial.normalized() * distancia
	posicion_final = posicion_inicial + offset
	
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
			movimiento_lineal()
		TipoMovimiento.SUAVE:
			movimiento_suave()
		TipoMovimiento.ELASTICO:
			movimiento_elastico()

func detener_movimiento() -> void:
	esta_moviendo = false
	print("⏹️ Movimiento de plataforma detenido")

# MOVIMIENTO LINEAL (Constante)
func movimiento_lineal() -> void:
	while esta_moviendo:
		# Determinar objetivo actual
		var objetivo = posicion_final if direccion_actual == 1 else posicion_inicial
		
		# Mover hacia el objetivo
		while global_position.distance_to(objetivo) > 2.0 and esta_moviendo:
			var direccion_movimiento = (objetivo - global_position).normalized()
			global_position += direccion_movimiento * velocidad * get_process_delta_time()
			await get_tree().process_frame
		
		# Ajustar posición exacta
		global_position = objetivo
		
		# Cambiar dirección
		direccion_actual *= -1
		
		# Pausa en los extremos
		if pausa_en_extremos > 0:
			esta_pausado = true
			await get_tree().create_timer(pausa_en_extremos).timeout
			esta_pausado = false
		
		# Si solo debe moverse cuando el jugador está cerca
		if detectar_jugador and not jugador_encima:
			esta_moviendo = false
			break

# MOVIMIENTO SUAVE (Con Tween)
func movimiento_suave() -> void:
	while esta_moviendo:
		var objetivo = posicion_final if direccion_actual == 1 else posicion_inicial
		var distancia_objetivo = global_position.distance_to(objetivo)
		var tiempo_movimiento = distancia_objetivo / velocidad
		
		# Crear tween para movimiento suave
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_SINE)
		
		# Animar hacia el objetivo
		tween.tween_property(self, "global_position", objetivo, tiempo_movimiento)
		await tween.finished
		
		# Cambiar dirección
		direccion_actual *= -1
		
		# Pausa
		if pausa_en_extremos > 0:
			await get_tree().create_timer(pausa_en_extremos).timeout
		
		if detectar_jugador and not jugador_encima:
			break

# MOVIMIENTO ELÁSTICO (Con rebote)
func movimiento_elastico() -> void:
	while esta_moviendo:
		var objetivo = posicion_final if direccion_actual == 1 else posicion_inicial
		var distancia_objetivo = global_position.distance_to(objetivo)
		var tiempo_movimiento = distancia_objetivo / velocidad
		
		# Crear tween con efecto elástico
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_ELASTIC)
		
		tween.tween_property(self, "global_position", objetivo, tiempo_movimiento)
		await tween.finished
		
		direccion_actual *= -1
		
		if pausa_en_extremos > 0:
			await get_tree().create_timer(pausa_en_extremos).timeout
		
		if detectar_jugador and not jugador_encima:
			break

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
			await get_tree().create_timer(2.0).timeout  # Esperar 2 segundos
			if not jugador_encima:
				detener_movimiento()

# FUNCIONES DE CONTROL EXTERNO
func cambiar_velocidad(nueva_velocidad: float) -> void:
	velocidad = nueva_velocidad
	print("⚡ Velocidad cambiada a: ", velocidad)

func cambiar_direccion() -> void:
	direccion_actual *= -1
	print("🔄 Dirección invertida")

func ir_a_posicion_inicial() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicion_inicial, 1.0)
	await tween.finished
	direccion_actual = 1
	print("🏠 Plataforma regresada a posición inicial")

func ir_a_posicion_final() -> void:
	var tween = create_tween()
	tween.tween_property(self, "global_position", posicion_final, 1.0)
	await tween.finished
	direccion_actual = -1
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
