extends Node3D

@export var altar_scene: PackedScene
@export var exit_corridor_scene: PackedScene
@export var enemy_scene: PackedScene
@export var gun_pickup_scene: PackedScene

@onready var maze: Maze = $Maze
@onready var player: Node3D = $Player

func _ready() -> void:
	# 1) Colocar al jugador en la entrada del laberinto
	var start_pos: Vector3 = maze.get_player_start_position(2.0)
	player.global_position = start_pos

	# 2) Instanciar el altar en el centro de la plaza
	if altar_scene:
		var altar = altar_scene.instantiate()
		add_child(altar)

		var altar_pos: Vector3 = maze.get_center_altar_position(0.0)
		altar.global_position = altar_pos
		
		#Arma sobre el altar
		if gun_pickup_scene:
			var gun_pickup := gun_pickup_scene.instantiate()
			altar.add_child(gun_pickup)
			# Posición local encima del altar (ajusta la Y si hace falta)
			gun_pickup.position = Vector3(0, 1.0, 0)

	# 3) Instanciar el pasillo final con puerta
	if exit_corridor_scene:
		var corridor = exit_corridor_scene.instantiate()
		add_child(corridor)

		# Origen del corredor justo fuera del laberinto, alineado con la salida
		var origin_pos: Vector3 = maze.get_exit_corridor_origin(0.0)
		origin_pos.x -= maze.cell_size * 0.5 #mover medio cell_size hacia dentro del laberinto
		corridor.global_position = origin_pos

		# Si tu corridor no mira hacia +X, aquí puedes rotarlo (por ahora lo dejamos así)

		# Conectar la señal player_escaped si existe
		if corridor.has_signal("player_escaped"):
			corridor.player_escaped.connect(_on_player_escaped)
	# 4) Instanciar el enemigo en la esquina opuesta al jugador
	_spawn_enemy_at_opposite_corner()

func _spawn_enemy_at_opposite_corner() -> void:#Encargada de crear al enemigo principal
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate()
	add_child(enemy)
	
	# La esquina opuesta ya la estás usando como exit_cell,
	# así que reutilizamos la posición interna de salida
	var enemy_start: Vector3 = maze.get_exit_position(2.0)
	enemy.global_position = enemy_start

	# Pasar referencias de Player y Maze al enemigo
	if enemy.has_method("set_target_and_maze"):
		enemy.set_target_and_maze(player, maze)


func _on_player_escaped() -> void:
	print("Game: el jugador ha escapado.")
	GameManager.on_player_escaped()
