# En tu Camera2D principal
extends Camera2D

func _ready():
	# Registrar esta cámara en el ScreenShakeManager
	process_mode = Node.PROCESS_MODE_ALWAYS
	ScreenShakeManager.register_camera(self)
