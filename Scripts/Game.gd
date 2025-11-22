extends Node3D

@export var altar_scene: PackedScene
@export var boss_scene: PackedScene                # Enemigo BOSS
@export var normal_enemy_scene: PackedScene        # Enemigo NORMAL para oleadas
@export var exit_corridor_scene: PackedScene
@export var gun_pickup_scene: PackedScene          # Pistola que aparece sobre el altar

@onready var maze: Maze = $Maze
@onready var player: Node3D = $Player
@onready var enemy_manager: Node = $EnemyManager

var _arena_event_triggered: bool = false

func _ready() -> void:
	# 1) Colocar al jugador en la entrada del laberinto
	var start_pos: Vector3 = maze.get_player_start_position(2.0)
	player.global_position = start_pos

	# 2) Instanciar el altar en el centro de la plaza
	if altar_scene:
		var altar := altar_scene.instantiate()
		add_child(altar)

		var altar_pos: Vector3 = maze.get_center_altar_position(0.0)
		altar.global_position = altar_pos

		# 2.1) Arma sobre el altar
		if gun_pickup_scene:
			var gun_pickup := gun_pickup_scene.instantiate()
			altar.add_child(gun_pickup)
			# Posición local encima del altar (ajusta la Y si hace falta)
			gun_pickup.position = Vector3(0.0, 1.0, 0.0)

		# 2.2) Conectar la señal para iniciar las oleadas cuando el player entra en la plaza
		if altar.has_signal("player_entered_plaza"):
			altar.player_entered_plaza.connect(_on_player_entered_plaza)

	# 3) Instanciar el pasillo final con puerta
	if exit_corridor_scene:
		var corridor := exit_corridor_scene.instantiate()
		add_child(corridor)

		# Origen del corredor justo fuera del laberinto, alineado con la salida
		var origin_pos: Vector3 = maze.get_exit_corridor_origin(0.0)
		# Pequeño ajuste para que conecte mejor con el laberinto (medio cell_size hacia dentro)
		origin_pos.x -= maze.cell_size * 0.5
		corridor.global_position = origin_pos

		# Conectar la señal player_escaped si existe
		if corridor.has_signal("player_escaped"):
			corridor.player_escaped.connect(_on_player_escaped)

	# 4) Configurar EnemyManager (enemigos normales)
	if enemy_manager:
		if enemy_manager.has_method("set"):
			enemy_manager.set("maze", maze)
			enemy_manager.set("player", player)
			enemy_manager.set("enemy_scene", normal_enemy_scene)
		
		# --- ESTO FALTABA: Conectar señal de fin de oleadas ---
		if enemy_manager.has_signal("all_waves_cleared"):
			enemy_manager.all_waves_cleared.connect(_on_all_waves_cleared)

	# 5) Instanciar el BOSS inicial en la esquina opuesta (celda de salida interna)
	_spawn_boss_at_opposite_corner()


func _spawn_boss_at_opposite_corner() -> void:
	if boss_scene == null:
		return

	var boss := boss_scene.instantiate()
	add_child(boss)

	# La esquina opuesta ya la estás usando como exit_cell,
	# así que reutilizamos la posición interna de salida
	var boss_start: Vector3 = maze.get_exit_position(2.0)
	boss.global_position = boss_start

	# Pasar referencias de Player y Maze al boss
	if boss.has_method("set_target_and_maze"):
		boss.set_target_and_maze(player, maze)


func _on_player_entered_plaza() -> void:
	# Si ya se activó, no hacemos nada
	if _arena_event_triggered:
		return
	
	_arena_event_triggered = true
	await get_tree().create_timer(1.0).timeout
	print("Game: ¡Encendiendo Arena!")
	
	# ACTIVAR: Muestra fuego y luces con sus valores por defecto
	_set_arena_torches_active(true)

	if enemy_manager and enemy_manager.has_method("start_waves"):
		enemy_manager.start_waves()


func _on_all_waves_cleared() -> void:
	await get_tree().create_timer(1.0).timeout
	print("Game: Apagando Fuego y Luces...")
	_set_arena_torches_active(false)

func _set_arena_torches_active(is_active: bool) -> void:
	var torches = get_tree().get_nodes_in_group("ArenaTorches")
	for t in torches:
		# 1. Luz
		var light = t.get_node_or_null("TorchLight")
		if light:
			light.visible = is_active
		
		# 2. Fuego (Visual)
		var flame = _find_node_by_name(t, "flame")
		if flame:
			flame.visible = is_active
			
		# 3. ### NUEVO: Reproducir Animación "Burning" ###
		# Buscamos el AnimationPlayer (suele estar en la raíz o cerca)
		var anim = t.get_node_or_null("AnimationPlayer")
		if anim:
			if is_active:
				# Si no se está reproduciendo ya, dale al play
				if anim.current_animation != "Burning":
					anim.play("Burning")
			else:
				# Parar animación al apagar
				anim.stop()

# Función auxiliar para encontrar nodos profundos (como tu "flame" dentro del modelo)
func _find_node_by_name(root: Node, name_to_find: String) -> Node:
	if root.name == name_to_find:
		return root
	for child in root.get_children():
		var found = _find_node_by_name(child, name_to_find)
		if found:
			return found
			
	return null

func _on_player_escaped() -> void:
	print("Game: el jugador ha escapado.")
	GameManager.on_player_escaped()
