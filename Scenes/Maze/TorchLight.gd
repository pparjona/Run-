extends OmniLight3D

@export var base_energy: float = 0.8
@export var flicker_amount: float = 0.2
@export var flicker_speed: float = 6.0

var t: float = 0.0

func _ready() -> void:
	light_energy = base_energy

func _process(delta: float) -> void:
	t += delta * flicker_speed
	var noise := sin(t) * 0.5 + 0.5
	light_energy = base_energy + (noise - 0.5) * flicker_amount
