extends CharacterBody3D

@export var move_speed: float = 7.0                   # velocidad base (reducimos para más natural)
@export var steering_smooth: float = 6.0              # suavizado de movimiento
@export var separation_strength: float = 6.0          # fuerza para evitar apelotonamientos
@export var separation_radius: float = 2.5            # distancia para repelerse

@export var waypoint_tolerance: float = 0.8
@export var height_offset: float = 2.0
@export var min_repath_time: float = 0.25
@export var stuck_repath_time: float = 1.0

@export var max_health: int = 100
var current_health: int = 0

var target: Node3D
var maze: Maze

var _cell_path: Array = []
var _world_path: Array = []
var _current_wp_index: int = 0

var _last_player_cell: Vector2i = Vector2i(-999, -999)
var _time_since_last_repath: float = 0.0

var _last_position: Vector3
var _time_since_progress: float = 0.0

func _ready() -> void:
	current_health = max_health

func set_target_and_maze(p_target: Node3D, p_maze: Maze) -> void:
	target = p_target
	maze = p_maze
	_last_position = global_position
	_force_recalculate_path()


func _physics_process(delta: float) -> void:
	if target == null or maze == null:
		return

	_time_since_last_repath += delta
	_time_since_progress += delta

	var player_cell: Vector2i = maze.world_to_cell(target.global_position)
	if player_cell != _last_player_cell and _time_since_last_repath >= min_repath_time:
		_recalculate_path(player_cell)

	# si está atascado, recalcula
	var moved_distance := global_position.distance_to(_last_position)
	if moved_distance > 0.05:
		_last_position = global_position
		_time_since_progress = 0.0
	elif _time_since_progress >= stuck_repath_time and _time_since_last_repath >= min_repath_time:
		_recalculate_path(player_cell)
		_time_since_progress = 0.0

	if _world_path.is_empty():
		_direct_chase(delta)
		return

	_follow_path(delta)


# ------------------------------
#  Movimiento suave + separación
# ------------------------------
func _follow_path(delta: float) -> void:
	if _current_wp_index >= _world_path.size():
		_current_wp_index = _world_path.size() - 1

	var waypoint: Vector3 = _world_path[_current_wp_index]
	var to_wp: Vector3 = waypoint - global_position
	to_wp.y = 0.0

	var dist := to_wp.length()
	if dist < waypoint_tolerance:
		if _current_wp_index < _world_path.size() - 1:
			_current_wp_index += 1
			return
		else:
			velocity = Vector3.ZERO
			move_and_slide()
			return

	# dirección hacia el waypoint
	var desired_dir := to_wp.normalized()

	# --------------------
	# separación de enemigos
	# --------------------
	desired_dir += _compute_separation() * separation_strength

	# suavizar dirección (más natural)
	var final_dir := velocity.normalized().lerp(desired_dir.normalized(), delta * steering_smooth)

	# aplicar velocidad
	velocity.x = final_dir.x * move_speed
	velocity.z = final_dir.z * move_speed
	velocity.y = 0

	look_at(global_position + final_dir, Vector3.UP)
	move_and_slide()


# movimiento directo si no hay path
func _direct_chase(delta: float) -> void:
	var to_player := target.global_position - global_position
	to_player.y = 0.0

	if to_player.length() < 0.1:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var dir := to_player.normalized()

	# también aplicamos separación aquí
	dir += _compute_separation() * separation_strength

	var final_dir := velocity.normalized().lerp(dir.normalized(), delta * steering_smooth)

	velocity.x = final_dir.x * move_speed
	velocity.z = final_dir.z * move_speed
	velocity.y = 0

	look_at(global_position + final_dir, Vector3.UP)
	move_and_slide()


# ---------------------------------------------------------
#  Detectar enemigos cerca y empujar en dirección contraria
# ---------------------------------------------------------
func _compute_separation() -> Vector3:
	var repulsion := Vector3.ZERO
	var count := 0

	for e in get_parent().get_children():
		if e == self:
			continue
		if not e is CharacterBody3D:
			continue

		var diff : Vector3 = global_position - e.global_position
		diff.y = 0

		var d :float = diff.length()
		if d < separation_radius and d > 0.01:
			repulsion += diff.normalized() / d
			count += 1

	if count > 0:
		repulsion /= count

	return repulsion


func _force_recalculate_path() -> void:
	var player_cell: Vector2i = maze.world_to_cell(target.global_position)
	_recalculate_path(player_cell)


func _recalculate_path(player_cell: Vector2i) -> void:
	if maze == null:
		return

	var start_cell: Vector2i = maze.world_to_cell(global_position)
	_cell_path = maze.find_path_cells(start_cell, player_cell)

	_world_path.clear()
	for c in _cell_path:
		_world_path.append(maze.cell_to_world(c, height_offset))

	_current_wp_index = 0
	_last_player_cell = player_cell
	_time_since_last_repath = 0.0


# ---------------------- DAÑO/MUERTE ----------------------
func apply_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
