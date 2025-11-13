# ProtoController v1.0 by Brackeys
# CC0 License

extends CharacterBody3D

# -------------------------------
# NUEVAS VARIABLES PARA FREEFLY
# -------------------------------
var fly_speed: float = 10.0   # velocidad vertical en freefly

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

# ----- VARIABLES -----
var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false  # <- modo noclip activado/desactivado

# REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

# ---------------------------------------
# READY
# ---------------------------------------
func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	capture_mouse()

# ---------------------------------------
# INPUT
# ---------------------------------------
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

	# ----------------------------------------------------
	# FREEFLY / NOCLIP MODE
	# ----------------------------------------------------
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		# velocidad horizontal
		motion *= freefly_speed * delta

		# movimiento vertical en noclip
		if Input.is_key_pressed(KEY_E):   # subir
			motion.y = freefly_speed * delta
		elif Input.is_key_pressed(KEY_Q): # bajar
			motion.y = -freefly_speed * delta

		move_and_collide(motion)
		return  # NOS SALIMOS AQUÍ → no aplicamos gravedad ni física normal

	# ----------------------------------------------------
	# MOVIMIENTO NORMAL (no freefly)
	# ----------------------------------------------------
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
