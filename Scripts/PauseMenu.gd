extends CanvasLayer

@export var settings_scene: PackedScene

@onready var menu_ui: Control = $MenuUI

var settings_instance: CanvasLayer = null

func _ready() -> void:
	# Importante: El menú de pausa debe procesarse cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED 

func _on_resume_button_pressed() -> void:
	# Delegamos la lógica al GameManager
	GameManager.resume_game()

func _on_quit_button_pressed() -> void:
	get_tree().quit()

# --- LÓGICA DE SETTINGS (Mantenemos tu lógica de "parcheo", es buena) ---
func _on_setting_button_pressed() -> void:
	if settings_scene == null:
		push_error("PauseMenu: settings_scene not assigned.")
		return
	if settings_instance != null:
		return # Ya están abiertos

	menu_ui.visible = false # Ocultamos los botones de pausa

	settings_instance = settings_scene.instantiate()
	# Nos aseguramos que los settings también funcionen en pausa
	settings_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED 
	add_child(settings_instance) # Lo añadimos como hijo de este CanvasLayer

	await get_tree().process_frame
	_patch_settings_for_pause(settings_instance)

func _patch_settings_for_pause(s: CanvasLayer) -> void:
	# Buscamos los nodos con seguridad
	var box = s.get_node_or_null("MarginContainer/VBoxContainer")
	if not box: return

	# Ocultamos lo que no queremos ver en pausa
	if box.has_node("DifficultyLabel"): box.get_node("DifficultyLabel").visible = false
	if box.has_node("DifficultButton"): box.get_node("DifficultButton").visible = false
	if box.has_node("HSeparator"): box.get_node("HSeparator").visible = false

	# Cambiamos el comportamiento del botón Atrás
	var back_btn: Button = box.get_node_or_null("BackButton")
	if back_btn:
		# Desconectamos la señal original que volvería al MenuUi.tscn
		var old_connections = back_btn.pressed.get_connections()
		for conn in old_connections:
			back_btn.pressed.disconnect(conn["callable"])
		
		# Conectamos nuestra propia función
		back_btn.pressed.connect(_on_pause_settings_back_pressed)

func _on_pause_settings_back_pressed() -> void:
	if settings_instance != null:
		settings_instance.queue_free()
		settings_instance = null
	
	# Volvemos a mostrar el menú de pausa principal
	menu_ui.visible = true
