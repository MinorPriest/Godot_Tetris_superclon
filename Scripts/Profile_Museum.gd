extends Node2D

# Variables para los jugadores
var p1_selected_profile: int = -1
var p2_selected_profile: int = -1
var p1_cursor_pos: int = 0
var p2_cursor_pos: int = 0
var editing_profile: bool = false
var current_editing_player: int = 0
var current_editing_index: int = 0
var current_editing_char: int = 0

# Sistema de edición de nombres mejorado
var alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 !@#$%&*-_=+"
var editing_name: String = ""
var editing_char_index: int = 0

# Sistema de regreso al menú
var p1_back_timer: float = 0.0
var p2_back_timer: float = 0.0
const BACK_HOLD_TIME: float = 3.0
var showing_back_hint: bool = false

# Nodos de los cursores
@onready var p1_cursor = $P1Cursor
@onready var p2_cursor = $P2Cursor

# Nodos de las etiquetas
@onready var labels = [
	$Label1, $Label2, $Label3, $Label4, $Label5, $Label6, $Label7
]

# Nodos de los stats
@onready var stats_label1 = $StatsLabel1
@onready var stats_label2 = $StatsLabel2

# NUEVO: Nodo para mostrar editor de nombres y hint de regreso
@onready var edit_display = $EditDisplay
@onready var back_hint_label = $BackHintLabel

# NUEVO: Referencia al DJ
var dj

# Posiciones de los perfiles
var profile_positions = [
	Vector2(80, 120),   # Perfil 1
	Vector2(240, 120),  # Perfil 2
	Vector2(408, 120),  # Perfil 3
	Vector2(568, 120),  # Perfil 4
	Vector2(736, 120),  # Perfil 5
	Vector2(896, 120),  # Perfil 6
	Vector2(1064, 120)  # Perfil 7
]

func _ready():
	# CORREGIDO: No llamar load_profiles() - ya se carga automáticamente en ProfileManager
	
	# Cargar automáticamente los últimos perfiles usados
	ProfileManager.auto_load_last_profiles()
	
	# Sincronizar selecciones locales
	p1_selected_profile = ProfileManager.current_profile_p1_index
	p2_selected_profile = ProfileManager.current_profile_p2_index
	
	# Posicionar cursores en los perfiles seleccionados
	if p1_selected_profile != -1:
		p1_cursor_pos = p1_selected_profile
	if p2_selected_profile != -1:
		p2_cursor_pos = p2_selected_profile
	
	# NUEVO: Inicializar DJ usando el mismo método que Main.gd
	initialize_dj()
	
	update_cursors()
	update_stats()
	update_labels()
	
	# Ocultar editor al inicio
	if edit_display:
		edit_display.visible = false
	
	# Configurar hint de regreso
	if back_hint_label:
		back_hint_label.visible = false
		back_hint_label.text = "Mantén presionado REGRESAR"
	
	print("🎮 Museo de Perfiles listo - P1: ", ProfileManager.current_profile_p1, " | P2: ", ProfileManager.current_profile_p2)

# NUEVO: Mismo método de inicialización que Main.gd
func initialize_dj() -> void:
	dj = get_node("/root/Dj")
	
	if dj:
		print("✅ DJ encontrado en ProfileMuseum")
		
		# Inicializar DJ con referencia a self, igual que en Main.gd
		if dj.has_method("initialize"):
			dj.initialize(self)
			print("✅ DJ inicializado con referencia de ProfileMuseum")
		else:
			print("⚠️ DJ no tiene método initialize")
	else:
		print("❌ DJ no encontrado en ProfileMuseum")

func _input(event):
	if editing_profile:
		handle_editing_input(event)
	else:
		handle_normal_input(event)  # ← SIEMPRE procesar inputs normales
	
	# Manejar botones de regreso
	handle_back_buttons(event)

func handle_normal_input(event):
	# MODIFICADO: Siempre permitir movimiento, incluso con perfiles seleccionados
	
	# Movimiento P1
	if event.is_action_pressed("p1_left"):
		p1_cursor_pos = wrapi(p1_cursor_pos - 1, 0, 7)
		play_menu_move_sound()
		update_cursors()
	elif event.is_action_pressed("p1_right"):
		p1_cursor_pos = wrapi(p1_cursor_pos + 1, 0, 7)
		play_menu_move_sound()
		update_cursors()
	
	# Movimiento P2
	if event.is_action_pressed("p2_left"):
		p2_cursor_pos = wrapi(p2_cursor_pos - 1, 0, 7)
		play_menu_move_sound()
		update_cursors()
	elif event.is_action_pressed("p2_right"):
		p2_cursor_pos = wrapi(p2_cursor_pos + 1, 0, 7)
		play_menu_move_sound()
		update_cursors()
	
	# Selección P1 - Permite cambiar selección incluso si ya hay una
	if event.is_action_pressed("p1_accept"):
		if ProfileManager.select_profile(1, p1_cursor_pos):
			p1_selected_profile = p1_cursor_pos
			play_player_select_sound(1)
			update_stats()
			update_cursors()
			print("P1 seleccionó: ", ProfileManager.get_profile(p1_selected_profile).profile_name)
			check_both_selected()
		else:
			print("Este perfil ya está seleccionado!")
	
	# Selección P2 - Permite cambiar selección incluso si ya hay una
	if event.is_action_pressed("p2_accept"):
		if ProfileManager.select_profile(2, p2_cursor_pos):
			p2_selected_profile = p2_cursor_pos
			play_player_select_sound(2)
			update_stats()
			update_cursors()
			print("P2 seleccionó: ", ProfileManager.get_profile(p2_selected_profile).profile_name)
			check_both_selected()
		else:
			print("Este perfil ya está seleccionado!")
	
	# Edición P1
	if event.is_action_pressed("p1_enter"):
		start_editing(1, p1_cursor_pos)
	
	# Edición P2
	if event.is_action_pressed("p2_enter"):
		start_editing(2, p2_cursor_pos)

# NUEVAS FUNCIONES PARA SONIDOS - Usando DJ inicializado correctamente
func play_menu_move_sound():
	if dj and dj.has_method("play_sound"):
		dj.play_sound("menu_move")
		print("🔊 Sonido menu_move reproducido")
	else:
		print("❌ No se pudo reproducir menu_move - DJ no disponible")

func play_player_select_sound(player: int):
	if dj and dj.has_method("play_sound"):
		if player == 1:
			dj.play_sound("player_1")
			print("🔊 Sonido player_1 reproducido")
		else:
			dj.play_sound("player_2") 
			print("🔊 Sonido player_2 reproducido")
	else:
		print("❌ No se pudo reproducir player_", player, " - DJ no disponible")

# FUNCIÓN: Manejar botones de regreso
func handle_back_buttons(event):
	# P1 Back
	if event.is_action_pressed("p1_back"):
		p1_back_timer = 0.0
		show_back_hint()
		print("⏪ P1 BACK presionado - Mantén por 3 segundos")
	
	if event.is_action_released("p1_back"):
		p1_back_timer = 0.0
		hide_back_hint()
		print("⏪ P1 BACK liberado")
	
	# P2 Back  
	if event.is_action_pressed("p2_back"):
		p2_back_timer = 0.0
		show_back_hint()
		print("⏪ P2 BACK presionado - Mantén por 3 segundos")
	
	if event.is_action_released("p2_back"):
		p2_back_timer = 0.0
		hide_back_hint()
		print("⏪ P2 BACK liberado")

func _process(delta):
	if editing_profile:
		# Parpadeo del cursor durante edición
		var alpha = sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
		labels[current_editing_index].add_theme_color_override("font_color", Color(1, alpha, alpha))
	
	# Actualizar timers de regreso
	update_back_timers(delta)

# FUNCIÓN: Actualizar timers de regreso
func update_back_timers(delta):
	# P1 Back timer
	if Input.is_action_pressed("p1_back"):
		p1_back_timer += delta
		update_back_hint_display()
		
		if p1_back_timer >= BACK_HOLD_TIME:
			return_to_main_menu("P1")
	
	# P2 Back timer
	if Input.is_action_pressed("p2_back"):
		p2_back_timer += delta
		update_back_hint_display()
		
		if p2_back_timer >= BACK_HOLD_TIME:
			return_to_main_menu("P2")

# FUNCIÓN: Mostrar hint de regreso
func show_back_hint():
	if not showing_back_hint and back_hint_label:
		showing_back_hint = true
		back_hint_label.visible = true
		update_back_hint_display()

# FUNCIÓN: Ocultar hint de regreso
func hide_back_hint():
	if showing_back_hint and back_hint_label:
		showing_back_hint = false
		back_hint_label.visible = false

# FUNCIÓN: Actualizar display del hint de regreso
func update_back_hint_display():
	if showing_back_hint and back_hint_label:
		var progress = max(p1_back_timer, p2_back_timer) / BACK_HOLD_TIME
		var progress_text = "[" + "■".repeat(int(progress * 10)) + "□".repeat(10 - int(progress * 10)) + "]"
		back_hint_label.text = "Mantén presionado REGRESAR\n" + progress_text

# FUNCIÓN: Regresar al menú principal
func return_to_main_menu(trigger_player: String):
	print("🏠 Regresando al menú principal - Trigger: ", trigger_player)
	
	# Cambiar a escena del menú principal
	get_tree().change_scene_to_file("res://Scenes/SelectionScene.tscn")

func handle_editing_input(event):
	if event.is_action_pressed("p1_enter") or event.is_action_pressed("p2_enter"):
		finish_editing()
	elif event.is_action_pressed("p1_left") or event.is_action_pressed("p2_left"):
		current_editing_char = wrapi(current_editing_char - 1, 0, alphabet.length())
		play_menu_move_sound()  # NUEVO: Sonido al mover en editor
		update_editing_display()
	elif event.is_action_pressed("p1_right") or event.is_action_pressed("p2_right"):
		current_editing_char = wrapi(current_editing_char + 1, 0, alphabet.length())
		play_menu_move_sound()  # NUEVO: Sonido al mover en editor
		update_editing_display()
	elif event.is_action_pressed("p1_accept") or event.is_action_pressed("p2_accept"):
		# Agregar letra actual al nombre
		var current_char = alphabet[current_editing_char]
		if editing_name.length() < 12:  # Límite de caracteres
			editing_name += current_char
			play_menu_move_sound()  # NUEVO: Sonido al agregar letra
			update_editing_display()
	elif event.is_action_pressed("p1_back") or event.is_action_pressed("p2_back"):
		# Borrar última letra
		if editing_name.length() > 0:
			editing_name = editing_name.substr(0, editing_name.length() - 1)
			play_menu_move_sound()  # NUEVO: Sonido al borrar
			update_editing_display()

func start_editing(player: int, profile_index: int):
	editing_profile = true
	current_editing_player = player
	current_editing_index = profile_index
	current_editing_char = 0
	editing_name = ProfileManager.get_profile(profile_index).profile_name
	
	# Mostrar interfaz de edición
	show_edit_display()
	
	print("Editando perfil ", profile_index + 1, " para P", player)

func finish_editing():
	# Guardar el nuevo nombre
	if editing_name.strip_edges() != "":
		ProfileManager.get_profile(current_editing_index).profile_name = editing_name
		ProfileManager.save_profiles()
		print("💾 Nombre guardado: ", editing_name)
	
	editing_profile = false
	
	# Ocultar interfaz de edición
	hide_edit_display()
	
	update_labels()
	update_stats()
	print("Edición completada: ", editing_name)

func update_editing_display():
	var current_char = alphabet[current_editing_char]
	labels[current_editing_index].text = editing_name + "[" + current_char + "]"
	
	# Actualizar display de edición
	if edit_display:
		edit_display.text = "Editando: " + editing_name + "\nCarácter: [" + current_char + "]"

func show_edit_display():
	if edit_display:
		edit_display.visible = true
		update_editing_display()

func hide_edit_display():
	if edit_display:
		edit_display.visible = false

func check_both_selected():
	if ProfileManager.are_both_players_selected():
		print("✅ Ambos jugadores han seleccionado perfil")
		print("P1: ", ProfileManager.current_profile_p1)
		print("P2: ", ProfileManager.current_profile_p2)
		# Opcional: Aquí puedes agregar lógica adicional si quieres

func update_cursors():
	p1_cursor.position = profile_positions[p1_cursor_pos]
	p2_cursor.position = profile_positions[p2_cursor_pos]
	
	# Resaltar perfiles seleccionados
	for i in range(labels.size()):
		var label = labels[i]
		if i == p1_selected_profile and i == p2_selected_profile:
			label.add_theme_color_override("font_color", Color(1, 1, 0))  # Amarillo (ambos seleccionado)
		elif i == p1_selected_profile:
			label.add_theme_color_override("font_color", Color(0, 1, 1))  # Cyan (P1 seleccionado)
		elif i == p2_selected_profile:
			label.add_theme_color_override("font_color", Color(1, 0, 1))  # Magenta (P2 seleccionado)
		else:
			label.add_theme_color_override("font_color", Color(1, 1, 1))  # Blanco (no seleccionado)

func update_labels():
	for i in range(labels.size()):
		var profile = ProfileManager.get_profile(i)
		labels[i].text = profile.profile_name

func update_stats():
	# Actualizar stats para P1
	if p1_selected_profile != -1:
		var profile1 = ProfileManager.get_profile(p1_selected_profile)
		var vs_text = ""
		for vs_profile in profile1.vs_wins:
			if vs_text != "":
				vs_text += "\n"
			vs_text += "%s: %d" % [vs_profile, profile1.vs_wins[vs_profile]]
		
		stats_label1.text = "Profile: %s\nWins: %d\nLose: %d\nMax Score: %d\nVS:\n%s" % [
			profile1.profile_name, profile1.wins, profile1.losses, profile1.max_score, vs_text
		]
	else:
		stats_label1.text = "Profile: \nWins: 0\nLose: 0\nMax Score: 0\nVS:"
	
	# Actualizar stats para P2
	if p2_selected_profile != -1:
		var profile2 = ProfileManager.get_profile(p2_selected_profile)
		var vs_text = ""
		for vs_profile in profile2.vs_wins:
			if vs_text != "":
				vs_text += "\n"
			vs_text += "%s: %d" % [vs_profile, profile2.vs_wins[vs_profile]]
		
		stats_label2.text = "Profile: %s\nWins: %d\nLose: %d\nMax Score: %d\nVS:\n%s" % [
			profile2.profile_name, profile2.wins, profile2.losses, profile2.max_score, vs_text
		]
	else:
		stats_label2.text = "Profile: \nWins: 0\nLose: 0\nMax Score: 0\nVS:"
