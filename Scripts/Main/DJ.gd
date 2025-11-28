extends Node

# Referencias
var main
var background_music: AudioStreamPlayer2D

# Lista de pistas
var music_tracks: Array[String] = [
	"res://Sounds/Track1.mp3",
	"res://Sounds/Track2.mp3", 
	"res://Sounds/Track3.mp3",
	"res://Sounds/Track4.mp3",
	"res://Sounds/Track5.mp3"
]
var current_track_index: int = 0
var played_tracks: Array[int] = []  # Para evitar repeticiones consecutivas

func initialize(main_node) -> void:
	main = main_node
	
	# Inicializar random
	randomize()
	
	# Obtener referencia al nodo BackgroundMusic de la escena
	background_music = main.get_node("BackgroundMusic")
	
	if background_music:
		print("🎵 BackgroundMusic encontrado en escena")
	else:
		print("❌ No se encontró el nodo BackgroundMusic en la escena")

func setup_background_music() -> void:
	if music_tracks.is_empty():
		print("❌ No hay pistas de música configuradas")
		return
	
	# Cargar una pista aleatoria
	load_random_track()
	
	# CONFIGURACIÓN
	background_music.volume_db = 0.0
	background_music.autoplay = true
	
	# Conectar la señal de finished (solo si no está conectada)
	if not background_music.finished.is_connected(_on_background_music_finished):
		background_music.finished.connect(_on_background_music_finished)
	
	# FORZAR REPRODUCCIÓN - CORRECCIÓN: Detener primero si está reproduciendo
	if background_music.playing:
		background_music.stop()
	
	background_music.play()
	
	print("🎵 Música ALEATORIA iniciada")
	print("🎵 Pista actual: ", music_tracks[current_track_index].get_file())

func load_random_track() -> void:
	if music_tracks.is_empty():
		return
	
	var available_indices = []
	
	# Crear lista de índices disponibles (evitando la última reproducida)
	for i in range(music_tracks.size()):
		if not played_tracks.has(i) or played_tracks.size() >= music_tracks.size():
			available_indices.append(i)
	
	# Si no hay disponibles, reiniciar
	if available_indices.is_empty():
		available_indices = range(music_tracks.size())
		played_tracks.clear()
		print("🎵 Reiniciando lista de pistas reproducidas")
	
	# Seleccionar aleatoriamente
	var random_index = available_indices[randi() % available_indices.size()]
	
	# Cargar la pista
	var track_path = music_tracks[random_index]
	var stream = load(track_path)
	
	if stream:
		background_music.stream = stream
		current_track_index = random_index
		
		# Agregar a la lista de reproducidas
		played_tracks.append(random_index)
		
		print("🎵 Pista aleatoria seleccionada: ", track_path.get_file())
		print("🎵 Índice: ", random_index)
	else:
		print("❌ No se pudo cargar: ", track_path)

func _on_background_music_finished() -> void:
	print("🎵 Canción terminada - Seleccionando siguiente aleatoria")
	load_random_track()
	background_music.play()
	print("🎵 Nueva pista: ", music_tracks[current_track_index].get_file())

func stop_background_music() -> void:
	if background_music and background_music.playing:
		background_music.stop()
		played_tracks.clear()  # Limpiar historial al detener
		print("⏹️ Música detenida - Historial limpiado")

# Función para cambiar manualmente a una pista aleatoria
func play_random_track() -> void:
	if background_music:
		background_music.stop()
		load_random_track()
		background_music.play()
		print("🎵 Cambio manual a pista aleatoria")

# Función para obtener información de la pista actual
func get_current_track_info() -> String:
	if music_tracks.size() > current_track_index:
		return music_tracks[current_track_index].get_file()
	return "No hay pista cargada"

func play_sound(sound_name: String) -> void:
	var sound_resources = {
		"piece_land": preload("res://sounds/piece_land.mp3"),
		"selectionScreen": preload("res://Sounds/RetroSound.mp3"),
		"player_1": preload("res://sounds/player_1.mp3"),
		"player_2": preload("res://Sounds/player_2.mp3"),
		"match": preload("res://sounds/match.mp3"),
		"attack_land": preload("res://sounds/attack_land.mp3"),
		"game_over_win": preload("res://sounds/game_over_win.mp3"),
		"menu_move": preload("res://Sounds/menu_move.mp3"),
		"menu_select": preload("res://Sounds/menu_select.mp3"),
		"game_start": preload("res://sounds/game_start.mp3"),
		"attack_launch": preload("res://sounds/attack_launch.mp3"),
		#"charge_gained": preload("res://sounds/charge_gained.mp3"),
		#"game_pause": preload("res://sounds/game_pause.mp3"),
		#"game_resume": preload("res://sounds/game_resume.mp3"),
		#"game_over_draw": preload("res://sounds/game_over_draw.mp3")
	}
	
	if sound_resources.has(sound_name):
		var audio_player = AudioStreamPlayer2D.new()
		audio_player.stream = sound_resources[sound_name]
		audio_player.autoplay = true
		main.add_child(audio_player)
		audio_player.finished.connect(_on_sound_finished.bind(audio_player))
		print("🔊 Sonido: ", sound_name)

func _on_sound_finished(audio_player: AudioStreamPlayer2D) -> void:
	audio_player.queue_free()
