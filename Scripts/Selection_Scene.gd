extends Node2D

# Módulos
var piece_logic
var referee
var hud
var dj

# Posiciones de los botones del menú
var button_positions = {
	"VS_Mode": Vector2(192, 352),
	"CPU_Mode": Vector2(192, 416),
	"Profiles": Vector2(192, 480),
	"Options": Vector2(192, 544)
}

# Array con el orden de los botones
var button_order = ["VS_Mode", "CPU_Mode", "Profiles", "Options"]
var current_selection = 0
var selector: AnimatedSprite2D

func _ready():
	print("Inicializando menú...")
	
	# NUEVO: Cargar automáticamente los últimos perfiles usados
	if ProfileManager:
		ProfileManager.auto_load_last_profiles()
		print("🔄 Últimos perfiles cargados automáticamente")
	
	# Inicializar módulo DJ
	initialize_dj()
	
	# NUEVO: Reproducir música específica para SelectionScreen
	play_selection_screen_music()
	
	# Configurar selector
	selector = $Title_Selector
	print("Posición inicial del selector: ", selector.position)
	selector.position = Vector2(192, 352)
	print("Posición después de _ready: ", selector.position)
	current_selection = 0
	
	print("🎵 Menú principal listo con música de fondo")

func initialize_dj():
	# Crear instancia del módulo DJ
	dj = preload("res://Scripts/Main/DJ.gd").new()
	dj.initialize(self)
	print("🎵 Módulo DJ inicializado")

# NUEVA FUNCIÓN: Reproducir música de SelectionScreen
func play_selection_screen_music():
	if dj:
		# Detener cualquier música anterior si es necesario
		if dj.has_method("stop_background_music"):
			dj.stop_background_music()
		
		# Reproducir música específica para SelectionScreen
		dj.play_sound("selectionScreen")
		print("🎵 Música SelectionScreen iniciada")

func _input(event):
	# Movimiento hacia arriba
	if event.is_action_pressed("p1_rotate"):
		current_selection = (current_selection - 1) % button_order.size()
		update_selector_position()
		# Reproducir sonido de navegación
		if dj:
			dj.play_sound("menu_move")
	
	# Movimiento hacia abajo
	elif event.is_action_pressed("p1_down"):
		current_selection = (current_selection + 1) % button_order.size()
		update_selector_position()
		# Reproducir sonido de navegación
		if dj:
			dj.play_sound("menu_move")
	
	# Seleccionar con ENTER - SOLO para opciones activas
	elif event.is_action_pressed("p1_enter") or event.is_action_pressed("p1_accept"):
		var current_option = button_order[current_selection]
		
		# Solo procesar selección para opciones activas
		if current_option == "VS_Mode":
			# Reproducir sonido de selección
			if dj:
				dj.play_sound("menu_select")
			await get_tree().create_timer(3.2).timeout  # Delay más corto
			select_option()
		elif current_option == "Profiles":
			await get_tree().create_timer(0.8).timeout  # Delay más corto
			select_option()
		
		else:
			# Para opciones inactivas, reproducir sonido de error o nada
			print("⏸️  Opción no disponible: ", current_option)
			# Opcional: reproducir sonido de error si quieres
			# if dj:
			#     dj.play_sound("error_sound")

func update_selector_position():
	# Mover el selector a la posición actual
	var current_button = button_order[current_selection]
	selector.position = button_positions[current_button]
	print("Selector movido a: ", current_button, " - Posición: ", selector.position)

func select_option():
	var selected_option = button_order[current_selection]
	
	match selected_option:
		"VS_Mode":
			print("Seleccionado: VS Mode")
			# Detener música de SelectionScreen antes de cambiar
			if dj and dj.has_method("stop_background_music"):
				dj.stop_background_music()
			# Reproducir sonido de inicio de juego
			if dj:
				dj.play_sound("game_start")
			# Cambiar a escena VS Mode
			get_tree().change_scene_to_file("res://Scenes/Main.tscn")
		
		"CPU_Mode":
			# Esta opción no debería ejecutarse nunca porque está bloqueada en _input
			print("❌ ERROR: CPU_Mode no debería ser seleccionable")
		
		"Profiles":
			print("Seleccionado: Profiles")
			# Detener música de SelectionScreen antes de cambiar
			if dj and dj.has_method("stop_background_music"):
				dj.stop_background_music()
			# Cambiar a escena Profiles
			get_tree().change_scene_to_file("res://Scenes/ProfileMuseum.tscn")
		
		"Options":
			# Esta opción no debería ejecutarse nunca porque está bloqueada en _input
			print("❌ ERROR: Options no debería ser seleccionable")

# Función para obtener la selección actual
func get_current_selection() -> String:
	return button_order[current_selection]

# Función para detener la música cuando sea necesario
func stop_music():
	if dj:
		dj.stop_background_music()

# Función para cambiar manualmente la música
func change_music_track():
	if dj:
		dj.play_random_track()
