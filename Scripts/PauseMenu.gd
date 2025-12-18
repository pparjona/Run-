extends CanvasLayer

@export var settings_scene: PackedScene

@onready var menu_ui: Control = $MenuUI

@onready var blur_overlay: ColorRect = $BlurOverlay 

var settings_instance: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _on_resume_button_pressed() -> void:
	GameManager.resume_game()

func _on_quit_button_pressed() -> void:
	GameManager.return_to_menu_from_pause()

# --- LÓGICA DE SETTINGS ---
func _on_setting_button_pressed() -> void:
	if settings_scene == null:
		push_error("PauseMenu: settings_scene not assigned.")
		return
	if settings_instance != null:
		return 

	menu_ui.visible = false 

	settings_instance = settings_scene.instantiate()
	settings_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	settings_instance.layer = 100 
	
	add_child(settings_instance) 

	await get_tree().process_frame
	_patch_settings_for_pause(settings_instance)

func _patch_settings_for_pause(s: CanvasLayer) -> void:
	var box = s.get_node_or_null("MarginContainer/VBoxContainer")
	if not box: return

	if box.has_node("DifficultyLabel"): box.get_node("DifficultyLabel").visible = false
	if box.has_node("DifficultButton"): box.get_node("DifficultButton").visible = false
	if box.has_node("HSeparator"): box.get_node("HSeparator").visible = false

	var back_btn: Button = box.get_node_or_null("BackButton")
	if back_btn:
		var old_connections = back_btn.pressed.get_connections()
		for conn in old_connections:
			back_btn.pressed.disconnect(conn["callable"])
		
		back_btn.pressed.connect(_on_pause_settings_back_pressed)

func _on_pause_settings_back_pressed() -> void:
	if settings_instance != null:
		settings_instance.queue_free()
		settings_instance = null
	
	menu_ui.visible = true
