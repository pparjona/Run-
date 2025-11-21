extends Area3D

@export var ammo_amount: int = 10

func _ready() -> void:
	# Para que el player pueda reconocerlo como munición
	add_to_group("AmmoPickup")

func set_ammo_amount(amount: int) -> void:
	ammo_amount = max(amount, 0)

func collect(player: Node) -> void:
	if player != null and player.has_method("add_ammo"):
		player.add_ammo(ammo_amount)
	queue_free()
