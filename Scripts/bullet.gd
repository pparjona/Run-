# Bala.gd
extends CharacterBody3D

@export var speed: float = 100.0
@export var damage: int = 50

@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready() -> void:
	# La bala se autodestruye a los 5 segundos
	lifetime_timer.wait_time = 5.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()


func _physics_process(_delta: float) -> void:
	# Mover la bala SIEMPRE en su eje -Z local
	# (el Muzzle le dará la orientación correcta al instanciarla)
	velocity = -global_transform.basis.z * speed
	move_and_slide()

	# Si choca con algo, destrúyela y aplica daño si es enemigo
	if get_slide_collision_count() > 0:
		var collision := get_slide_collision(0)
		var collider := collision.get_collider()

		if collider != null:
			# 1) Collider directo en grupo Enemy con método apply_damage
			if collider.is_in_group("Enemy") and collider.has_method("apply_damage"):
				collider.apply_damage(damage)
			# 2) Collider hijo de un Enemy
			elif collider.get_parent() != null \
					and collider.get_parent().is_in_group("Enemy") \
					and collider.get_parent().has_method("apply_damage"):
				collider.get_parent().apply_damage(damage)

		queue_free()
