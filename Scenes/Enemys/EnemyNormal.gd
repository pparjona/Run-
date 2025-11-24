extends CharacterBody3D

@export var move_speed: float = 4.0        # Velocidad agresiva
@export var turn_speed: float = 12.0
@export var max_health: int = 100
var current_health: int = 100

@export var ammo_drop_scene: PackedScene
@export var ammo_drop_chance: float = 0.4
@export var ammo_drop_min: int = 5
@export var ammo_drop_max: int = 15

@onready var asset_enemy: Node3D = $AssetEnemy
@onready var animation_player: AnimationPlayer = $AssetEnemy/AnimationPlayer

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
var target: CharacterBody3D = null

func _ready() -> void:
	if animation_player:
		animation_player.play("mixamo_com")
	else:
		print("ERROR: No encuentro el AnimationPlayer en $assetEnemy/AnimationPlayer")

func set_target_and_maze(p_target: Node3D, _p_maze: Node) -> void:
	target = p_target

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if target == null:
		move_and_slide()
		return
	
	_target_position(target)
	
	var nextLocation = navigation_agent_3d.get_next_path_position()
	var currentLocation = global_transform.origin
	var nextVelocity = (nextLocation-currentLocation).normalized() * move_speed
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
	
	move_and_slide()

func _target_position(target):
	navigation_agent_3d.target_position = target.global_transform.origin
	

func apply_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	_try_drop_ammo()
	queue_free()
	
func _try_drop_ammo() -> void:
	if ammo_drop_scene == null:
		return

	# randf() devuelve un float entre 0 y 1.
	if randf() > ammo_drop_chance:
		return

	var pickup := ammo_drop_scene.instantiate()
	get_tree().current_scene.add_child(pickup)

	if pickup is Node3D:
		var pos := global_position
		# Ajusta esta Y según la altura del suelo // tal como esta y=0
		pos.y = 0
		pickup.global_position = pos
	# Le damos una cantidad aleatoria de balas si el script lo soporta
	var amount := randi_range(ammo_drop_min, ammo_drop_max)
	if pickup.has_method("set_ammo_amount"):
		pickup.set_ammo_amount(amount)
	elif "ammo_amount" in pickup:
		pickup.ammo_amount = amount
