extends Node

enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

var state: GameState = GameState.MENU

# Rutas de escenas principales (se usarán más adelante)
const MAIN_MENU_SCENE := "res://Scenes/MenuUi.tscn"
const GAME_SCENE      := "res://Scenes/Game.tscn"
const SETTINGS_SCENE  := "res://Scenes/Settings.tscn"
const END_SCENE       := "res://Scenes/EndScreen.tscn"

var menu_music_stream = preload("res://Sounds/Musica/musicaMenu2.mp3")
var game_music_stream = preload("res://Sounds/Musica/musicaAmbiente.mp3")
var music_player: AudioStreamPlayer

# Ejemplo de datos globales que pueden interesar
var difficulty: int = 1
var master_volume: float = 1.0

signal state_changed(old_state: GameState, new_state: GameState)

# REFERENCIAS GLOBALES
var player: Node = null
var hud: CanvasLayer = null

func _ready() -> void:
	if state == GameState.MENU:
		_play_music(menu_music_stream)

# -------------------------
# CAMBIO DE ESCENAS
# -------------------------
func _change_scene(path: String, new_state: GameState) -> void:
	var old := state
	state = new_state
	get_tree().change_scene_to_file(path)
	state_changed.emit(old, new_state)


func goto_menu() -> void:
	_play_music(menu_music_stream)
	_change_scene(MAIN_MENU_SCENE, GameState.MENU)


func start_game() -> void:
	_play_music(game_music_stream)
	_change_scene(GAME_SCENE, GameState.PLAYING)


func goto_settings() -> void:
	_play_music(menu_music_stream)
	_change_scene(SETTINGS_SCENE, GameState.MENU)


func game_over() -> void:
	_destroy_music()
	_change_scene(END_SCENE, GameState.GAME_OVER)


func game_won() -> void:
	_destroy_music()
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
# LÓGICA DE MÚSICA
# -------------------------
func _play_music(stream_to_play: AudioStream) -> void:
	# 1. Calculamos el volumen correcto para esta canción
	var target_db = _calculate_volume_db(stream_to_play)
	# 2. Si ya existe el reproductor
	if music_player != null:
		if music_player.stream == stream_to_play and music_player.playing:
			# Si es la misma canción, solo actualizamos el volumen (por si cambió el master)
			music_player.volume_db = target_db
			return
		else:
			# Cambio de canción: paramos, cambiamos stream y volumen
			music_player.stop()
			music_player.stream = stream_to_play
			music_player.volume_db = target_db
			music_player.play()
	# 3. Si no existe, lo creamos
	else:
		music_player = AudioStreamPlayer.new()
		add_child(music_player)
		music_player.stream = stream_to_play
		music_player.bus = "Master"
		music_player.volume_db = target_db
		music_player.play()

func _destroy_music() -> void:
	# Si existe, lo eliminamos por completo para ahorrar recursos
	if music_player != null:
		music_player.stop()
		music_player.queue_free()
		music_player = null

func _calculate_volume_db(stream: AudioStream) -> float:
	var base_db = linear_to_db(master_volume)
	if stream == game_music_stream:
		return (base_db - 8.0)
	
	# Si es cualquier otra (menú), usamos el volumen master tal cual
	return base_db
# -------------------------
# REGISTRO DE PLAYER Y HUD
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
	player.health_changed.connect(hud.update_health)
	player.gun_equipped.connect(hud.set_has_gun)
	player.ammo_changed.connect(hud.update_ammo)

	# Estado inicial en el HUD
	hud.update_health(player.health, player.max_health)
	hud.set_has_gun(player.has_gun)
	# Aquí cambiamos max_ammo_in_clip por reserve_ammo
	hud.update_ammo(player.current_ammo_in_clip, player.reserve_ammo)


# -------------------------
# EVENTOS GLOBALES DEL JUEGO
# -------------------------
func on_player_died() -> void:
	print("GameManager: el jugador ha muerto")
	# Más adelante: game_over()


func on_player_escaped() -> void:
	print("GameManager: el jugador ha escapado")
	game_won()
