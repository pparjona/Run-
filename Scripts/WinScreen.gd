extends CanvasLayer

@onready var menu_button: Button = $MarginContainer/VBoxContainer/MenuButton
@onready var exit_button: Button = $MarginContainer/VBoxContainer/ExitButton
@onready var finish_music: AudioStreamPlayer2D = $FinishMusic


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	finish_music.play()

func _on_menu_button_pressed() -> void:
	GameManager.goto_menu()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
