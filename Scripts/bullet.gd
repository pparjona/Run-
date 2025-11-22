extends CharacterBody3D

@export var speed: float = 40.0 
@export var base_damage: int = 50

@onready var lifetime_timer: Timer = $LifetimeTimer

func _ready() -> void:
	lifetime_timer.wait_time = 5.0
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()

func _physics_process(delta: float) -> void:
	# Mover la bala
	var collision = move_and_collide(-global_transform.basis.z * speed * delta)
	
	# Si hubo colisión...
	if collision:
		var collider = collision.get_collider()
		
		if collider:
			_handle_impact(collider)
		
		# Destruir la bala al chocar
		queue_free()

func _handle_impact(collider: Node):
	var damage_to_deal = base_damage
	var enemy_node = null

	# CASO 1: HEADSHOT (Golpe a la cabeza - StaticBody3D (Es static porque si no la bala no choca))
	if collider.is_in_group("head"):
		print("¡HEADSHOT!")
		damage_to_deal *= 2 # Doble daño
		
		# Truco: El "Dueño" (Owner) de la cabeza suele ser el nodo Raíz del Zombie
		# Si no funciona owner, usa collider.get_parent().get_parent()...
		enemy_node = collider.owner 
		
		# Si owner da null (a veces pasa con GLB importados), intentamos buscar hacia arriba
		if not enemy_node:
			enemy_node = collider.get_parent().get_parent() # Ajusta según tu jerarquía

	# CASO 2: BODYSHOT (Golpe al cuerpo normal - CharacterBody3D)
	elif collider.is_in_group("Enemy"):
		print("Impacto en cuerpo")
		enemy_node = collider

	# APLICAR DAÑO (Si encontramos al enemigo y tiene vida)
	if enemy_node and enemy_node.has_method("apply_damage"):
		enemy_node.apply_damage(damage_to_deal)
