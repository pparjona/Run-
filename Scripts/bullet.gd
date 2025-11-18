# Bala.gd
extends CharacterBody3D

# Velocidad de la bala
@export var speed = 50.0
@export var damage: int = 50
# Dirección en la que volará (se la daremos desde el jugador)
var direction = Vector3.FORWARD

@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready():
	# Configura el timer para que dure 5 segundos, se ejecute una vez y llame
	# a la función 'queue_free' (borrarse a sí mismo) cuando termine.
	lifetime_timer.wait_time = 5.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()

func _physics_process(_delta : float):
	# Mueve la bala hacia adelante
	velocity = direction * speed
	move_and_slide()
	
	# Si choca con algo, destrúyela
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var collider := collision.get_collider()

		if collider != null:
			# 1) Collider directo en grupo Enemy con método apply_damage
			if collider.is_in_group("Enemy") and collider.has_method("apply_damage"):
				collider.apply_damage(damage)
			# 2) Collider hijo de un Enemy por si choca con algo del padre
			elif collider.get_parent() != null \
					and collider.get_parent().is_in_group("Enemy") \
					and collider.get_parent().has_method("apply_damage"):
				collider.get_parent().apply_damage(damage)

		# Siempre destruimos la bala al impactar
		queue_free()
