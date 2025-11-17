extends CanvasLayer

@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/VolumeSlider
@onready var difficulty_button: OptionButton = $MarginContainer/VBoxContainer/DifficultButton
@onready var back_button: Button = $MarginContainer/VBoxContainer/BackButton


func _ready() -> void:
	# Inicializar dificultad
	_setup_difficulty_options()
	# Sincronizar con el valor actual del GameManager
	difficulty_button.selected = clamp(GameManager.difficulty, 0, difficulty_button.item_count - 1)

	# Inicializar slider de volumen
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = clamp(GameManager.master_volume, 0.0, 1.0)
	_apply_volume(volume_slider.value)

	# Conectar señales
	volume_slider.value_changed.connect(_on_volume_changed)
	difficulty_button.item_selected.connect(_on_difficulty_selected)
	back_button.pressed.connect(_on_back_pressed)


func _setup_difficulty_options() -> void:
	difficulty_button.clear()
	difficulty_button.add_item("EASY", 0)
	difficulty_button.add_item("MEDIUM", 1)
	difficulty_button.add_item("HARD", 2)


func _on_difficulty_selected(index: int) -> void:
	# index coincide con el id que hemos puesto (0,1,2)
	GameManager.difficulty = index
	print("Difficulty changed to: ", difficulty_button.get_item_text(index))


func _on_volume_changed(value: float) -> void:
	GameManager.master_volume = value
	_apply_volume(value)


func _apply_volume(value: float) -> void:
	# Aplica el volumen al bus Master (aunque aún no tengas música, esto ya funciona)
	var bus := AudioServer.get_bus_index("Master")
	var db := linear_to_db(value) if value > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus, db)


func _on_back_pressed() -> void:
	GameManager.goto_menu()
