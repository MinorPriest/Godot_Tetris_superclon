# ScreenShakeManager.gd
extends Node

var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_fade: float = 8.0

var rng = RandomNumberGenerator.new()
var cameras: Array[Camera2D] = []

func _ready():
	rng.randomize()
	# IMPORTANTE: Hacer que este nodo funcione incluso cuando el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("✅ ScreenShakeManager INICIALIZADO (PROCESS_MODE_ALWAYS)")

func _process(delta):
	if shake_duration > 0 and not cameras.is_empty():
		shake_duration -= delta
		
		# Aplicar shake
		for camera in cameras:
			if is_instance_valid(camera):
				camera.offset = Vector2(
					rng.randf_range(-1.0, 1.0) * shake_intensity,
					rng.randf_range(-1.0, 1.0) * shake_intensity
				)
		
		# Reducir intensidad gradualmente
		shake_intensity = lerp(shake_intensity, 0.0, shake_fade * delta)
		
		# Debug cada 5 frames - CORREGIDO
		if Engine.get_frames_drawn() % 5 == 0:
			var current_offset = cameras[0].offset if cameras.size() > 0 else Vector2.ZERO
			print("🎬 SHAKE ACTIVO - Dur: " + str(shake_duration) + ", Int: " + str(shake_intensity) + ", Offset: " + str(current_offset))
			
	elif shake_duration <= 0 and shake_intensity > 0:
		# Restablecer offsets cuando termina el shake
		for camera in cameras:
			if is_instance_valid(camera):
				camera.offset = Vector2.ZERO
		print("🎬 SHAKE TERMINADO - Offset restablecido")
		shake_intensity = 0.0

# Registrar cámara
func register_camera(camera: Camera2D):
	if not camera in cameras:
		cameras.append(camera)
		print("✅ Cámara registrada: ", camera.name)

# Screen shake con valores optimizados
func apply_shake(duration: float = 0.8, intensity: float = 15.0):
	shake_duration = duration
	shake_intensity = intensity
	print("🎯 SHAKE APLICADO - Dur: " + str(duration) + "s, Int: " + str(intensity))

func attack_shake():
	print("🎉 VICTORY SHAKE")
	apply_shake(0.5, 8.0)

func game_over_shake():
	print("💀 GAME OVER SHAKE")
	apply_shake(1.5, 18.0)
