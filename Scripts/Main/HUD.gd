extends Control

# Señales
signal restart_requested()
signal return_to_menu_requested()

# Referencias
var main
var referee

# Nodes del HUD
@onready var time_label: Label = $Time
@onready var p1_score_label: Label = $P1_Score
@onready var p1_charges_label: Label = $P1_SpecialCharges
@onready var p2_score_label: Label = $P2_Score
@onready var p2_charges_label: Label = $P2_SpecialCharges
@onready var p1_initial_label: Label = $P1_Initial
@onready var p2_initial_label: Label = $P2_Initial
@onready var game_over_label: Label = $GameOverLabel
@onready var start_new_game: Button = $StartNewGame
@onready var back_to_selection: Button = $BackToSelection

# NUEVAS REFERENCIAS PARA NOMBRES DE PERFIL
@onready var p1_profile_label: Label = $P1_Profile
@onready var p2_profile_label: Label = $P2_Profile

# Preview con AnimatedSprite2D
@onready var next_preview_p1: AnimatedSprite2D = $NextPreviewP1
@onready var next_preview_p2: AnimatedSprite2D = $NextPreviewP2

# Attack Gauges
@onready var p1_attack_gauge: AnimatedSprite2D = $P1AttackGauge
@onready var p2_attack_gauge: AnimatedSprite2D = $P2AttackGauge

# Mapeo de índice de pieza a nombre de animación
var piece_animations = [
	"red_red",       # índice 0
	"yellow_yellow", # índice 1  
	"blue_blue",     # índice 2
	"red_yellow",    # índice 3
	"red_blue",      # índice 4
	"yellow_blue",   # índice 5
	"red_red",       # índice 6
	"yellow_blue",   # índice 7
	"blue_blue",     # índice 8
	"red_yellow"     # índice 9
]

# Estados de carga para las barras de ataque (6 estados: 0-5 cargas)
var attack_charge_states = ["Charge_0", "Charge_1", "Charge_2", "Charge_3", "Charge_4", "Charge_5"]

# Variable para evitar múltiples clics
var restart_cooldown: bool = false
var button_cooldown: bool = false

func _ready():
	# Conectar señales de PieceLogic
	var piece_logic = get_node("../PieceLogic")
	if piece_logic:
		piece_logic.next_piece_index.connect(_on_next_piece_index)
		print("✅ HUD: Señal next_piece_index conectada")
	else:
		print("❌ HUD: No se encontró PieceLogic")
	
	_setup_attack_gauges()
	
	# Conectar el botón de regreso al menú
	if back_to_selection:
		back_to_selection.pressed.connect(_on_back_to_selection_pressed)
		print("✅ HUD: Botón BackToSelection conectado")
	else:
		print("❌ HUD: No se encontró el botón BackToSelection")
	
	# Actualizar nombres de perfil al inicio
	update_profile_names()

func _setup_attack_gauges():
	if p1_attack_gauge:
		print("✅ HUD: P1AttackGauge encontrado en escena")
		_debug_attack_gauge_animations("P1", p1_attack_gauge)
	else:
		print("❌ HUD: No se encontró P1AttackGauge en la escena")
	
	if p2_attack_gauge:
		print("✅ HUD: P2AttackGauge encontrado en escena")
		_debug_attack_gauge_animations("P2", p2_attack_gauge)
	else:
		print("❌ HUD: No se encontró P2AttackGauge en la escena")
	
	_update_attack_gauge("P1", 0)
	_update_attack_gauge("P2", 0)

# NUEVA FUNCIÓN: Actualizar nombres de perfil
func update_profile_names():
	if ProfileManager:
		if p1_profile_label:
			var p1_profile = ProfileManager.current_profile_p1
			p1_profile_label.text = "P1: " + (p1_profile if p1_profile != "" else "Jugador 1")
			print("✅ HUD: Nombre P1 actualizado: ", p1_profile_label.text)
		
		if p2_profile_label:
			var p2_profile = ProfileManager.current_profile_p2
			p2_profile_label.text = "P2: " + (p2_profile if p2_profile != "" else "Jugador 2")
			print("✅ HUD: Nombre P2 actualizado: ", p2_profile_label.text)
	else:
		print("❌ HUD: No se encontró ProfileManager")
		if p1_profile_label:
			p1_profile_label.text = "P1: Jugador 1"
		if p2_profile_label:
			p2_profile_label.text = "P2: Jugador 2"

func _debug_attack_gauge_animations(player_id: String, attack_gauge: AnimatedSprite2D):
	if attack_gauge == null or attack_gauge.sprite_frames == null:
		print("❌ HUD: AttackGauge ", player_id, " no tiene SpriteFrames")
		return
	
	print("🔍 HUD: Animaciones disponibles para ", player_id, ":")
	var animations = attack_gauge.sprite_frames.get_animation_names()
	for anim in animations:
		print("   - ", anim)
	
	for required_anim in attack_charge_states:
		if attack_gauge.sprite_frames.has_animation(required_anim):
			print("✅ HUD: ", player_id, " tiene animación: ", required_anim)
		else:
			print("❌ HUD: ", player_id, " FALTA animación: ", required_anim)

func initialize(main_node, referee_node) -> void:
	main = main_node
	referee = referee_node
	
	if game_over_label:
		game_over_label.visible = false
	if start_new_game:
		start_new_game.visible = false
		start_new_game.disabled = true
	if back_to_selection:
		back_to_selection.visible = false
		back_to_selection.disabled = true
	
	if start_new_game:
		start_new_game.pressed.connect(_on_restart_pressed)
	
	update_initial_display()
	
	if next_preview_p1:
		next_preview_p1.visible = false
	if next_preview_p2:
		next_preview_p2.visible = false
	
	# Actualizar nombres de perfil al inicializar
	update_profile_names()
	
	print("HUD inicializado correctamente")

func update_initial_display() -> void:
	if time_label: time_label.text = "00:00"
	if p1_score_label: p1_score_label.text = "P1: 0"
	if p1_charges_label: p1_charges_label.text = "Cargas: 0/5"
	if p2_score_label: p2_score_label.text = "P2: 0" 
	if p2_charges_label: p2_charges_label.text = "Cargas: 0/5"
	if p1_initial_label: p1_initial_label.text = "Inicial: 0/10"
	if p2_initial_label: p2_initial_label.text = "Inicial: 0/10"

# === NUEVAS FUNCIONES PARA REINICIO MEJORADO ===

func reset_hud():
	print("🔄 HUD: Reset completo iniciado")
	update_initial_display()
	hide_game_over()
	
	# Resetear previews
	if next_preview_p1:
		next_preview_p1.visible = false
		next_preview_p1.stop()
	if next_preview_p2:
		next_preview_p2.visible = false
		next_preview_p2.stop()
	
	# Resetear attack gauges
	_update_attack_gauge("P1", 0)
	_update_attack_gauge("P2", 0)
	
	# Actualizar nombres de perfil
	update_profile_names()
	
	# Asegurar que los botones estén en estado correcto
	if start_new_game:
		start_new_game.visible = false
		start_new_game.disabled = true
	if back_to_selection:
		back_to_selection.visible = false
		back_to_selection.disabled = true
	
	print("✅ HUD: Reset completado")

func _on_restart_pressed() -> void:
	if button_cooldown:
		print("⏳ HUD: Botones en cooldown, ignorando clic")
		return
	
	button_cooldown = true
	print("🔄 HUD: Solicitando reinicio de partida (una vez)")
	
	# Ocultar inmediatamente la pantalla de Game Over
	hide_game_over()
	
	# Deshabilitar botones inmediatamente
	if start_new_game:
		start_new_game.disabled = true
		start_new_game.visible = false
	if back_to_selection:
		back_to_selection.disabled = true
		back_to_selection.visible = false
	
	# Emitir señal de reinicio (solo una vez)
	restart_requested.emit()
	
	# Reactivar los botones después de un tiempo seguro
	await get_tree().create_timer(3.0).timeout
	button_cooldown = false
	
	print("✅ HUD: Reinicio completado - Botones listos para nuevo uso")

# NUEVA FUNCIÓN: Manejar botón de regresar al menú
func _on_back_to_selection_pressed() -> void:
	if button_cooldown:
		print("⏳ HUD: Botones en cooldown, ignorando clic")
		return
	
	button_cooldown = true
	print("🏠 HUD: Solicitando regreso al menú de selección")
	
	# Deshabilitar botones inmediatamente
	if start_new_game:
		start_new_game.disabled = true
	if back_to_selection:
		back_to_selection.disabled = true
	
	return_to_menu_requested.emit()
	
	# No reactivar botones ya que cambiamos de escena
	print("✅ HUD: Solicitud de regreso al menú enviada")

func _update_attack_gauge(player_id: String, charge_level: int) -> void:
	var attack_gauge = p1_attack_gauge if player_id == "P1" else p2_attack_gauge
	if attack_gauge == null:
		print("❌ HUD: No se encontró AttackGauge para: ", player_id)
		return
	
	charge_level = clamp(charge_level, 0, 5)
	
	var animation_name = attack_charge_states[charge_level]
	
	if attack_gauge.sprite_frames != null and attack_gauge.sprite_frames.has_animation(animation_name):
		attack_gauge.visible = true
		attack_gauge.play(animation_name)
		print("✅ HUD: AttackGauge ", player_id, " - Animación: ", animation_name, " (Carga: ", charge_level, ")")
	else:
		print("⚠️ HUD: Animación no encontrada en AttackGauge ", player_id, ": ", animation_name)
		_try_alternative_animation_names(attack_gauge, player_id, charge_level)

func _try_alternative_animation_names(attack_gauge: AnimatedSprite2D, player_id: String, charge_level: int):
	var alternative_names = [
		"charge_" + str(charge_level),
		"carga_" + str(charge_level),
		"state_" + str(charge_level),
		"nivel_" + str(charge_level),
		str(charge_level)
	]
	
	for alt_name in alternative_names:
		if attack_gauge.sprite_frames != null and attack_gauge.sprite_frames.has_animation(alt_name):
			attack_gauge.visible = true
			attack_gauge.play(alt_name)
			print("✅ HUD: AttackGauge ", player_id, " - Animación alternativa: ", alt_name, " (Carga: ", charge_level, ")")
			if charge_level < attack_charge_states.size():
				attack_charge_states[charge_level] = alt_name
			return
	
	print("❌ HUD: No se encontró ninguna animación válida para carga ", charge_level, " en ", player_id)

func _on_attack_charge_updated(player_id: String, current_charges: int, _max_charges: int) -> void:
	_update_attack_gauge(player_id, current_charges)

func _on_next_piece_index(player_id: String, piece_index: int):
	print("🎯 HUD: Preview por ÍNDICE - ", player_id, " - Índice: ", piece_index)
	
	var preview_sprite = $NextPreviewP1 if player_id == "P1" else $NextPreviewP2
	if preview_sprite == null:
		print("❌ HUD: No se encontró AnimatedSprite2D para: ", player_id)
		return
	
	var piece_logic = get_node("../PieceLogic")
	if piece_logic == null:
		print("❌ HUD: No se pudo acceder a PieceLogic")
		return
	
	if piece_index < piece_logic.shared_piece_sequence.size():
		var next_piece = piece_logic.shared_piece_sequence[piece_index]
		var animation_name = _get_animation_name_from_piece(next_piece)
		
		if preview_sprite.sprite_frames != null and preview_sprite.sprite_frames.has_animation(animation_name):
			preview_sprite.visible = true
			preview_sprite.play(animation_name)
			print("✅ HUD: Mostrando animación: ", animation_name, " para índice ", piece_index)
		else:
			print("⚠️ HUD: Animación no encontrada: ", animation_name)
			preview_sprite.visible = false
	else:
		print("⚠️ HUD: Índice fuera de rango: ", piece_index)
		preview_sprite.visible = false

func _get_animation_name_from_piece(piece_data: Array) -> String:
	if piece_data == null or piece_data.is_empty():
		return "default"
	
	var first_rotation = piece_data[0]
	var colors: Array[int] = []
	
	for element in first_rotation:
		if element is int:
			colors.append(element)
	
	if colors.size() >= 2:
		if colors[0] == colors[1]:
			match colors[0]:
				0: return "red_red"
				1: return "yellow_yellow"
				2: return "blue_blue"
		else:
			if colors.has(0) and colors.has(1):
				return "red_yellow"
			elif colors.has(0) and colors.has(2):
				return "red_blue"
			elif colors.has(1) and colors.has(2):
				return "yellow_blue"
	
	return "default"

func _on_time_updated(time: float) -> void:
	if not time_label:
		return
	var minutes: int = int(time / 60.0)
	var seconds: int = int(time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_score_updated(player, score: int, _charge_score: int) -> void:
	if not referee:
		return
	
	var p1 = referee.get_p1() if referee.has_method("get_p1") else null
	var p2 = referee.get_p2() if referee.has_method("get_p2") else null
	
	if not p1 or not p2:
		return
	
	if player == p1 and p1_score_label:
		p1_score_label.text = "P1: " + str(score)
	elif player == p2 and p2_score_label:
		p2_score_label.text = "P2: " + str(score)

func _on_charges_updated(player, charges: int, max_charges: int) -> void:
	if not referee:
		return
	
	var p1 = referee.get_p1() if referee.has_method("get_p1") else null
	var p2 = referee.get_p2() if referee.has_method("get_p2") else null
	
	if not p1 or not p2:
		return
	
	if player == p1 and p1_charges_label:
		p1_charges_label.text = "Cargas: " + str(charges) + "/" + str(max_charges)
		_on_attack_charge_updated("P1", charges, max_charges)
	elif player == p2 and p2_charges_label:
		p2_charges_label.text = "Cargas: " + str(charges) + "/" + str(max_charges)
		_on_attack_charge_updated("P2", charges, max_charges)

func _on_initial_pieces_updated(p1_cleared: int, p2_cleared: int) -> void:
	if p1_initial_label:
		p1_initial_label.text = "Inicial: " + str(p1_cleared) + "/10"
	if p2_initial_label:
		p2_initial_label.text = "Inicial: " + str(p2_cleared) + "/10"

func _on_board_changed(_player) -> void:
	pass

func _on_game_over(message: String) -> void:
	ScreenShakeManager.game_over_shake()
	await get_tree().process_frame
	
	# Mostrar elementos de Game Over
	if game_over_label:
		game_over_label.text = message
		game_over_label.visible = true
		$DarkScreen.visible = true
		
	if start_new_game:
		start_new_game.visible = true
		start_new_game.disabled = false
		start_new_game.focus_mode = Control.FOCUS_ALL
		start_new_game.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if back_to_selection:
		back_to_selection.visible = true
		back_to_selection.disabled = false
		back_to_selection.focus_mode = Control.FOCUS_ALL
		back_to_selection.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# CRÍTICO: Configurar el foco después de que los nodos estén listos
	call_deferred("_setup_game_over_focus")

# MÉTODO MEJORADO: Configurar el foco después de que todo esté listo
func _setup_game_over_focus():
	# Asegurar que el HUD pueda recibir inputs
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Configurar los botones para inputs
	if start_new_game and start_new_game.visible:
		start_new_game.focus_mode = Control.FOCUS_ALL
		start_new_game.mouse_filter = Control.MOUSE_FILTER_STOP
		start_new_game.grab_focus()
		print("🎯 HUD: Botón StartNewGame enfocado - Listo para inputs de jugadores")
	
	if back_to_selection and back_to_selection.visible:
		back_to_selection.focus_mode = Control.FOCUS_ALL
		back_to_selection.mouse_filter = Control.MOUSE_FILTER_STOP
		print("🎯 HUD: Botón BackToSelection listo para inputs")
	
	print("🎮 HUD: Sistema de inputs de Game Over activado - Usa controles de jugadores")

# NUEVA FUNCIÓN: Manejar inputs de los jugadores para los botones de Game Over
func _input(event: InputEvent) -> void:
	if not game_over_label or not game_over_label.visible:
		return
	
	# Solo procesar si estamos en pantalla de Game Over y los botones están visibles
	if (start_new_game and start_new_game.visible and 
		back_to_selection and back_to_selection.visible):
		
		# Navegación entre botones - ROTATE para subir, DOWN para bajar
		if (event.is_action_pressed("p1_rotate") or event.is_action_pressed("p2_rotate")):
			# ROTATE = SUBIR/NAVEGAR ARRIBA
			if back_to_selection.has_focus():
				start_new_game.grab_focus()
				print("🎯 HUD: Rotate (Arriba) - Navegando a StartNewGame")
			else:
				back_to_selection.grab_focus()
				print("🎯 HUD: Rotate (Arriba) - Navegando a BackToSelection")
		
		elif (event.is_action_pressed("p1_down") or event.is_action_pressed("p2_down")):
			# DOWN = BAJAR/NAVEGAR ABAJO
			if start_new_game.has_focus():
				back_to_selection.grab_focus()
				print("🎯 HUD: Down (Abajo) - Navegando a BackToSelection")
			else:
				start_new_game.grab_focus()
				print("🎯 HUD: Down (Abajo) - Navegando a StartNewGame")
		
		# Aceptar/Seleccionar con botones de aceptación
		if (event.is_action_pressed("p1_accept") or event.is_action_pressed("p2_accept") or
			event.is_action_pressed("p1_enter") or event.is_action_pressed("p2_enter")):
			
			if start_new_game.has_focus():
				print("🎯 HUD: Botón Aceptar/Enter - Iniciando reinicio")
				_on_restart_pressed()
			elif back_to_selection.has_focus():
				print("🎯 HUD: Botón Aceptar/Enter - Regresando al menú")
				_on_back_to_selection_pressed()
		
		# Volver/Cancelar con botones de back
		if (event.is_action_pressed("p1_back") or event.is_action_pressed("p2_back")):
			# BACK = CANCELAR/VOLVER (cambiar entre botones)
			if back_to_selection.has_focus():
				start_new_game.grab_focus()
				print("🎯 HUD: Botón Back - Navegando a StartNewGame")
			else:
				back_to_selection.grab_focus()
				print("🎯 HUD: Botón Back - Navegando a BackToSelection")

func show_game_over(message: String) -> void:
	_on_game_over(message)

func hide_game_over() -> void:
	if game_over_label:
		game_over_label.visible = false
	if start_new_game:
		start_new_game.visible = false
		start_new_game.disabled = true
	if back_to_selection:
		back_to_selection.visible = false
		back_to_selection.disabled = true
	if $DarkScreen:
		$DarkScreen.visible = false

# NUEVA FUNCIÓN: Mostrar mensaje final con nombres de perfil
func show_final_message(message: String) -> void:
	show_game_over(message)
