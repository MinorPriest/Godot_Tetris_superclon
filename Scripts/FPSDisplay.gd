extends CanvasLayer

@onready var fps_label: Label
var show_fps: bool = false

func _ready():
	# Crear el Label dinámicamente
	fps_label = Label.new()
	fps_label.name = "FPSLabel"
	add_child(fps_label)
	
	# Configurar posición y estilo
	fps_label.position = Vector2(20, 20)
	fps_label.modulate = Color.CYAN
	fps_label.add_theme_font_size_override("font_size", 20)
	
	# Configurar el texto inicial
	fps_label.text = "FPS: --"
	fps_label.visible = show_fps
	
	print("✅ FPS Display inicializado - Presiona F11 para mostrar/ocultar")

func _process(_delta):
	if show_fps:
		var current_fps = Engine.get_frames_per_second()
		fps_label.text = "FPS: " + str(current_fps)
		
		# Color dinámico según performance
		if current_fps >= 55:
			fps_label.modulate = Color.GREEN
		elif current_fps >= 30:
			fps_label.modulate = Color.YELLOW
		else:
			fps_label.modulate = Color.RED

func _input(event):
	# Toggle con F11
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		show_fps = !show_fps
		fps_label.visible = show_fps
		print("🎮 FPS Display: ", "ON" if show_fps else "OFF")
		
		
