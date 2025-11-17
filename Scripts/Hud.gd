extends CanvasLayer

@onready var health_text: Label = $LeftContainer/VBoxContainer/HealthText
@onready var health_bar: ProgressBar = $LeftContainer/VBoxContainer/HealthBar
@onready var ammo_text: Label = $RightContainer/AmmoRow/AmmoText
@onready var ammo_value: Label = $RightContainer/AmmoRow/AmmoValue



func _ready() -> void:
	health_bar.min_value = 0
	ammo_text.text = "Munición:"
	ammo_value.text = "--"

	# Registrarse en el GameManager
	GameManager.register_hud(self)


func update_health(current: int, max: int) -> void:
	health_bar.max_value = max
	health_bar.value = current
	#health_text.text = "Health: %d / %d" % [current, max]


func set_has_gun(has_gun: bool) -> void:
	# De momento solo mostramos "--" siempre; más adelante
	# aquí podrías cambiar el estilo cuando tengas arma.
	if not has_gun:
		ammo_value.text = "--"


func update_ammo(current: int, max: int) -> void:
	if max > 0:
		ammo_value.text = "%d / %d" % [current, max]
	else:
		ammo_value.text = "--"
