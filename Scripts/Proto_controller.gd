# ProtoController v1.0 by Brackeys
# CC0 License

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = true

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"
## Name of Input Action to Shoot.
@export var input_shoot : String = "shoot"
## Name of Input Action to Pickup.
@export var input_pickup : String = "pickup"
## Name of Input Action to Reload.
@export var input_reload : String = "reload"


# ----- VARIABLES -----
var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
@export var shoot_cooldown: float = 0.45     # ajusta a la duración de la animación "shoot"
var can_shoot: bool = true
@export var reload_time: float = 1.0         # ajusta a la duración de la animación "reload"
var is_reloading: bool = false



# VIDA Y MUNICIÓN EN PANTALLA
@export var max_health: int = 100
var health: int

# MUNICIÓN
@export var max_ammo_in_clip: int = 10      # balas máximas en el cargador
var current_ammo_in_clip: int = 0           # balas actuales en el cargador

@export var reserve_ammo: int = 20          # balas de reserva (además del cargador lleno)

signal health_changed(current: int, max: int)
signal player_died
signal gun_equipped(has_gun: bool)
signal ammo_changed(current: int, max: int) # current = en cargador, max = tamaño de cargador

# Carga las escenas. ¡¡ASEGÚRATE DE QUE ESTAS RUTAS SEAN CORRECTAS!!
const BULLET_SCENE = preload("res://Scenes/Pistol/bullet.tscn")
const EQUIPPED_GUN_SCENE = preload("res://Scenes/Pistol/equiped_gun.tscn")

# Estado del arma
var has_gun = false
var gun_pickup_in_range = null # Guarda el arma que podemos recoger

# REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider
# ¡Asegúrate de que estos nodos existen en tu escena ProtoController!
@onready var gun_holder = $Head/Camera3D/EquipedGun
@onready var pickup_detector = $PickUpDetector
@onready var equiped_gun: Node3D = $Head/Camera3D/EquipedGun


# ---------------------------------------
# READY
# ---------------------------------------
func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	capture_mouse()
	
	# Configura el detector para que detecte 'Areas' (monitorING)
	# pero no sea detectado por otros (monitorABLE)
	pickup_detector.monitoring = true 
	pickup_detector.monitorable = false
	
	# Iniciar vida
	health = max_health
	health_changed.emit(health, max_health)

	# Iniciar munición:
	#  - un cargador lleno
	#  - reserva inicial (por defecto 20 → total 30)
	if max_ammo_in_clip <= 0:
		max_ammo_in_clip = 10
	current_ammo_in_clip = max_ammo_in_clip
	# reserve_ammo ya viene del export (por defecto 20)
	ammo_changed.emit(current_ammo_in_clip, max_ammo_in_clip)

	GameManager.register_player(self)


# ---------------------------------------
# INPUT
# ---------------------------------------
func _input(event: InputEvent) -> void:
	# No procesar disparos o recogidas si estamos en modo noclip
	if freeflying:
		return

	# Disparar
	if event.is_action_pressed(input_shoot):
		shoot()
	
	# Recoger arma
	if event.is_action_pressed(input_pickup) and gun_pickup_in_range != null and not has_gun:
		equip_gun(gun_pickup_in_range)

	# Recargar
	if event.is_action_pressed(input_reload):
		reload_weapon()


func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Mouse look
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()


# ---------------------------------------
# PHYSICS
# ---------------------------------------
func _physics_process(delta: float) -> void:

	# FREEFLY / NOCLIP MODE
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		# velocidad horizontal
		motion *= freefly_speed * delta

		# movimiento vertical en noclip
		if Input.is_key_pressed(KEY_SPACE):  # subir
			motion.y = freefly_speed * delta
		elif Input.is_key_pressed(KEY_Q):    # bajar
			motion.y = -freefly_speed * delta

		move_and_collide(motion)
		return  # NOS SALIMOS AQUÍ → no aplicamos gravedad ni física normal

	# MOVIMIENTO NORMAL (no freefly)
	# Gravedad
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta

	# Saltar
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity

	# Correr / andar
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Movimiento horizontal normal
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0

	move_and_slide()


# ----------------------------------------------------
# ROTACIÓN DE CÁMARA
# ----------------------------------------------------
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


# ----------------------------------------------------
# FREEFLY ENABLE / DISABLE
# ----------------------------------------------------
func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO
	print("FREEFLY ACTIVADO")

func disable_freefly():
	collider.disabled = false
	freeflying = false
	print("FREEFLY DESACTIVADO")


# ----------------------------------------------------
# MOUSE
# ----------------------------------------------------
func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


# ----------------------------------------------------
# INPUT CHECKS
# ----------------------------------------------------
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. Missing input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. Missing input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. Missing input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. Missing input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. Missing input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. Missing input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. Missing input_freefly: " + input_freefly)
		can_freefly = false
		
	# Gun
	if not InputMap.has_action(input_shoot):
		push_error("Shooting disabled. Missing input_shoot: " + input_shoot)
	if not InputMap.has_action(input_pickup):
		push_error("Pickup disabled. Missing input_pickup: " + input_pickup)
	if not InputMap.has_action(input_reload):
		push_error("Reload disabled. Missing input_reload: " + input_reload)


# ----------------------------------------------------
#  FUNCIONES DE ARMAS
# ----------------------------------------------------
func equip_gun(gun_pickup_object):
	# Marcar que tenemos el arma
	has_gun = true
	
	# Destruir el arma del suelo
	gun_pickup_object.queue_free()
	gun_pickup_in_range = null
	
	# Crear la instancia del arma equipada
	var equipped_gun = EQUIPPED_GUN_SCENE.instantiate()
	gun_holder.add_child(equipped_gun)
	print("¡Arma equipada!")
	gun_equipped.emit(true)

	# Actualizar HUD de munición
	ammo_changed.emit(current_ammo_in_clip, max_ammo_in_clip)


func shoot():
	# Si no tenemos arma, no podemos disparar
	if not has_gun:
		print("No tengo arma")
		return

	# No disparamos si estamos en cooldown o recargando
	if not can_shoot or is_reloading:
		return

	# Si no hay balas en el cargador
	if current_ammo_in_clip <= 0:
		print("Click! Sin balas en el cargador.")
		return

	# Asumimos que el arma equipada es el primer hijo del GunHolder
	if gun_holder.get_child_count() == 0:
		print("No hay arma equipada en gun_holder")
		return
	var equipped_gun: Node3D = gun_holder.get_child(0)

	# Activar cooldown de disparo
	can_shoot = false

	# --- DISPARO VISUAL: ANIMACIÓN + SONIDO ---
	var anim_player: AnimationPlayer = equipped_gun.get_node_or_null("AnimationPlayer")
	if anim_player and anim_player.has_animation("shoot"):
		anim_player.stop()
		anim_player.play("shoot")

	var audio_shoot: AudioStreamPlayer3D = equipped_gun.get_node_or_null("AudioShoot")
	if audio_shoot:
		audio_shoot.stop()
		audio_shoot.play()

	# --- FLASH DE LUZ ---
	_flash_muzzle(equipped_gun)

	# --- DISPARO LÓGICO: BALA ---
	var muzzle: Node3D = equipped_gun.get_node_or_null("Muzzle")
	# Si en tu escena es "Pistol/Muzzle", usa esa ruta:
	# var muzzle: Node3D = equipped_gun.get_node_or_null("Pistol/Muzzle")

	if muzzle == null:
		print("ERROR: El arma equipada no tiene nodo 'Muzzle'")
		can_shoot = true
		return

	var bullet: CharacterBody3D = BULLET_SCENE.instantiate()

	# IMPORTANTE:
	# Le copiamos TODA la transform del Muzzle (posición + rotación)
	# Así la bala "nace" orientada igual que el cañón.
	bullet.global_transform = muzzle.global_transform

	# Añadir la bala a la escena actual
	get_tree().current_scene.add_child(bullet)


	# 6) Restar bala del cargador y actualizar HUD
	current_ammo_in_clip -= 1
	ammo_changed.emit(current_ammo_in_clip, max_ammo_in_clip)

	# 7) Cooldown de disparo
	await get_tree().create_timer(shoot_cooldown).timeout
	can_shoot = true



func reload_weapon():
	# No recargamos si no tenemos arma
	if not has_gun:
		return

	# No recargamos si ya estamos recargando
	if is_reloading:
		return

	# Si el cargador ya está lleno, nada que hacer
	if current_ammo_in_clip >= max_ammo_in_clip:
		print("Cargador ya lleno")
		return

	# Si no tenemos balas de reserva, no se puede recargar
	if reserve_ammo <= 0:
		print("No quedan balas de reserva")
		return

	is_reloading = true

	# Reproducir animación de recarga si existe
	if gun_holder.get_child_count() > 0:
		var equipped_gun := gun_holder.get_child(0)
		var anim_player: AnimationPlayer = equipped_gun.get_node_or_null("AnimationPlayer")
		if anim_player and anim_player.has_animation("reload"):
			anim_player.play("reload")
			var audio_reload: AudioStreamPlayer3D = equipped_gun.get_node_or_null("AudioReload")
			if audio_reload:
				audio_reload.stop()
				audio_reload.play()

	# Esperar el tiempo de recarga (hazlo coincidir con la duración de la animación)
	await get_tree().create_timer(reload_time).timeout

	# Ahora aplicamos la lógica de recarga
	var needed: int = max_ammo_in_clip - current_ammo_in_clip
	var to_load: int = min(needed, reserve_ammo)

	current_ammo_in_clip += to_load
	reserve_ammo -= to_load

	print("Recargando:", to_load, "balas. En cargador:", current_ammo_in_clip, "Reserva:", reserve_ammo)
	ammo_changed.emit(current_ammo_in_clip, max_ammo_in_clip)

	is_reloading = false

func _flash_muzzle(equipped_gun: Node3D) -> void:
	var flash_light := equipped_gun.get_node_or_null("Pistol/Muzzle/MuzzleFlashLight")
	if flash_light == null:
		return

	flash_light.visible = true
	# Duración muy corta del flash (ajusta a tu gusto: 0.03–0.08 suele ir bien)
	await get_tree().create_timer(0.05).timeout
	flash_light.visible = false


# ----------------------------------------------------
#  SEÑALES DE RECOGIDA
# ----------------------------------------------------
func _on_pick_up_detector_area_entered(area: Area3D) -> void:
	# Si el objeto que entró está en el grupo "GunPickup"...
	if area.is_in_group("GunPickup"):
		gun_pickup_in_range = area
		print("¡Puedes recoger un arma! (Presiona 'E')")


func _on_pick_up_detector_area_exited(area: Area3D) -> void:
	# Si el objeto que sale es el que teníamos guardado...
	if area == gun_pickup_in_range:
		gun_pickup_in_range = null
		print("Arma fuera de rango")


# ----------------------------------------------------
# DAÑO / MUERTE
# ----------------------------------------------------
func _on_player_died() -> void:
	print("Jugador muerto")
	GameManager.on_player_died()

func take_damage(amount: int) -> void:
	health -= amount
	if health < 0:
		health = 0

	health_changed.emit(health, max_health)

	if health == 0:
		player_died.emit()
		_on_player_died()
