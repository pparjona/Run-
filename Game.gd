extends Node3D

@onready var maze: Maze = $Maze
@onready var player: Node3D = $Player

func _ready() -> void:
	var start_pos: Vector3 = maze.get_player_start_position(2.0)
	player.global_position = start_pos
