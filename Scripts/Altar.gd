extends Node3D

signal player_entered_plaza

@onready var plaza_trigger: Area3D = $PlazaTrigger

func _ready() -> void:
	print("Altar.gd READY, trigger =", plaza_trigger)
	plaza_trigger.body_entered.connect(_on_plaza_trigger_body_entered)

func _on_plaza_trigger_body_entered(body: Node) -> void:
	print("Altar: body_entered ->", body.name, "groups:", body.get_groups())
	if body.is_in_group("Player"):
		print("Altar: player ha entrado en la plaza, emitiendo señal")
		player_entered_plaza.emit()

		# Desactivar el trigger para que no dispare más veces
		# (deferred porque estamos dentro del callback de señal)
		plaza_trigger.set_deferred("monitoring", false)
		plaza_trigger.set_deferred("monitorable", false)
