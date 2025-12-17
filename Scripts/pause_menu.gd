extends CanvasLayer

@export var settings_scene: PackedScene

@onready var resume_button: Button = $MenuUI/MarginContainer/VBoxContainer/ResumeButton
@onready var settings_button: Button = $MenuUI/MarginContainer/VBoxContainer/SettingButton
@onready var quit_button: Button = $MenuUI/MarginContainer/VBoxContainer/QuitButton
@onready var menu_ui: Control = $MenuUI

var settings_instance: CanvasLayer = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# STATO INIZIALE: il pause menu non deve mai "partire" da solo
	visible = false
	menu_ui.visible = true

	# sicurezza: se per qualche motivo esiste già un settings, lo eliminiamo
	if settings_instance:
		settings_instance.queue_free()
		settings_instance = null

func _pause() -> void:
	visible = true
	get_tree().paused = true

func _resume() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_button_pressed() -> void:
	_resume()

func _on_setting_button_pressed() -> void:
	if not visible:
		return
	if not get_tree().paused:
		return

	if settings_scene == null:
		push_error("PauseMenu: settings_scene not assigned.")
		return
	if settings_instance != null:
		return

	menu_ui.visible = false

	settings_instance = settings_scene.instantiate()
	settings_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().current_scene.add_child(settings_instance)

	await get_tree().process_frame
	_patch_settings_for_pause(settings_instance)

func _patch_settings_for_pause(s: CanvasLayer) -> void:
	var box := s.get_node("MarginContainer/VBoxContainer")


	box.get_node("DifficultyLabel").visible = false
	box.get_node("DifficultButton").visible = false
	box.get_node("HSeparator").visible = false

	var back_btn: Button = box.get_node("BackButton")
	var old_cb := Callable(s, "_on_back_pressed")
	if back_btn.pressed.is_connected(old_cb):
		back_btn.pressed.disconnect(old_cb)
	back_btn.pressed.connect(_on_pause_settings_back_pressed)

func _on_pause_settings_back_pressed() -> void:
	if settings_instance != null:
		settings_instance.queue_free()
		settings_instance = null
	menu_ui.visible = true

func _on_quit_button_pressed() -> void:
	get_tree().quit()
