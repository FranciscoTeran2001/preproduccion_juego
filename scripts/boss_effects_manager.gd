# scripts/boss_effects_manager.gd
extends Node2D

@onready var rage_particles = get_node_or_null("RageParticles")
@onready var charge_particles = get_node_or_null("ChargeParticles")
@onready var explosion_effect = get_node_or_null("AreaAttackEffect/ExplosionEffect")

func _ready():
	print("✨ Effects Manager iniciado")

func trigger_effect(effect_name: String):
	print("🎨 Efecto activado: ", effect_name)
	
	match effect_name:
		"rage":
			if rage_particles:
				rage_particles.emitting = true
				rage_particles.restart()
		"charge":
			if charge_particles:
				charge_particles.emitting = true
				charge_particles.restart()
		"explosion":
			if explosion_effect:
				explosion_effect.emitting = true
				explosion_effect.restart()
