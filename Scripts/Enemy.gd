extends CharacterBody3D

@export var move_speed: float = 10.0            # velocidad del enemigo
@export var waypoint_tolerance: float = 0.8     # distancia para cambiar de waypoint
@export var height_offset: float = 2.0          # altura del camino
@export var min_repath_time: float = 0.25       # tiempo mínimo entre recalculados
@export var stuck_repath_time: float = 1.0      # si está casi sin moverse tanto tiempo, recalcula

@export var max_health: int = 100               
var current_health: int = 0

var target: Node3D        # Player
var maze: Maze            # referencia al Maze

var _cell_path: Array = []     # [Vector2i]
var _world_path: Array = []    # [Vector3]
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

	# 1) Recalcular si el jugador cambia de celda
	var player_cell: Vector2i = maze.world_to_cell(target.global_position)
	if player_cell != _last_player_cell and _time_since_last_repath >= min_repath_time:
		_recalculate_path(player_cell)

	# 2) Recalcular si estamos "atascados" (apenas avanzamos)
	var moved_distance := global_position.distance_to(_last_position)
	if moved_distance > 0.05:
		_last_position = global_position
		_time_since_progress = 0.0
	elif _time_since_progress >= stuck_repath_time and _time_since_last_repath >= min_repath_time:
		_recalculate_path(player_cell)
		_time_since_progress = 0.0

	# 3) Si no hay camino, fallback simple: ir directo al jugador (puede chocar con paredes, pero no se queda loco)
	if _world_path.is_empty():
		_direct_chase(delta)
		return

	# 4) Seguir el camino de waypoints
	_follow_path(delta)


func _follow_path(delta: float) -> void:
	if _current_wp_index >= _world_path.size():
		_current_wp_index = _world_path.size() - 1

	var waypoint: Vector3 = _world_path[_current_wp_index]
	var to_wp: Vector3 = waypoint - global_position
	to_wp.y = 0.0

	var dist_to_wp := to_wp.length()

	# Cambiar al siguiente waypoint si estamos cerca
	if dist_to_wp < waypoint_tolerance:
		if _current_wp_index < _world_path.size() - 1:
			_current_wp_index += 1
			waypoint = _world_path[_current_wp_index]
			to_wp = waypoint - global_position
			to_wp.y = 0.0
			dist_to_wp = to_wp.length()
		else:
			# Último waypoint: ya casi encima del jugador
			velocity = Vector3.ZERO
			move_and_slide()
			return

	var dir := Vector3.ZERO
	if dist_to_wp > 0.001:
		dir = to_wp / dist_to_wp

	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	velocity.y = 0.0

	if dir.length() > 0.001:
		look_at(global_position + dir, Vector3.UP)

	move_and_slide()


func _direct_chase(delta: float) -> void:
	var to_player := target.global_position - global_position
	to_player.y = 0.0

	if to_player.length() < 0.1:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var dir := to_player.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	velocity.y = 0.0

	if dir.length() > 0.001:
		look_at(global_position + dir, Vector3.UP)

	move_and_slide()


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
	

# ----------------------
# SISTEMA DE DAÑO / MUERTE
# ----------------------

func apply_damage(amount: int) -> void:
	current_health -= amount
	# Por si quieres log más adelante
	# print("Enemy hit, hp:", current_health, "/", max_health)
	if current_health <= 0:
		die()


func die() -> void:
	# Aquí luego podrás meter animación, sonido, partículas, etc.
	queue_free()
