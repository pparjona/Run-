extends CanvasLayer

@onready var health_bar: ProgressBar = $LeftContainer/VBoxContainer/HealthBar
@onready var ammo_value: Label = $RightContainer/AmmoRow/AmmoValue

var _has_gun: bool = false

func _ready() -> void:
	health_bar.min_value = 0
	ammo_value.text = "--"
	ammo_value.visible = false  # oculto al inicio

	# Registrarse en el GameManager
	GameManager.register_hud(self)


func update_health(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current


func set_has_gun(has_gun: bool) -> void:
	_has_gun = has_gun

	if has_gun:
		ammo_value.visible = true   # mostramos el texto de munición
	else:
		ammo_value.visible = false  # ocultamos la munición
		ammo_value.text = "--"


func update_ammo(current_clip: int, reserve: int) -> void:
	# Si aún no tienes arma, ignoramos la actualización
	if not _has_gun:
		return

	ammo_value.text = "%d / %d" % [current_clip, reserve]
