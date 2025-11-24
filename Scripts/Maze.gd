extends Node3D
class_name Maze

# --- CONFIGURACIÓN ---
@export var width: int = 31
@export var height: int = 31
@export var cell_size: float = 6.0

@export var wall_scene: PackedScene
@export var floor_scene: PackedScene

@export var wall_torch_scene: PackedScene
@export_range(0.0, 1.0, 0.01) var torch_probability: float = 0.04
@export var torch_height: float = 2.0

@export var arena_torch_scene: PackedScene
var arena_torch_height_offset: float = -0.7

@export_range(0.0, 1.0) var braiding_chance: float = 0.1
@export var wall_height: float = 4.0
@export var wall_thickness: float = 6.0

@export var room_width_cells: int = 7
@export var room_height_cells: int = 7

var grid: Array = []
var start_cell: Vector2i = Vector2i(1, 1)
var exit_cell: Vector2i = Vector2i(0, 0)
var center_cell: Vector2i = Vector2i(0, 0)
var walkable_cells: Array = []

var _path_dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

# Variable para guardar la región de navegación generada
var nav_region: NavigationRegion3D

func _ready() -> void:
	# 1. Generamos los datos del laberinto
	_init_grid()
	_generate_maze()
	_carve_center_room()
	_carve_exit()
	_create_loops()
	_collect_walkable_cells()
	
	# 2. Construimos el mundo físico Y la navegación
	_build_maze_with_navigation()
	
	# 3. Decoración (Antorchas)
	_place_torches()
	_spawn_arena_torches()

# ---------------------------------------------------------
# CONSTRUCCIÓN FÍSICA + NAVEGACIÓN
# ---------------------------------------------------------
func _build_maze_with_navigation() -> void:
	var total_width: float = float(width) * cell_size
	var total_height: float = float(height) * cell_size

	# 1. Crear dinámicamente el NavigationRegion3D
	nav_region = NavigationRegion3D.new()
	add_child(nav_region) # Lo hacemos hijo del nodo Maze
	
	# 2. Configurar el NavMesh (El mapa de donde se puede pisar)
	var nav_mesh = NavigationMesh.new()
	nav_mesh.agent_radius = 0.5       # Radio del enemigo (para que no se roce con paredes)
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 0.5    # Pequeña ayuda para desniveles
	
	nav_mesh.cell_height = 0.02
	# IMPORTANTE: "PARSED_GEOMETRY_STATIC_COLLIDERS" es la mejor opción 
	# cuando usas StaticBody3D + MeshInstance3D (tus paredes y suelo nuevos)
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	
	nav_region.navigation_mesh = nav_mesh

	# 3. Instanciar SUELO y hacerlo HIJO de nav_region
	if floor_scene:
		var floor_instance = floor_scene.instantiate()
		nav_region.add_child(floor_instance) # <--- CLAVE: Hijo de la región
		
		# Posición y Escala
		floor_instance.position = Vector3(total_width * 0.5, -0.5, total_height * 0.5)
		# Escalamos el suelo base (que mide 1x1) al tamaño total
		floor_instance.scale = Vector3(total_width, 1.0, total_height)

	# 4. Instanciar PAREDES y hacerlas HIJAS de nav_region
	if wall_scene:
		for y in height:
			for x in width:
				if grid[y][x] == 0:
					var wall_instance = wall_scene.instantiate()
					nav_region.add_child(wall_instance) # <--- CLAVE: Hijo de la región

					var wx: float = float(x) * cell_size
					var wz: float = float(y) * cell_size

					# Posición (Asumiendo que Wall.tscn ya tiene tamaño 6x4x6)
					wall_instance.position = Vector3(wx, wall_height * 0.5, wz)

	# 5. HORNEAR (BAKE)
	# Esperamos un frame para asegurar que Godot ha colocado todo en la escena
	await get_tree().process_frame
	nav_region.bake_navigation_mesh()
	print("Maze: Mapa de navegación horneado correctamente.")


# ---------------------------------------------------------
# LÓGICA DEL LABERINTO (NO TOCAR)
# ---------------------------------------------------------
func _init_grid() -> void:
	grid.clear()
	for y in height:
		var row: Array = []
		for x in width: row.append(0)
		grid.append(row)

func _generate_maze() -> void:
	var stack: Array = []
	start_cell = Vector2i(1, 1)
	grid[start_cell.y][start_cell.x] = 1
	stack.push_back(start_cell)

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var neighbors: Array = []
		for dir in _path_dirs:
			var next: Vector2i = current + dir * 2
			if _is_in_bounds(next) and grid[next.y][next.x] == 0:
				neighbors.append(next)
		if neighbors.is_empty():
			stack.pop_back()
		else:
			neighbors.shuffle()
			var chosen: Vector2i = neighbors[0]
			var between: Vector2i = current + (chosen - current) / 2
			grid[between.y][between.x] = 1
			grid[chosen.y][chosen.x] = 1
			stack.push_back(chosen)

func _create_loops() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for y in range(1, height - 1):
		for x in range(1, width - 1):
			if grid[y][x] == 0:
				var path_up = grid[y-1][x] == 1
				var path_down = grid[y+1][x] == 1
				var path_left = grid[y][x-1] == 1
				var path_right = grid[y][x+1] == 1
				var can_break = false
				if path_left and path_right and not path_up and not path_down: can_break = true
				if path_up and path_down and not path_left and not path_right: can_break = true
				if can_break and rng.randf() < braiding_chance:
					grid[y][x] = 1

func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x > 0 and cell.x < width - 1 and cell.y > 0 and cell.y < height - 1

func _is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

func _carve_center_room() -> void:
	@warning_ignore("integer_division")
	var center_x: int = width / 2
	@warning_ignore("integer_division")
	var center_y: int = height / 2
	center_cell = Vector2i(center_x, center_y)
	@warning_ignore("integer_division")
	var half_w: int = room_width_cells / 2
	@warning_ignore("integer_division")
	var half_h: int = room_height_cells / 2
	for y in range(center_y - half_h, center_y + half_h + 1):
		for x in range(center_x - half_w, center_x + half_w + 1):
			var cell := Vector2i(x, y)
			if _is_inside_grid(cell): grid[cell.y][cell.x] = 1

func _carve_exit() -> void:
	exit_cell = Vector2i(width - 2, height - 2)
	grid[exit_cell.y][exit_cell.x] = 1
	grid[exit_cell.y][width - 1] = 1

func _collect_walkable_cells() -> void:
	walkable_cells.clear()
	for y in height:
		for x in width:
			if grid[y][x] == 1: walkable_cells.append(Vector2i(x, y))

# ---------------------------------------------------------
# HELPERS PÚBLICOS
# ---------------------------------------------------------
func world_to_cell(world_pos: Vector3) -> Vector2i:
	var x := int(floor(world_pos.x / cell_size + 0.5))
	var y := int(floor(world_pos.z / cell_size + 0.5))
	return Vector2i(x, y)

func cell_to_world(cell: Vector2i, height_offset: float = 0.0) -> Vector3:
	var wx: float = float(cell.x) * cell_size
	var wz: float = float(cell.y) * cell_size
	return Vector3(wx, height_offset, wz)

func get_player_start_position(height_offset: float = 2.0) -> Vector3:
	return cell_to_world(start_cell, height_offset)

func get_exit_position(height_offset: float = 2.0) -> Vector3:
	return cell_to_world(exit_cell, height_offset)

func get_center_altar_position(height_offset: float = 0.0) -> Vector3:
	return cell_to_world(center_cell, height_offset)

func get_exit_corridor_origin(height_offset: float = 0.0) -> Vector3:
	var wx: float = float(width) * cell_size
	var wz: float = float(exit_cell.y) * cell_size
	return Vector3(wx, height_offset, wz)


func get_random_walkable_world_position(height_offset: float = 0.0, exclude_start: bool = true, exclude_exit: bool = true, exclude_center: bool = false) -> Vector3:
	var candidates: Array = []
	for cell in walkable_cells:
		if exclude_start and cell == start_cell: continue
		if exclude_exit and cell == exit_cell: continue
		if exclude_center and cell == center_cell: continue
		candidates.append(cell)
	
	if candidates.is_empty(): 
		# Si falla, al inicio pero alto
		var start_pos = cell_to_world(start_cell, height_offset)
		start_pos.y = 8.0 
		return start_pos
	
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var random_cell = candidates[rng.randi_range(0, candidates.size() - 1)]
	
	# Obtenemos el centro matemático de la celda
	var center_pos = cell_to_world(random_cell, 0.0)
	
	return Vector3(center_pos.x, 8.0, center_pos.z)

# ---------------------------------------------------------
# ANTORCHAS
# ---------------------------------------------------------
func _place_torches() -> void:
	if wall_torch_scene == null: return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for cell: Vector2i in walkable_cells:
		if rng.randf() > torch_probability: continue
		var wall_dirs: Array[Vector2i] = []
		for dir: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + dir
			if not _is_inside_grid(neighbor): continue
			if grid[neighbor.y][neighbor.x] == 0: wall_dirs.append(dir)
		if wall_dirs.is_empty(): continue
		var dir2d: Vector2i = wall_dirs[rng.randi_range(0, wall_dirs.size() - 1)]
		var wall_cell: Vector2i = cell + dir2d
		var dir3d: Vector3 = Vector3(dir2d.x, 0.0, dir2d.y).normalized()
		var wall_center: Vector3 = cell_to_world(wall_cell, wall_height * 0.5)
		var offset: float = wall_thickness * 0.5 + 0.1
		var torch_pos: Vector3 = wall_center - dir3d * offset
		torch_pos.y = torch_height
		var torch := wall_torch_scene.instantiate() as Node3D
		add_child(torch)
		torch.global_position = torch_pos
		torch.look_at(torch.global_position - dir3d, Vector3.UP)
		torch.rotate_y(PI)

func _spawn_arena_torches() -> void:
	if arena_torch_scene == null: return

	@warning_ignore("integer_division")
	var half_w: int = room_width_cells / 2
	@warning_ignore("integer_division")
	var half_h: int = room_height_cells / 2
	
	var min_x = center_cell.x - half_w
	var max_x = center_cell.x + half_w
	var min_y = center_cell.y - half_h
	var max_y = center_cell.y + half_h

	var spacing: int = 2 
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var place_torch = false
			# 1. Borde Superior e Inferior
			if y == min_y or y == max_y:
				# Solo ponemos si la distancia desde la esquina izquierda es par
				if (x - min_x) % spacing == 0:
					place_torch = true
			# 2. Borde Izquierdo y Derecho (excluyendo esquinas ya calculadas arriba)
			elif x == min_x or x == max_x:
				# Solo ponemos si la distancia desde la esquina superior es par
				if (y - min_y) % spacing == 0:
					place_torch = true
			# 3. Instanciar si corresponde
			if place_torch:
				var cell = Vector2i(x, y)
				var torch_pos = cell_to_world(cell, arena_torch_height_offset)
				var torch = arena_torch_scene.instantiate()
				add_child(torch)
				torch.global_position = torch_pos
				torch.add_to_group("ArenaTorches")
