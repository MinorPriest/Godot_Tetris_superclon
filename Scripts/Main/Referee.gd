extends Node

# Señales
signal score_updated(player, score, charge_score)
signal charges_updated(player, charges, max_charges)
signal time_updated(time)
signal game_over(message)
signal freeze_all_players(freeze)
signal add_attack(from_player, to_player, side)
signal initial_pieces_updated(p1_cleared, p2_cleared)

# Referencias - NO usar tipos específicos
var main
var piece_logic
var hud
var dj

# Variables del referee
var game_time: float = 0.0
var is_timer_running: bool = false
var game_paused: bool = false

# 🆕 VARIABLES PARA CONTROLAR PIEZAS INICIALES
var initial_pieces_placed: bool = false
var p1_initial_count: int = 0
var p2_initial_count: int = 0
const INITIAL_PIECES_REQUIRED: int = 10

# Constantes
const POINTS_PER_CHARGE: int = 150
const MAX_CHARGES: int = 5

# Variable para evitar múltiples reinicios
var is_restarting: bool = false
var restart_requested: bool = false

func initialize(main_node, piece_logic_node, hud_node, dj_node) -> void:
	main = main_node
	piece_logic = piece_logic_node
	hud = hud_node
	dj = dj_node
	print("Referee inicializado")

func setup_game() -> void:
	print("🎮 Referee: INICIANDO CONFIGURACIÓN DEL JUEGO...")
	
	# 🆕 RESETEAR CONTADORES DE PIEZAS INICIALES
	p1_initial_count = 0
	p2_initial_count = 0
	initial_pieces_placed = false
	is_timer_running = false  # ← ASEGURAR QUE ESTÉ EN FALSE
	game_time = 0.0
	game_paused = false
	is_restarting = false
	restart_requested = false
	
	if piece_logic and piece_logic.has_method("setup_initial_pieces"):
		piece_logic.setup_initial_pieces()
		print("✅ Piezas iniciales configuradas")
	else:
		print("❌ No se pudo configurar piezas iniciales")
	
	if piece_logic and piece_logic.has_method("setup_shared_sequence"):
		piece_logic.setup_shared_sequence()
		print("✅ Secuencia compartida configurada")
	
	if piece_logic and piece_logic.has_method("select_random_preset"):
		piece_logic.select_random_preset()
		print("✅ Preset seleccionado")
	
	if piece_logic and piece_logic.has_method("setup_preset_positions"):
		piece_logic.setup_preset_positions()
		print("✅ Posiciones del preset configuradas")
	
	freeze_game(true)
	print("✅ Jugadores congelados")
	
	# Asegurarnos de que main.is_setup_phase sea true
	if main and main.has_method("set_setup_phase"):
		main.set_setup_phase(true)
	
	print("🎮 Referee: CONFIGURACIÓN COMPLETADA - ESPERANDO PIEZAS INICIALES")
	
	# Configurar estado inicial del HUD
	update_all_hud_displays()
	
	# CORRECCIÓN: Iniciar música aquí también
	if dj and dj.has_method("setup_background_music"):
		print("🎵 Referee: Iniciando música de fondo en setup...")
		dj.setup_background_music()
	
	# DESCONGELAR AUTOMÁTICAMENTE después de 3 segundos (como fallback)
	await get_tree().create_timer(3.0).timeout
	if game_paused and not is_restarting and not restart_requested:  # Solo si todavía está congelado y no estamos reiniciando
		print("🕒 Referee: Descongelamiento automático después de setup")
		freeze_game(false)

func update(delta: float) -> void:
	#print("🔄 Referee.update() llamado - game_paused: ", game_paused, " | is_timer_running: ", is_timer_running)
	
	if is_timer_running and not game_paused and not is_restarting and not restart_requested:
		game_time += delta
		time_updated.emit(game_time)

	# Verificar inputs de ataque (SOLO UNA VEZ)
	if not is_restarting and not restart_requested:
		check_attack_inputs()

func check_attack_inputs() -> void:
	# NO PROCESAR INPUTS SI EL JUEGO ESTÁ TERMINADO - VERIFICACIÓN MÁS ESTRICTA
	if game_paused or not is_timer_running or (main and main.game_paused) or is_restarting or restart_requested:
		#print("⏸️  Juego terminado - saltando inputs de ataque")
		return
	
	#print("🎯 Referee.check_attack_inputs() - Frame: ", Engine.get_frames_drawn())
	
	if not piece_logic:
		print("❌ piece_logic es null")
		return
	
	var p1 = piece_logic.get_p1()
	var p2 = piece_logic.get_p2()
	
	if not p1 or not p2:
		print("❌ p1 o p2 son null")
		return
	
	#print("🎯 Cargas disponibles - P1: ", p1.charges, " | P2: ", p2.charges)
	
	# VERIFICACIÓN DIRECTA SIN CONDICIONES (solo para debug)
	if Input.is_action_just_pressed("p1_attack_left"):
		print("🎯🎯🎯 REFEREE: P1 ATAQUE IZQUIERDA DETECTADO")
	if Input.is_action_just_pressed("p1_attack_right"):
		print("🎯🎯🎯 REFEREE: P1 ATAQUE DERECHA DETECTADO")
	if Input.is_action_just_pressed("p2_attack_left"):
		print("🎯🎯🎯 REFEREE: P2 ATAQUE IZQUIERDA DETECTADO")
	if Input.is_action_just_pressed("p2_attack_right"):
		print("🎯🎯🎯 REFEREE: P2 ATAQUE DERECHA DETECTADO")
	
	# Ataques P1 - CON RETURN para evitar múltiples procesamientos
	if Input.is_action_just_pressed("p1_attack_left") and p1.charges > 0:
		print("🚀🚀🚀 REFEREE: EMITIENDO add_attack P1→P2 (izquierda)")
		add_attack.emit(p1, p2, "left")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("attack_launch")
		return
	
	elif Input.is_action_just_pressed("p1_attack_right") and p1.charges > 0:
		print("🚀🚀🚀 REFEREE: EMITIENDO add_attack P1→P2 (derecha)")
		add_attack.emit(p1, p2, "right")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("attack_launch")
		return
	
	# Ataques P2 - CON RETURN para evitar múltiples procesamientos
	elif Input.is_action_just_pressed("p2_attack_left") and p2.charges > 0:
		print("🚀🚀🚀 REFEREE: EMITIENDO add_attack P2→P1 (izquierda)")
		add_attack.emit(p2, p1, "left")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("attack_launch")
		return
	
	elif Input.is_action_just_pressed("p2_attack_right") and p2.charges > 0:
		print("🚀🚀🚀 REFEREE: EMITIENDO add_attack P2→P1 (derecha)")
		add_attack.emit(p2, p1, "right")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("attack_launch")
		return

# === Manejo de matches ===
func _on_match_found(player, _matched_positions: Array, points: int) -> void:
	if is_restarting or restart_requested:
		return
	#print("🎉🎉🎉 REFEREE: _on_match_found RECIBIDO!")
	#print("Jugador: ", "P1" if player == get_p1() else "P2")
	#print("Puntos recibidos: ", points)
	#print("Cargas actuales antes: ", player.charges)
	#print("Puntos de carga actuales antes: ", player.charge_points)
	#print("Score actual antes: ", player.display_score)
	
	add_points_to_charges(player, points)
	
	#print("Cargas después: ", player.charges)
	#print("Puntos de carga después: ", player.charge_points)
	#print("Score después: ", player.display_score)
	
	check_initial_pieces_win_condition()
	if dj and dj.has_method("play_sound"):
		dj.play_sound("match")

func add_points_to_charges(player, points: int) -> void:
	player.display_score += points
	
	if player.charges < MAX_CHARGES:
		player.charge_score += points
		player.charge_points += points
		
		while player.charge_points >= POINTS_PER_CHARGE and player.charges < MAX_CHARGES:
			player.charge_points -= POINTS_PER_CHARGE
			player.charges += 1
			if dj and dj.has_method("play_sound"):
				dj.play_sound("charge_gained")
	else:
		print("Cargas al máximo (", MAX_CHARGES, "), puntos para cargas perdidos: ", points, " pero puntos totales aumentan")
	
	# Emitir señales de actualización
	score_updated.emit(player, player.display_score, player.charge_score)
	charges_updated.emit(player, player.charges, MAX_CHARGES)

# === NUEVA FUNCIÓN CRÍTICA: Manejar finalización de piezas iniciales ===
func handle_initial_pieces_completed() -> void:
	if not piece_logic or not piece_logic.has_method("get_initial_pieces_cleared"):
		return
	
	var p1 = piece_logic.get_p1()
	var p2 = piece_logic.get_p2()
	
	if not p1 or not p2:
		return
	
	var p1_cleared = piece_logic.get_initial_pieces_cleared(p1)
	var p2_cleared = piece_logic.get_initial_pieces_cleared(p2)
	
	print("🔍 VERIFICACIÓN FINAL - P1: ", p1_cleared, "/10, P2: ", p2_cleared, "/10")
	
	# Obtener nombres de perfil
	var p1_name = "Jugador 1"
	var p2_name = "Jugador 2"
	
	if ProfileManager:
		if ProfileManager.current_profile_p1 != "":
			p1_name = ProfileManager.current_profile_p1
		if ProfileManager.current_profile_p2 != "":
			p2_name = ProfileManager.current_profile_p2
	
	# VERIFICACIÓN DIRECTA Y EXPLÍCITA
	if p1_cleared == 10 and p2_cleared == 10:
		print("🎉 EMPATE DETECTADO - Ambos en 10/10!")
		game_over.emit("EMPATE!\nAmbos jugadores completaron las piezas iniciales")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("game_over_draw")
		freeze_game_completely()
		
	elif p1_cleared == 10:
		print("🎉 P1 VICTORIA DETECTADA - 10/10 alcanzado!")
		game_over.emit(p1_name + " GANA!\nCompletó las piezas iniciales primero")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("game_over_win")
		freeze_game_completely()
		
	elif p2_cleared == 10:
		print("🎉 P2 VICTORIA DETECTADA - 10/10 alcanzado!")
		game_over.emit(p2_name + " GANA!\nCompletó las piezas iniciales primero")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("game_over_win")
		freeze_game_completely()

# === Condiciones de victoria ===
func check_initial_pieces_win_condition() -> void:
	if not piece_logic or not piece_logic.has_method("get_initial_pieces_cleared"):
		return
	
	var p1 = piece_logic.get_p1()
	var p2 = piece_logic.get_p2()
	
	if not p1 or not p2:
		return
	
	var p1_cleared = piece_logic.get_initial_pieces_cleared(p1)
	var p2_cleared = piece_logic.get_initial_pieces_cleared(p2)
	
	print("DEBUG: Verificando victoria - P1: ", p1_cleared, "/10, P2: ", p2_cleared, "/10")
	
	# Emitir actualización de piezas iniciales
	initial_pieces_updated.emit(p1_cleared, p2_cleared)
	
	# 🆕 LLAMADA A LA NUEVA FUNCIÓN DE VERIFICACIÓN
	handle_initial_pieces_completed()

func _on_initial_pieces_updated(_p1_cleared: int, _p2_cleared: int) -> void:
	check_initial_pieces_win_condition()

# === Manejo de piezas colocadas ===
func _on_piece_landed(player) -> void:
	if is_restarting or restart_requested:
		return
		
	# 🆕 SOLO CONTAR si estamos en fase de setup y no hemos terminado
	if not initial_pieces_placed and main and main.is_setup_phase:
		if player == get_p1():
			p1_initial_count += 1
			print("📊 P1 pieza inicial colocada: ", p1_initial_count, "/", INITIAL_PIECES_REQUIRED)
		elif player == get_p2():
			p2_initial_count += 1
			print("📊 P2 pieza inicial colocada: ", p2_initial_count, "/", INITIAL_PIECES_REQUIRED)
		
		# Verificar si ambos jugadores han colocado las 10 piezas iniciales
		check_initial_pieces_completion()
	
	# Reproducir sonido normal (siempre)
	if dj and dj.has_method("play_sound"):
		dj.play_sound("piece_land")
	
	# 🆕 SOLO verificar game over si NO estamos en setup
	if not main.is_setup_phase:
		check_board_full_condition()

func _on_attack_piece_landed(_player) -> void:
	if is_restarting or restart_requested:
		return
		
	if dj and dj.has_method("play_sound"):
		dj.play_sound("attack_land")

# 🆕 NUEVO MÉTODO: Verificar si se completaron las piezas iniciales
func check_initial_pieces_completion() -> void:
	if p1_initial_count >= INITIAL_PIECES_REQUIRED and p2_initial_count >= INITIAL_PIECES_REQUIRED:
		print("🎉🎉🎉 ¡TODAS LAS PIEZAS INICIALES COLOCADAS! 🎉🎉🎉")
		print("P1: ", p1_initial_count, " | P2: ", p2_initial_count)
		
		initial_pieces_placed = true
		start_game_timer()  # ← INICIAR TIMER SOLO AQUÍ
		
		# Descongelar el juego
		freeze_game(false)
		
		# Actualizar fase de setup en main
		if main and main.has_method("set_setup_phase"):
			main.set_setup_phase(false)
		
		# 🆕 LLAMADA CRÍTICA: Verificar victoria inmediatamente después de completar
		await get_tree().process_frame  # Esperar un frame para que se actualicen los contadores
		handle_initial_pieces_completed()

# 🆕 NUEVO MÉTODO: Iniciar el contador del juego
func start_game_timer() -> void:
	is_timer_running = true
	game_time = 0.0  # Reiniciar el tiempo
	print("⏰ CONTADOR INICIADO - ¡Que comience el juego!")
	
	# CORRECCIÓN: Asegurar que la música se reproduzca
	if dj and dj.has_method("setup_background_music"):
		print("🎵 Iniciando música para nuevo juego...")
		dj.setup_background_music()
	elif dj and dj.has_method("play_sound"):
		dj.play_sound("game_start")

func check_board_full_condition() -> void:
	if not piece_logic or not piece_logic.has_method("get_p1") or not piece_logic.has_method("get_p2"):
		return
	
	var p1 = piece_logic.get_p1()
	var p2 = piece_logic.get_p2()
	
	if not p1 or not p2:
		return
	
	# Obtener nombres de perfil
	var profile_manager = get_node("/root/ProfileManager")
	var p1_name = "Jugador 1"
	var p2_name = "Jugador 2"
	
	if profile_manager:
		if profile_manager.current_profile_p1 != "":
			p1_name = profile_manager.current_profile_p1
		if profile_manager.current_profile_p2 != "":
			p2_name = profile_manager.current_profile_p2
	
	var p1_game_over = false
	var p2_game_over = false
	
	if "is_active" in p1:
		p1_game_over = not p1.is_active or is_board_full(p1)
	else:
		p1_game_over = is_board_full(p1)
	
	if "is_active" in p2:
		p2_game_over = not p2.is_active or is_board_full(p2)
	else:
		p2_game_over = is_board_full(p2)
	
	if p1_game_over and p2_game_over:
		# CORREGIDO: Mensaje más claro para detección
		game_over.emit("EMPATE - " + p1_name + " vs " + p2_name)
		if dj and dj.has_method("play_sound"):
			dj.play_sound("game_over_draw")
		freeze_game_completely()
	elif p1_game_over:
		# CORREGIDO: Mensaje más claro para detección
		game_over.emit(p2_name + " GANA - " + p1_name + " eliminado")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("game_over_win")
		freeze_game_completely()
	elif p2_game_over:
		# CORREGIDO: Mensaje más claro para detección
		game_over.emit(p1_name + " GANA - " + p2_name + " eliminado")
		if dj and dj.has_method("play_sound"):
			dj.play_sound("game_over_win")
		freeze_game_completely()

func is_board_full(player) -> bool:
	var spawn_positions = []
	if player == piece_logic.get_p1():
		spawn_positions = [
			Vector2i(4, 1), 
			Vector2i(4, 1) + Vector2i(0,1), 
			Vector2i(4, 1) + Vector2i(1,0)
		]
	else:
		spawn_positions = [
			Vector2i(29, 1), 
			Vector2i(29, 1) + Vector2i(0,1), 
			Vector2i(29, 1) + Vector2i(1,0)
		]
	
	for pos in spawn_positions:
		if player.board_layer.get_cell_source_id(pos) != -1:
			return true
	return false

# === Manejo de cambios en el tablero ===
func _on_board_changed(_player) -> void:
	if is_restarting or restart_requested:
		return
		
	# Actualizar contadores de piezas iniciales cuando cambia el tablero
	if not piece_logic or not piece_logic.has_method("get_initial_pieces_cleared"):
		return
	
	var p1 = piece_logic.get_p1()
	var p2 = piece_logic.get_p2()
	
	if not p1 or not p2:
		return
	
	var p1_cleared = piece_logic.get_initial_pieces_cleared(p1)
	var p2_cleared = piece_logic.get_initial_pieces_cleared(p2)
	initial_pieces_updated.emit(p1_cleared, p2_cleared)
	
	# 🆕 VERIFICACIÓN ADICIONAL: Si estamos en juego normal, verificar victoria
	if not main.is_setup_phase:
		handle_initial_pieces_completed()

# === Sistema de reinicio ===
func _on_restart_requested() -> void:
	if is_restarting:
		print("⏳ Referee: Ya se está reiniciando, ignorando solicitud adicional")
		return
	
	print("🔄 REFEREE: Solicitud de reinicio recibida")
	restart_game()

# NUEVA FUNCIÓN: Limpieza del referee
func cleanup():
	print("🧹 REFEREE: Limpieza iniciada")
	game_time = 0.0
	is_timer_running = false
	game_paused = false
	initial_pieces_placed = false
	p1_initial_count = 0
	p2_initial_count = 0
	is_restarting = false
	restart_requested = false

func restart_game() -> void:
	if is_restarting:
		print("⏳ REFEREE: Ya se está reiniciando, ignorando solicitud")
		return
	
	is_restarting = true
	print("🔄 REFEREE: Iniciando reinicio controlado...")
	
	# Resetear estado COMPLETAMENTE
	cleanup()
	
	# Ocultar pantalla de Game Over en HUD y resetear
	if hud:
		if hud.has_method("hide_game_over"):
			hud.hide_game_over()
		if hud.has_method("reset_hud"):
			hud.reset_hud()
	
	# Limpiar tableros completamente
	if piece_logic and piece_logic.has_method("cleanup_boards"):
		piece_logic.cleanup_boards()
	
	# Pequeño delay para estabilizar
	await get_tree().create_timer(0.2).timeout
	
	# Reiniciar lógica de piezas
	if piece_logic and piece_logic.has_method("restart"):
		piece_logic.restart()
	
	# Esperar otro frame
	await get_tree().process_frame
	
	# Configurar el juego de nuevo
	setup_game()
	
	# Actualizar HUD
	update_all_hud_displays()
	
	# CORRECCIÓN CRÍTICA: Reproducir música de fondo después del reinicio
	if dj and dj.has_method("setup_background_music"):
		print("🎵 REFEREE: Reiniciando música de fondo...")
		dj.setup_background_music()
	elif dj and dj.has_method("play_sound"):
		print("🎵 REFEREE: Reproduciendo sonido de inicio...")
		dj.play_sound("game_start")
	
	await get_tree().create_timer(1.0).timeout
	is_restarting = false
	print("✅ REFEREE: Reinicio controlado completado")
	
func update_all_hud_displays() -> void:
	if not piece_logic or not piece_logic.has_method("get_p1") or not piece_logic.has_method("get_p2"):
		return
	
	var p1 = piece_logic.get_p1()
	var p2 = piece_logic.get_p2()
	
	if not p1 or not p2:
		return
	
	# Actualizar tiempo
	time_updated.emit(game_time)
	
	# Actualizar scores y cargas
	score_updated.emit(p1, p1.display_score, p1.charge_score)
	score_updated.emit(p2, p2.display_score, p2.charge_score)
	charges_updated.emit(p1, p1.charges, MAX_CHARGES)
	charges_updated.emit(p2, p2.charges, MAX_CHARGES)
	
	# Actualizar piezas iniciales
	var p1_cleared = piece_logic.get_initial_pieces_cleared(p1)
	var p2_cleared = piece_logic.get_initial_pieces_cleared(p2)
	initial_pieces_updated.emit(p1_cleared, p2_cleared)

# === Funciones de acceso para compatibilidad ===
func get_p1():
	if piece_logic and piece_logic.has_method("get_p1"):
		return piece_logic.get_p1()
	return null

func get_p2():
	if piece_logic and piece_logic.has_method("get_p2"):
		return piece_logic.get_p2()
	return null

func freeze_game(freeze: bool) -> void:
	game_paused = freeze
	freeze_all_players.emit(freeze)
	
	# Actualizar main.game_paused de manera segura
	if main and main.has_method("set_game_paused"):
		main.set_game_paused(freeze)
	elif main:
		main.game_paused = freeze
	
	if dj and dj.has_method("play_sound"):
		if freeze:
			dj.play_sound("game_pause")
		else:
			dj.play_sound("game_resume")

func freeze_game_completely() -> void:
	print("❄️❄️❄️ CONGELANDO JUEGO COMPLETAMENTE - AMBOS JUGADORES")
	is_timer_running = false
	game_paused = true
	
	# Congelar ambos jugadores mediante señal
	freeze_all_players.emit(true)
	
	# Actualizar estado en main
	if main and main.has_method("set_game_paused"):
		main.set_game_paused(true)
	elif main:
		main.game_paused = true
	
	# Detener lógica de piezas si es posible
	if piece_logic and piece_logic.has_method("_on_freeze_all_players"):
		piece_logic._on_freeze_all_players(true)
	
	print("✅ JUEGO COMPLETAMENTE CONGELADO - NINGÚN JUGADOR PUEDE MOVERSE")
