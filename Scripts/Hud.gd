extends CanvasLayer

@onready var health_bar: ProgressBar = $LeftContainer/VBoxContainer/HealthBar
@onready var ammo_value: Label = $RightContainer/AmmoRow/AmmoValue



func _ready() -> void:
	health_bar.min_value = 0
	ammo_value.text = "--"

	# Registrarse en el GameManager
	GameManager.register_hud(self)


func update_health(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current


func set_has_gun(has_gun: bool) -> void:
	# De momento solo mostramos "--" siempre; más adelante
	# aquí podrías cambiar el estilo cuando tengas arma.
	if not has_gun:
		ammo_value.text = "--"


func update_ammo(current: int, max_ammo: int) -> void:
	if max_ammo > 0:
		ammo_value.text = "%d / %d" % [current, max_ammo]
	else:
		ammo_value.text = "--"
