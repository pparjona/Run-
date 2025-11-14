extends Node3D
class_name Maze

@export var width: int = 21   # DEBE ser impar (21, 31, 41...)
@export var height: int = 21  # DEBE ser impar
@export var cell_size: float = 6.0  # tamaño físico de cada celda en el mundo 3D

@export var wall_scene: PackedScene
@export var floor_scene: PackedScene

# Altura y grosor de paredes (en unidades del mundo)
@export var wall_height: float = 4.0
@export var wall_thickness: float = 6.0  # normalmente igual a cell_size para bloques completos

var grid: Array = []      # grid[y][x] = 0 (pared) o 1 (pasillo)
var start_cell: Vector2i = Vector2i(1, 1)
var exit_cell: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	_init_grid()
	_generate_maze()
	_carve_exit()
	_build_maze()

func _init_grid() -> void:
	grid.clear()
	for y in height:
		var row: Array = []
		for x in width:
			row.append(0) # todo paredes al principio
		grid.append(row)

func _generate_maze() -> void:
	# Algoritmo DFS (backtracking) para generar el laberinto
	var stack: Array = []

	start_cell = Vector2i(1, 1)
	grid[start_cell.y][start_cell.x] = 1
	stack.push_back(start_cell)

	var directions := [
		Vector2i(1, 0),
		Vector2i(-1, 0),
		Vector2i(0, 1),
		Vector2i(0, -1),
	]

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	while not stack.is_empty():
		var current: Vector2i = stack.back()
		var neighbors: Array = []

		# Buscar vecinos a 2 celdas de distancia que sigan siendo paredes
		for dir in directions:
			var next: Vector2i = current + dir * 2
			if _is_in_bounds(next) and grid[next.y][next.x] == 0:
				neighbors.append(next)

		if neighbors.is_empty():
			# No hay vecinos disponibles, retroceder
			stack.pop_back()
		else:
			# Elegir un vecino aleatorio
			neighbors.shuffle()
			var chosen: Vector2i = neighbors[0]

			# Celda intermedia entre current y chosen (el muro que vamos a abrir)
			var between: Vector2i = current + (chosen - current) / 2
			grid[between.y][between.x] = 1
			grid[chosen.y][chosen.x] = 1

			stack.push_back(chosen)

func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x > 0 and cell.x < width - 1 and cell.y > 0 and cell.y < height - 1

# ---------------------------------------------------------
# Crear salida en la esquina opuesta al inicio
# ---------------------------------------------------------
func _carve_exit() -> void:
	# Celda interior opuesta (esquina inferior derecha “interna”)
	exit_cell = Vector2i(width - 2, height - 2)

	# Aseguramos que esa celda sea pasillo
	grid[exit_cell.y][exit_cell.x] = 1

	# Abrimos un hueco en la pared exterior derecha junto a esa celda
	grid[exit_cell.y][width - 1] = 1
	# Si prefieres abrir por abajo en vez de por la derecha, puedes usar:
	# grid[height - 1][exit_cell.x] = 1

# ---------------------------------------------------------
# Construir geometría 3D
# ---------------------------------------------------------
func _build_maze() -> void:
	var total_width: float = float(width) * cell_size
	var total_height: float = float(height) * cell_size

	# 1) Suelo grande
	if floor_scene:
		var floor_instance = floor_scene.instantiate()
		add_child(floor_instance)

		# Posicionamos el suelo en el centro del laberinto
		floor_instance.position = Vector3(total_width * 0.5, -0.5, total_height * 0.5)
		# Ajustamos el tamaño si es un CSGBox3D
		floor_instance.set("size", Vector3(total_width, 1.0, total_height))

	# 2) Paredes (bloques completos en las celdas grid[y][x] == 0)
	if wall_scene:
		for y in height:
			for x in width:
				if grid[y][x] == 0:
					var wall_instance = wall_scene.instantiate()
					add_child(wall_instance)

					var wx: float = float(x) * cell_size
					var wz: float = float(y) * cell_size

					wall_instance.position = Vector3(wx, wall_height * 0.5, wz)
					# Ajustamos tamaño del bloque de pared según cell_size y parámetros
					wall_instance.set("size", Vector3(wall_thickness, wall_height, wall_thickness))

# ---------------------------------------------------------
# Helpers para posiciones
# ---------------------------------------------------------
func get_player_start_position(height_offset: float = 2.0) -> Vector3:
	# Punto de inicio del jugador (centro de la celda start_cell)
	var wx: float = float(start_cell.x) * cell_size
	var wz: float = float(start_cell.y) * cell_size
	return Vector3(wx, height_offset, wz)

func get_exit_position(height_offset: float = 2.0) -> Vector3:
	# Punto de salida (centro de la celda exit_cell)
	var wx: float = float(exit_cell.x) * cell_size
	var wz: float = float(exit_cell.y) * cell_size
	return Vector3(wx, height_offset, wz)

func world_to_cell(world_pos: Vector3) -> Vector2i:
	var x := int(round(world_pos.x / cell_size))
	var y := int(round(world_pos.z / cell_size))
	return Vector2i(x, y)

func cell_to_world(cell: Vector2i, height_offset: float = 0.0) -> Vector3:
	return Vector3(float(cell.x) * cell_size, height_offset, float(cell.y) * cell_size)
