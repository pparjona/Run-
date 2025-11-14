extends Node3D

signal player_escaped

@onready var exit_area: Area3D = $ExitArea

func _ready() -> void:
	exit_area.body_entered.connect(_on_exit_area_body_entered)

func _on_exit_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		print("¡Has escapado del laberinto!")
		player_escaped.emit()
