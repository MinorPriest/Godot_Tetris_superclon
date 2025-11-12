extends Node2D

# Módulos
var piece_logic
var referee
var hud
var dj

# Nodes
@onready var p1_board: TileMapLayer = $P1Board
@onready var p1_active: TileMapLayer = $P1Active
@onready var p2_board: TileMapLayer = $P2Board
@onready var p2_active: TileMapLayer = $P2Active

# Variables de estado del juego
var game_paused: bool = false
var is_setup_phase: bool = true
var is_timer_running: bool = true
var is_game_over: bool = false  # NUEVA VARIABLE CRÍTICA

func _ready() -> void:
	print("=== INICIANDO JUEGO ===")
	initialize_modules()


	print("DEBUG: _ready() completado")

func set_setup_phase(setup: bool):
	print("🔄 MAIN: Cambiando is_setup_phase de ", is_setup_phase, " a ", setup)
	is_setup_phase = setup

func set_game_paused(paused: bool) -> void:
	print("🔄 MAIN: Cambiando game_paused de ", game_paused, " a ", paused)
	game_paused = paused

# NUEVA FUNCIÓN: Congelar juego completamente
func set_game_over(over: bool) -> void:
	print("🔄 MAIN: Cambiando is_game_over de ", is_game_over, " a ", over)
	is_game_over = over
	game_paused = over  # También pausar el juego
	
	
	if over:
		# Detener completamente las actualizaciones de física
		set_physics_process(false)
		print("🚨 JUEGO TERMINADO - Todas las actualizaciones detenidas")
		# Detener música a través del DJ
	if dj and dj.has_method("stop_background_music"):
		dj.stop_background_music()

func initialize_modules() -> void:
	# Configurar referencias a los módulos
	piece_logic = $PieceLogic
	referee = $Referee
	hud = $HUD
	dj = $DJ
	
	print("Módulos encontrados:")
	print("- PieceLogic: ", piece_logic != null)
	print("- Referee: ", referee != null)
	print("- HUD: ", hud != null)
	print("- DJ: ", dj != null)
	
	# Inicializar cada módulo
	initialize_piece_logic()
	initialize_referee()
	initialize_hud()
	initialize_dj()
	
	# Conectar señales
	connect_modules_signals()
	
	# Iniciar juego
	if referee and referee.has_method("setup_game"):
		referee.setup_game()

func initialize_piece_logic() -> void:
	if piece_logic and piece_logic.has_method("initialize"):
		piece_logic.initialize(self, p1_board, p1_active, p2_board, p2_active)
		print("PieceLogic inicializado")
		
		# VERIFICAR QUE TENGA TODOS LOS MÉTODOS NECESARIOS
		var required_methods = ["setup_initial_pieces", "setup_shared_sequence", "select_random_preset", "setup_preset_positions", "update"]
		for method in required_methods:
			if piece_logic.has_method(method):
				print("✅ PieceLogic tiene método: ", method)
			else:
				print("❌ PieceLogic NO tiene método: ", method)
		
		# CONECTAR SEÑAL PARA SABER CUANDO TERMINA EL SETUP
		if piece_logic.has_signal("setup_phase_finished"):
			piece_logic.connect("setup_phase_finished", Callable(self, "_on_setup_phase_finished"))
			print("✅ Señal setup_phase_finished conectada")
		else:
			print("❌ PieceLogic no tiene señal setup_phase_finished")

func initialize_referee() -> void:
	if referee and referee.has_method("initialize"):
		referee.initialize(self, piece_logic, hud, dj)
		print("Referee inicializado")

func initialize_hud() -> void:
	if hud and hud.has_method("initialize"):
		hud.initialize(self, referee)
		print("HUD inicializado")

func initialize_dj() -> void:
	if dj and dj.has_method("initialize"):
		dj.initialize(self)
		print("DJ inicializado")

# NUEVA FUNCIÓN: Se llama cuando el juego termina
func _on_game_over(message: String) -> void:
	print("🎯 MAIN: GAME OVER - ", message)
	
	# Congelar completamente el juego
	set_game_over(true)
	
	# También congelar PieceLogic
	if piece_logic and piece_logic.has_method("set_game_over"):
		piece_logic.set_game_over(true)
	
	# Mostrar mensaje final en HUD
	if hud and hud.has_method("show_final_message"):
		hud.show_final_message(message)
	
	# Pausa global (redundante pero seguro)
	get_tree().paused = true



# NUEVA FUNCIÓN: Se llama cuando termina la fase de setup
func _on_setup_phase_finished():
	print("🎉🎉🎉 MAIN: Fase de setup TERMINADA - Activando ataques 🎉🎉🎉")
	is_setup_phase = false
	game_paused = false
	if dj and dj.has_method("play_sound"):
		dj.play_sound("game_start")
	# También actualizar referee si es necesario
	if referee and referee.has_method("_on_setup_phase_finished"):
		referee._on_setup_phase_finished()

func connect_modules_signals() -> void:
	print("Conectando señales...")
	
	# Verificar que todos los módulos existan
	if not piece_logic or not referee or not hud:
		print("ERROR: Módulos faltantes para conectar señales")
		return
	
	# VERIFICAR CONEXIÓN match_found (CRÍTICA)
	print("🔍 VERIFICANDO CONEXIÓN match_found:")
	print("PieceLogic tiene señal match_found: ", piece_logic.has_signal("match_found"))
	print("Referee tiene método _on_match_found: ", referee.has_method("_on_match_found"))
	
	if piece_logic.is_connected("match_found", Callable(referee, "_on_match_found")):
		print("✅ match_found CONECTADA correctamente")
	else:
		print("❌ match_found NO CONECTADA - reconectando...")
		_safe_connect(piece_logic, "match_found", referee, "_on_match_found")
	
	# VERIFICAR CONEXIÓN add_attack
	print("🔍 VERIFICANDO CONEXIÓN add_attack:")
	print("Referee tiene señal add_attack: ", referee.has_signal("add_attack"))
	print("PieceLogic tiene método _on_add_attack: ", piece_logic.has_method("_on_add_attack"))
	if referee.is_connected("add_attack", Callable(piece_logic, "_on_add_attack")):
		print("✅ add_attack CONECTADA correctamente")
	else:
		print("❌ add_attack NO CONECTADA - reconectando...")
		_safe_connect(referee, "add_attack", piece_logic, "_on_add_attack")
	
	# PieceLogic → Referee
	_safe_connect(piece_logic, "match_found", referee, "_on_match_found")
	_safe_connect(piece_logic, "piece_landed", referee, "_on_piece_landed")
	_safe_connect(piece_logic, "board_changed", referee, "_on_board_changed")
	_safe_connect(piece_logic, "attack_piece_landed", referee, "_on_attack_piece_landed")
	_safe_connect(piece_logic, "initial_pieces_updated", referee, "_on_initial_pieces_updated")
	
	# PieceLogic → Main (NUEVA CONEXIÓN)
	if piece_logic.has_signal("setup_phase_finished"):
		_safe_connect(piece_logic, "setup_phase_finished", self, "_on_setup_phase_finished")
	
	# PieceLogic → HUD
	_safe_connect(piece_logic, "board_changed", hud, "_on_board_changed")
	_safe_connect(piece_logic, "initial_pieces_updated", hud, "_on_initial_pieces_updated")
	_safe_connect(piece_logic, "next_piece_updated", hud, "_on_next_piece_updated")

	# Referee → PieceLogic
	_safe_connect(referee, "freeze_all_players", piece_logic, "_on_freeze_all_players")
	_safe_connect(referee, "add_attack", piece_logic, "_on_add_attack")
	
	# Referee → HUD
	_safe_connect(referee, "score_updated", hud, "_on_score_updated")
	_safe_connect(referee, "charges_updated", hud, "_on_charges_updated")
	_safe_connect(referee, "time_updated", hud, "_on_time_updated")
	_safe_connect(referee, "game_over", hud, "_on_game_over")
	_safe_connect(referee, "initial_pieces_updated", hud, "_on_initial_pieces_updated")
	
	# NUEVA CONEXIÓN CRÍTICA: Referee → Main (para game over)
	_safe_connect(referee, "game_over", self, "_on_game_over")
	
	# HUD → Referee
	_safe_connect(hud, "restart_requested", referee, "_on_restart_requested")
	
	print("Todas las señales conectadas")

func _input(event: InputEvent) -> void:
	# NO procesar inputs si el juego terminó
	if is_game_over:
		return
	
	if event.is_action_pressed("ui_accept"):  # Presiona espacio para debug
		if referee and referee.has_method("debug_player_status"):
			referee.debug_player_status()
	
	if event.is_action_pressed("p1_attack_left"):
		print("🎯 MAIN _input: p1_attack_left presionado - game_paused: ", game_paused, " | is_setup_phase: ", is_setup_phase)
	if event.is_action_pressed("p1_attack_right"):
		print("🎯 MAIN _input: p1_attack_right presionado - game_paused: ", game_paused, " | is_setup_phase: ", is_setup_phase)
	if event.is_action_pressed("p2_attack_left"):
		print("🎯 MAIN _input: p2_attack_left presionado - game_paused: ", game_paused, " | is_setup_phase: ", is_setup_phase)
	if event.is_action_pressed("p2_attack_right"):
		print("🎯 MAIN _input: p2_attack_right presionado - game_paused: ", game_paused, " | is_setup_phase: ", is_setup_phase)

func _safe_connect(source: Object, signal_name: String, target: Object, method_name: String) -> void:
	if not source or not target:
		print("ERROR: Source o target nulos para ", signal_name, " -> ", method_name)
		return
	
	if not source.has_signal(signal_name):
		print("ERROR: Señal no existe: ", signal_name, " en ", source.get_class())
		return
	
	if not target.has_method(method_name):
		print("ERROR: Método no existe: ", method_name, " en ", target.get_class())
		return
	
	if source.is_connected(signal_name, Callable(target, method_name)):
		print("Señal ya conectada: ", signal_name, " -> ", method_name)
		return
	
	var result = source.connect(signal_name, Callable(target, method_name))
	if result == OK:
		print("✅ Conectada: ", signal_name, " -> ", method_name)
	else:
		print("❌ Error conectando ", signal_name, " -> ", method_name, ": ", result)

func _physics_process(delta: float) -> void:
	# VERIFICACIÓN CRÍTICA: NO ACTUALIZAR SI EL JUEGO TERMINÓ
	if is_game_over:
		return
	
	#print("🔄 MAIN _physics_process - game_paused: ", game_paused, " | is_setup_phase: ", is_setup_phase)
	
	# NO ACTUALIZAR SI EL JUEGO ESTÁ TERMINADO (pero permitir durante setup)
	if game_paused and not is_setup_phase:
		#print("⏸️  Juego pausado - saltando actualizaciones")
		return
	
	# ACTUALIZAR SIEMPRE
	if referee and referee.has_method("update"):
		referee.update(delta)
		#print("✅ Referee actualizado")
	else:
		print("❌ Referee no se pudo actualizar")
	
	if piece_logic and piece_logic.has_method("update"):
		piece_logic.update(delta)
		#print("✅ PieceLogic actualizado")
	else:
		print("❌ PieceLogic no se pudo actualizar")

# Funciones de acceso
func get_p1():
	if piece_logic and piece_logic.has_method("get_p1"):
		return piece_logic.get_p1()
	return null

func get_p2():
	if piece_logic and piece_logic.has_method("get_p2"):
		return piece_logic.get_p2()
	return null
