extends CharacterBody3D

@export var move_speed: float = 1.7
@export var turn_speed: float = 8.0
@export var max_health: int = 1500
@export var damage: float = 30

# --- CONFIGURACIÓN DEL LOOT (MUNICIÓN) ---
@export var ammo_drop_scene: PackedScene
@export var ammo_boxes_to_drop: int = 5   # Cuántas cajas suelta al morir
@export var ammo_per_box_min: int = 5     # Balas mínimas por caja
@export var ammo_per_box_max: int = 15    # Balas máximas por caja

@onready var boss: Node3D = $Boss
@onready var area_3d: Area3D = $Area3D
@onready var timer: Timer = $Timer
@onready var animation_player: AnimationPlayer = $Boss/AnimationPlayer
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var attack_range: Area3D = $AttackRange

var current_health: int = 750
var target: CharacterBody3D = null
var is_attacking: bool = false
var is_hurting: bool = false



func _ready() -> void:
	if animation_player:
		animation_player.play("Idle", 0.2)



func set_target_and_maze(p_target: Node3D, _p_maze: Node) -> void:
	target = p_target



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if is_hurting or is_attacking:
		move_and_slide()
		return 

	if target == null:
		_handle_move_animation(Vector3.ZERO)
		move_and_slide()
		return
	
	_target_position(target)
	
	var nextLocation = navigation_agent_3d.get_next_path_position()
	var currentLocation = global_transform.origin
	var nextVelocity = (nextLocation - currentLocation).normalized() * move_speed
	var current_y_velocity = velocity.y
	velocity = velocity.move_toward(Vector3(nextVelocity.x, current_y_velocity, nextVelocity.z), 0.2)
	
	if not is_on_floor():
		velocity.y = current_y_velocity + (get_gravity().y * delta)
	
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() > 0.1:
		var look_target = global_position + horizontal_velocity
		look_target.y = global_position.y
		var current_transform = global_transform
		var target_transform = current_transform.looking_at(look_target, Vector3.UP)
		global_transform = current_transform.interpolate_with(target_transform, turn_speed * delta)
	
	_handle_move_animation(horizontal_velocity)
	
	move_and_slide()
	
	check_attack_range()


func _handle_move_animation(h_velocity: Vector3):
	if is_attacking or is_hurting:
		return
		
	if h_velocity.length() > 0.5:
		animation_player.play("Walk", 0.2)



func check_attack_range():
	if not timer.is_stopped():
		return

	for body in attack_range.get_overlapping_bodies():
		if body.is_in_group("Player"):
			perform_attack(body)
			return


# --- AQUÍ ESTÁ LA LÓGICA DE ATAQUE ALEATORIO ---
func perform_attack(target_body):
	if is_attacking or is_hurting: return
	
	is_attacking = true
	velocity = Vector3.ZERO 
	
	# Elegimos un número aleatorio entre 0 y 1
	var attack_type = randi() % 2 
	
	# Variable para saber cuánto esperar según el ataque
	var impact_time = 1.0 
	
	if attack_type == 0:
		# ATAQUE 1 (Ej: Golpe Fuerte)
		animation_player.play("Plunge Attack", 0.2) # Pon el nombre real aquí
		impact_time = 1.2 # Ajusta el tiempo de impacto de ESTE ataque
	else:
		# ATAQUE 2 (Ej: Golpe Rápido)
		animation_player.play("Rear Attack", 0.2) # Pon el nombre real aquí
		impact_time = 0.8 # Este ataque podría ser más rápido
	
	# Esperamos el tiempo definido arriba
	await get_tree().create_timer(impact_time).timeout
	
	# Comprobación de daño
	if target_body != null:
		var distancia = global_position.distance_to(target_body.global_position)
		
		# Aumenta un poco el rango para el Boss si es muy grande
		if distancia <= 5.0:
			if is_hurting:
				is_attacking = false 
				return 
			
			target_body.take_damage(damage)
	
	timer.start()
	
	await animation_player.animation_finished
	
	is_attacking = false
	animation_player.play("Idle", 0.2)



func _target_position(target):
	navigation_agent_3d.target_position = target.global_transform.origin



func apply_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()



# --- MODIFICADO: MUERTE Y BOTÍN ---
func die() -> void:
	# Bucle para soltar X cajas de munición
	for i in range(ammo_boxes_to_drop):
		spawn_ammo_box()
		
	queue_free()



func spawn_ammo_box() -> void:
	if ammo_drop_scene == null: return

	var pickup := ammo_drop_scene.instantiate()
	get_tree().current_scene.add_child(pickup)



	if pickup is Node3D:
		var pos := global_position
		
		# --- DISPERSIÓN ALEATORIA ---
		# Añadimos un pequeño desplazamiento aleatorio en X y Z
		# para que las cajas no caigan una encima de otra perfectamente apiladas.
		var random_offset_x = randf_range(-1.5, 1.5)
		var random_offset_z = randf_range(-1.5, 1.5)
		
		pos.x += random_offset_x
		pos.z += random_offset_z
		pos.y = 0.5 # Un poco elevado para que no atraviese el suelo
		
		pickup.global_position = pos
	
	# Cantidad aleatoria de balas dentro de ESTA caja
	var amount := randi_range(ammo_per_box_min, ammo_per_box_max)
	
	if pickup.has_method("set_ammo_amount"):
		pickup.set_ammo_amount(amount)
	elif "ammo_amount" in pickup:
		pickup.ammo_amount = amount



func _on_timer_timeout() -> void:
	pass
