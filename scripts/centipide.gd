extends CharacterBody2D

var vida := 50  # 2 balas para morir
var esta_muerto := false

func _ready() -> void:
	add_to_group("enemigos")
	if has_node("centipide"):
		$centipide.play("centipide_inactivo")

func recibir_daño(cantidad: int) -> void:
	if esta_muerto:
		return
	
	vida -= cantidad
	print("Centipede recibió ", cantidad, " de daño. Vida: ", vida)
	
	# Efecto de daño
	if has_node("centipide"):
		$centipide.play("centipide_hurt")
		await get_tree().create_timer(0.5).timeout
	
	if vida <= 0:
		morir()
	else:
		$centipide.play("centipide_inactivo")

func morir() -> void:
	if esta_muerto:
		return
	esta_muerto = true
	
	if has_node("centipide"):
		$centipide.play("centipide_muerte")
		await $centipide.animation_finished
	
	queue_free()
