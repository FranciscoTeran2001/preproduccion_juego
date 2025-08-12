extends CharacterBody2D

@export var distancia = 10
@export var velocidad = 18

var direccion = 1
var posicion_inicial

func _ready():
	posicion_inicial = position

func _process(delta):
	position.x += velocidad * delta * direccion

	if abs(position.x - posicion_inicial.x) >= distancia:
		direccion *= -1
