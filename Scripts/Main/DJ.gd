extends Node

# Referencias
var main

# Recursos de sonido
var sound_resources: Dictionary = {}

func initialize(main_node) -> void:
	main = main_node
	
	# Cargar recursos de sonido (ajusta las rutas según tu proyecto)
	sound_resources = {
		#"piece_land": preload("res://sounds/piece_land.wav"),
		#"match": preload("res://sounds/match.wav"),
		#"charge_gained": preload("res://sounds/charge_gained.wav"),
		#"attack_launch": preload("res://sounds/attack_launch.wav"),
		#"attack_land": preload("res://sounds/attack_land.wav"),
		#"game_over_win": preload("res://sounds/game_over_win.wav"),
		#"game_over_draw": preload("res://sounds/game_over_draw.wav"),
		#"game_start": preload("res://sounds/game_start.wav"),
		#"game_pause": preload("res://sounds/game_pause.wav"),
		#"game_resume": preload("res://sounds/game_resume.wav")
	}
	
	print("DJ inicializado - Listo para recibir señales de sonido")

func play_sound(sound_name: String) -> void:
	if sound_resources.has(sound_name):
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = sound_resources[sound_name]
		audio_player.autoplay = true
		add_child(audio_player)
		
		# Limpiar después de reproducir
		audio_player.finished.connect(_on_sound_finished.bind(audio_player))
		
		print("DJ: Reproduciendo sonido - ", sound_name)
	else:
		print("DJ: Sonido no encontrado - ", sound_name)

func _on_sound_finished(audio_player: AudioStreamPlayer) -> void:
	audio_player.queue_free()
