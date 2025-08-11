extends CharacterBody2D

var vida := 150  # 6 balas para morir (jefe resistente)
var esta_muerto := false

func _ready() -> void:
	add_to_group("enemigos")
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("inactivo")

func recibir_daño(cantidad: int) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("Jefe recibió ", cantidad, " de daño. Vida: ", vida)
	
	# Efecto de daño
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("daño_jefe1")
		await get_tree().create_timer(0.7).timeout
	
	if vida <= 0:
		morir()
	else:
		$AnimatedSprite2D.play("inactivo")

func morir() -> void:
	if esta_muerto:
		return
	esta_muerto = true
	
	print("¡JEFE DERROTADO!")
	
	if has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.play("muerte_jefe1")
		await $AnimatedSprite2D.animation_finished
	
	queue_free()
