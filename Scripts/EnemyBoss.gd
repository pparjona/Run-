extends CharacterBody3D

@export var move_speed: float = 1.8
@export var turn_speed: float = 8.0
@export var max_health: int = 750
var current_health: int = 750

@export var ammo_drop_scene: PackedScene
@export var ammo_drop_chance: float = 0.4
@export var ammo_drop_min: int = 5
@export var ammo_drop_max: int = 15

@export var damage: float = 33

@onready var boss: Node3D = $Boss
@onready var area_3d: Area3D = $Area3D
@onready var timer: Timer = $Timer
# Asegúrate de que la ruta al AnimationPlayer sea correcta
@onready var animation_player: AnimationPlayer = $Boss/AnimationPlayer


@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
var target: CharacterBody3D = null

var is_attacking: bool = false
var is_hurting: bool = false


func _ready() -> void:
	# Iniciamos con Idle
	if animation_player:
		animation_player.play("Idle", 0.2)
	else:
		print("ERROR: No encuentro el AnimationPlayer")

func set_target_and_maze(p_target: Node3D, _p_maze: Node) -> void:
	target = p_target

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# --- BLOQUEO DE ACCIONES ---
	# Si está recibiendo daño o atacando, no calculamos movimiento
	# para que no deslice por el suelo mientras hace la animación.
	if is_hurting or is_attacking:
		move_and_slide() # Mantiene la gravedad pero no avanza
		return 
	# ---------------------------

	if target == null:
		_handle_move_animation(Vector3.ZERO) # Si no hay target, ponemos idle
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
	
	# Rotación hacia el objetivo
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	if horizontal_velocity.length() > 0.1:
		var look_target = global_position + horizontal_velocity
		look_target.y = global_position.y
		var current_transform = global_transform
		var target_transform = current_transform.looking_at(look_target, Vector3.UP)
		global_transform = current_transform.interpolate_with(target_transform, turn_speed * delta)
	
	# Gestionar animación de caminar/quieto
	_handle_move_animation(horizontal_velocity)
	
	move_and_slide()
	
	# Lógica de ataque
	check_attack_range()


# --- FUNCIÓN PARA ANIMACIONES DE MOVIMIENTO ---
func _handle_move_animation(h_velocity: Vector3):
	# Solo cambiamos la animación si NO estamos haciendo otra cosa importante
	if is_attacking or is_hurting:
		return
		
	if h_velocity.length() > 0.5: # Si se mueve
		animation_player.play("Walk", 0.2)
	else: # Si está casi quieto
		animation_player.play("Idle", 0.2)


# --- LÓGICA DE ATAQUE ---
func check_attack_range():
	# Si el timer está corriendo, significa que estamos en "Cooldown" del ataque
	if not timer.is_stopped():
		return

	for body in area_3d.get_overlapping_bodies():
		if body.is_in_group("Player"):
			perform_attack(body)
			return # Atacamos al primer jugador que encontramos y salimos

func perform_attack(target_body):
	if is_attacking or is_hurting: return
	
	is_attacking = true
	# Detenemos al enemigo para que golpee quieto
	velocity = Vector3.ZERO 
	
	# 1. Reproducir animación
	animation_player.play("Plunge Attack", 0.2)
	
	# 2. Aplicar daño (Lo hacemos justo al iniciar o podrías usar un Call Method Track en la animación)
	target_body.take_damage(damage)
	
	# 3. Iniciar el Timer de cooldown
	timer.start()
	
	# 4. Esperar a que termine la animación para volver a caminar
	await animation_player.animation_finished
	is_attacking = false
	# Volvemos a Idle momentáneamente hasta el siguiente frame de física
	animation_player.play("Idle", 0.2) 

func _target_position(target):
	navigation_agent_3d.target_position = target.global_transform.origin


# --- LÓGICA DE RECIBIR DAÑO ---
func apply_damage(amount: int) -> void:
	current_health -= amount
	
	if current_health <= 0:
		die()
	

func die() -> void:
	# Opcional: Podrías poner una animación de muerte aquí antes del queue_free
	_try_drop_ammo()
	queue_free()
	
func _try_drop_ammo() -> void:
	if ammo_drop_scene == null: return
	if randf() > ammo_drop_chance: return

	var pickup := ammo_drop_scene.instantiate()
	get_tree().current_scene.add_child(pickup)

	if pickup is Node3D:
		var pos := global_position
		pos.y = 0
		pickup.global_position = pos
	
	var amount := randi_range(ammo_drop_min, ammo_drop_max)
	if pickup.has_method("set_ammo_amount"):
		pickup.set_ammo_amount(amount)
	elif "ammo_amount" in pickup:
		pickup.ammo_amount = amount

func _on_timer_timeout() -> void:
	# El timer solo controla el cooldown del daño, no necesitamos lógica extra aquí
	# porque el check_attack_range revisa si el timer está parado.
	pass
