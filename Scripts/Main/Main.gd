extends Node2D

# Módulos
var piece_logic
var referee
var hud
var dj
var ProfileManager

# Nodes
@onready var p1_board: TileMapLayer = $P1Board
@onready var p1_active: TileMapLayer = $P1Active
@onready var p2_board: TileMapLayer = $P2Board
@onready var p2_active: TileMapLayer = $P2Active

# Variables de estado del juego
var game_paused: bool = false
var is_setup_phase: bool = true
var is_timer_running: bool = true
var is_game_over: bool = false

# Variables de control de reinicio
var is_restarting: bool = false
var restart_cooldown: float = 0.0

func _ready() -> void:
	print("=== INICIANDO JUEGO ===")
	
	# Obtener ProfileManager del autoload
	ProfileManager = get_node("/root/ProfileManager")
	if ProfileManager:
		print("✅ ProfileManager encontrado")
		ProfileManager.auto_load_last_profiles()
		print("🔄 Últimos perfiles cargados automáticamente para la partida")
	else:
		print("❌ ProfileManager NO encontrado")
	
	initialize_modules()
	print("DEBUG: _ready() completado")

func set_setup_phase(setup: bool):
	print("🔄 MAIN: Cambiando is_setup_phase de ", is_setup_phase, " a ", setup)
	is_setup_phase = setup

func set_game_paused(paused: bool) -> void:
	print("🔄 MAIN: Cambiando game_paused de ", game_paused, " a ", paused)
	game_paused = paused

func set_game_over(over: bool) -> void:
	print("🔄 MAIN: Cambiando is_game_over de ", is_game_over, " a ", over)
	is_game_over = over
	game_paused = over
	
	if over:
		set_physics_process(false)
		print("🚨 JUEGO TERMINADO - Todas las actualizaciones detenidas")
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
		
		var required_methods = ["setup_initial_pieces", "setup_shared_sequence", "select_random_preset", "setup_preset_positions", "update"]
		for method in required_methods:
			if piece_logic.has_method(method):
				print("✅ PieceLogic tiene método: ", method)
			else:
				print("❌ PieceLogic NO tiene método: ", method)
		
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

func _on_game_over(message: String) -> void:
	print("🎯 MAIN: GAME OVER - ", message)
	
	# AÑADIR: Registrar resultado en ProfileManager
	if ProfileManager:
		var player1 = get_p1()
		var player2 = get_p2()
		
		var winner_player = 0
		var loser_player = 0
		var winner_score = 0
		
		var p1_name = ProfileManager.current_profile_p1
		var p2_name = ProfileManager.current_profile_p2
		
		print("🔍 Analizando mensaje de victoria:")
		print("   Mensaje: ", message)
		print("   P1 actual: ", p1_name)
		print("   P2 actual: ", p2_name)
		
		# ✅ CORRECCIÓN CRÍTICA: Lógica de detección de ganador MEJORADA
		# Buscar explícitamente el patrón "NOMBRE GANA - OTRO eliminado"
		if message.begins_with(p1_name + " GANA"):
			# P1 gana
			winner_player = 1
			loser_player = 2
			winner_score = player1.display_score if player1 and "display_score" in player1 else 0
			print("🏆 Ganador detectado: P1 (", p1_name, ") vs Perdedor: P2 (", p2_name, ") - Score: ", winner_score)
		elif message.begins_with(p2_name + " GANA"):
			# P2 gana
			winner_player = 2
			loser_player = 1
			winner_score = player2.display_score if player2 and "display_score" in player2 else 0
			print("🏆 Ganador detectado: P2 (", p2_name, ") vs Perdedor: P1 (", p1_name, ") - Score: ", winner_score)
		elif "EMPATE" in message:
			print("🤝 Empate - No se registra resultado en perfiles")
			winner_player = 0
			loser_player = 0
		else:
			# Fallback para mensajes genéricos
			if "JUGADOR 1 GANA" in message or "P1 GANA" in message:
				winner_player = 1
				loser_player = 2
				winner_score = player1.display_score if player1 and "display_score" in player1 else 0
				print("🏆 Ganador (fallback): P1 - Score: ", winner_score)
			elif "JUGADOR 2 GANA" in message or "P2 GANA" in message:
				winner_player = 2
				loser_player = 1
				winner_score = player2.display_score if player2 and "display_score" in player2 else 0
				print("🏆 Ganador (fallback): P2 - Score: ", winner_score)
			else:
				print("❌ No se pudo determinar ganador del mensaje: ", message)
		
		if winner_player != 0 and loser_player != 0:
			ProfileManager.register_game_result(winner_player, loser_player, winner_score)
			print("✅ Resultado registrado en ProfileManager")
		else:
			print("❌ No se pudo determinar ganador del mensaje: ", message)
	
	# Resto del código de game over...
	set_game_over(true)
	
	if piece_logic and piece_logic.has_method("set_game_over"):
		piece_logic.set_game_over(true)
	
	if hud and hud.has_method("show_final_message"):
		hud.show_final_message(message)
	
	game_paused = true

# NUEVA FUNCIÓN: Manejar reinicio solicitado por HUD
func _on_restart_requested():
	if is_restarting:
		print("⏳ MAIN: Ya se está reiniciando, ignorando solicitud adicional")
		return
	
	is_restarting = true
	print("🔄 MAIN: Iniciando reinicio controlado...")
	
	# Resetear estados críticos
	game_paused = false
	is_setup_phase = true
	is_timer_running = true
	is_game_over = false
	
	# Reactivar el proceso de física
	set_physics_process(true)
	
	# CORRECCIÓN: Detener música actual antes del reinicio
	if dj and dj.has_method("stop_background_music"):
		dj.stop_background_music()
	
	# Pequeño delay para estabilizar
	await get_tree().create_timer(0.1).timeout
	
	# Solo un reinicio desde referee
	if referee and referee.has_method("restart_game"):
		referee.restart_game()
	else:
		print("❌ MAIN: Fallback - Recargando escena")
		get_tree().reload_current_scene()
	
	# Permitir nuevo reinicio después de un tiempo
	await get_tree().create_timer(2.0).timeout
	is_restarting = false
	print("✅ MAIN: Reinicio completado - Listo para nuevos reinicios")

# NUEVA FUNCIÓN: Reiniciar juego completamente
func restart_game_completely():
	if is_restarting:
		return
		
	print("🔄 MAIN: Reinicio completo iniciado")
	is_restarting = true
	
	# Resetear todos los estados
	game_paused = false
	is_setup_phase = true
	is_timer_running = true
	is_game_over = false
	
	# Limpiar completamente
	cleanup_all()
	
	# Reiniciar sistemas principales
	if piece_logic and piece_logic.has_method("cleanup"):
		piece_logic.cleanup()
	
	await get_tree().create_timer(0.1).timeout
	
	# Configurar juego nuevo
	if referee and referee.has_method("setup_game"):
		referee.setup_game()
	
	await get_tree().create_timer(1.0).timeout
	is_restarting = false
	print("✅ MAIN: Reinicio completo completado")

# NUEVA FUNCIÓN: Limpieza completa
func cleanup_all():
	print("🧹 MAIN: Limpiando todos los sistemas...")
	
	# Limpiar tableros si es posible
	if piece_logic and piece_logic.has_method("cleanup_boards"):
		piece_logic.cleanup_boards()
	
	# Resetear HUD
	if hud and hud.has_method("hide_game_over"):
		hud.hide_game_over()
	
	# Resetear referee
	if referee and referee.has_method("cleanup"):
		referee.cleanup()

func _on_return_to_menu_requested():
	print("🏠 MAIN: Regresando al menú de selección")
	game_paused = false
	is_game_over = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/SelectionScene.tscn")

func _on_setup_phase_finished():
	print("🎉🎉🎉 MAIN: Fase de setup TERMINADA - Activando ataques 🎉🎉🎉")
	is_setup_phase = false
	game_paused = false
	if dj and dj.has_method("play_sound"):
		dj.play_sound("game_start")
	if referee and referee.has_method("_on_setup_phase_finished"):
		referee._on_setup_phase_finished()

func connect_modules_signals() -> void:
	print("Conectando señales...")
	
	if not piece_logic or not referee or not hud:
		print("ERROR: Módulos faltantes para conectar señales")
		return
	
	# VERIFICAR CONEXIÓN match_found
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
	
	# PieceLogic → Main
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
	
	# Referee → Main
	_safe_connect(referee, "game_over", self, "_on_game_over")
	
	# HUD → Referee Y HUD → Main (DOBLE CONEXIÓN PARA REINICIO)
	_safe_connect(hud, "restart_requested", referee, "_on_restart_requested")
	_safe_connect(hud, "restart_requested", self, "_on_restart_requested")
	
	# HUD → Main
	_safe_connect(hud, "return_to_menu_requested", self, "_on_return_to_menu_requested")
	
	print("Todas las señales conectadas")

func _input(event: InputEvent) -> void:
	if is_game_over:
		return
	
	if event.is_action_pressed("ui_accept"):
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
	if is_game_over:
		return
	
	if game_paused and not is_setup_phase:
		return
	
	if referee and referee.has_method("update"):
		referee.update(delta)
	
	if piece_logic and piece_logic.has_method("update"):
		piece_logic.update(delta)

func get_p1():
	if piece_logic and piece_logic.has_method("get_p1"):
		return piece_logic.get_p1()
	return null

func get_p2():
	if piece_logic and piece_logic.has_method("get_p2"):
		return piece_logic.get_p2()
	return null
