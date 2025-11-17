extends CanvasLayer

@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton
@onready var settings_button: Button = $MarginContainer/VBoxContainer/SettingButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton


func _ready() -> void:
	GameManager.state = GameManager.GameState.MENU


func _on_start_button_pressed() -> void:
	GameManager.start_game()


func _on_setting_button_pressed() -> void:
	GameManager.goto_settings()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
