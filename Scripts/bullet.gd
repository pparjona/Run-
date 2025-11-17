# Bala.gd
extends CharacterBody3D

# Velocidad de la bala
@export var speed = 50.0
# Dirección en la que volará (se la daremos desde el jugador)
var direction = Vector3.FORWARD

func _ready():
	# Configura el timer para que dure 5 segundos, se ejecute una vez y llame
	# a la función 'queue_free' (borrarse a sí mismo) cuando termine.
	$LifetimeTimer.wait_time = 5.0
	$LifetimeTimer.one_shot = true
	$LifetimeTimer.timeout.connect(queue_free)
	$LifetimeTimer.start()

func _physics_process(delta):
	# Mueve la bala hacia adelante
	velocity = direction * speed
	move_and_slide()
	
	# Si choca con algo, destrúyela
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		
		# ---- ¡PARA EL FUTURO! ----
		# Cuando tengas monstruos, puedes hacer esto:
		# if collision.get_collider().is_in_group("Monstruos"):
		#     collision.get_collider().take_damage(10) # Llama a una función en el monstruo
		# -------------------------
		
		# Destruye la bala al impactar
		queue_free()
