extends Node

@export var maze: Maze
@export var player: Node3D
@export var enemy_scene: PackedScene   # escena del enemigo NORMAL

@export var total_waves: int = 3
@export var enemies_per_wave: int = 5

@export var time_between_spawns: float = 1.0
@export var time_between_waves: float = 5.0
@export var max_enemies_alive: int = 20

var _waves_started: bool = false
var _current_wave: int = 0
var _spawn_timer: float = 0.0
var _wave_pause_timer: float = 0.0
var _spawned_this_wave: int = 0
var _enemies_alive: int = 0

signal all_waves_cleared

func _ready() -> void:
	print("EnemyManager READY. maze =", maze, "player =", player, "enemy_scene =", enemy_scene)

func start_waves() -> void:
	if _waves_started:
		print("EnemyManager: start_waves llamado pero ya estaba iniciado.")
		return
	_waves_started = true
	_current_wave = 1
	_spawned_this_wave = 0
	_spawn_timer = 0.0
	_wave_pause_timer = 0.0
	
	print("EnemyManager: ¡Oleadas iniciadas! Ola =", _current_wave)

func _process(delta: float) -> void:
	if not _waves_started:
		return

	if _current_wave > total_waves:
		return
	
	# Si hay demasiados enemigos vivos, no spawneamos más de momento
	if _enemies_alive >= max_enemies_alive:
		return

	# ¿Quedan enemigos por spawnear en esta ola?
	if _spawned_this_wave < enemies_per_wave:
		_spawn_timer += delta
		if _spawn_timer >= time_between_spawns:
			_spawn_timer = 0.0
			_spawn_enemy()
			_spawned_this_wave += 1
	else:
		# Pausa entre oleadas
		if _current_wave < total_waves:
			_wave_pause_timer += delta
			if _wave_pause_timer >= time_between_waves:
				# Avanzamos de ola
				_wave_pause_timer = 0.0
				_spawned_this_wave = 0
				_current_wave += 1
				enemies_per_wave += 2 # Aumentamos dificultad
				print("EnemyManager: empieza ola ", _current_wave)

func _finish_combat() -> void:
	print("EnemyManager: ¡COMBATE TERMINADO!")
	_waves_started = false
	_current_wave = total_waves + 1 
	all_waves_cleared.emit()

func _spawn_enemy() -> void:
	if enemy_scene == null or maze == null or player == null:
		push_warning("EnemyManager: NO puedo spawnear. enemy_scene =", enemy_scene, "maze =", maze, "player =", player)
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	var spawn_pos: Vector3 = maze.get_random_walkable_world_position(
		2.0,
		true,  # exclude_start
		true,  # exclude_exit
		true   # exclude_center
	)
	enemy.global_position = spawn_pos
	print("EnemyManager: enemigo spawneado en", spawn_pos)

	if enemy.has_method("set_target_and_maze"):
		enemy.set_target_and_maze(player, maze)

	_enemies_alive += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited)

func _on_enemy_tree_exited() -> void:
	_enemies_alive = max(0, _enemies_alive - 1)
	print("EnemyManager: enemigo destruido. Enemigos vivos =", _enemies_alive)
	
	if _waves_started:
		# Si estamos en la última ola Y ya salieron todos los bichos Y no queda nadie vivo...
		if _current_wave == total_waves and _spawned_this_wave >= enemies_per_wave and _enemies_alive == 0:
			_finish_combat()
