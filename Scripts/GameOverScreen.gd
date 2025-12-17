extends CanvasLayer

@onready var menu_button: Button = $MarginContainer/VBoxContainer/MenuButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_menu_button_pressed() -> void:
	GameManager.goto_menu()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
