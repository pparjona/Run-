extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

var state: GameState = GameState.MENU

# Rutas de escenas principales (se usarán más adelante)
const MAIN_MENU_SCENE := "res://Scenes/MenuUi.tscn"
const GAME_SCENE      := "res://Scenes/Game.tscn"
const SETTINGS_SCENE  := "res://Scenes/Settings.tscn"
const END_SCENE       := "res://Scenes/EndScreen.tscn"

# Ejemplo de datos globales que pueden interesar
var difficulty: int = 1
var master_volume: float = 1.0

signal state_changed(old_state: GameState, new_state: GameState)

# REFERENCIAS GLOBALES (NUEVO)
var player: Node = null
var hud: CanvasLayer = null


# -------------------------
# CAMBIO DE ESCENAS (para más adelante)
# -------------------------
func _change_scene(path: String, new_state: GameState) -> void:
	var old := state
	state = new_state
	get_tree().change_scene_to_file(path)
	state_changed.emit(old, new_state)


func goto_menu() -> void:
	_change_scene(MAIN_MENU_SCENE, GameState.MENU)


func start_game() -> void:
	_change_scene(GAME_SCENE, GameState.PLAYING)

func goto_settings() -> void:
	_change_scene(SETTINGS_SCENE, GameState.MENU)

func game_over() -> void:
	_change_scene(END_SCENE, GameState.GAME_OVER)

func game_won() -> void:
	_change_scene(END_SCENE, GameState.VICTORY)


func pause_game() -> void:
	if state == GameState.PLAYING:
		get_tree().paused = true
		var old := state
		state = GameState.PAUSED
		state_changed.emit(old, state)


func resume_game() -> void:
	if state == GameState.PAUSED:
		get_tree().paused = false
		var old := state
		state = GameState.PLAYING
		state_changed.emit(old, state)


# -------------------------
# REGISTRO DE PLAYER Y HUD  (NUEVO)
# -------------------------
func register_player(p: Node) -> void:
	player = p
	_connect_player_to_hud()


func register_hud(h: CanvasLayer) -> void:
	hud = h
	_connect_player_to_hud()


func _connect_player_to_hud() -> void:
	if player == null or hud == null:
		return

	# Conexiones de señales Player -> HUD
	# (suponiendo que el player tiene esas señales)
	player.health_changed.connect(hud.update_health)
	player.gun_equipped.connect(hud.set_has_gun)
	player.ammo_changed.connect(hud.update_ammo)

	# Forzamos estado inicial en el HUD
	hud.update_health(player.health, player.max_health)
	hud.set_has_gun(player.has_gun)
	hud.update_ammo(player.current_ammo_in_clip, player.max_ammo_in_clip)


# -------------------------
# EVENTOS GLOBALES DEL JUEGO (NUEVO)
# -------------------------
func on_player_died() -> void:
	print("GameManager: el jugador ha muerto")
	# MÁS ADELANTE: aquí llamaremos a game_over() cuando exista la escena final
	# game_over()


func on_player_escaped() -> void:
	print("GameManager: el jugador ha escapado")
	# MÁS ADELANTE: aquí llamaremos a game_won() cuando exista la escena final
	# game_won()
