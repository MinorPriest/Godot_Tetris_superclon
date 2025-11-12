extends Control

# Señales
signal restart_requested()

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

# Preview con AnimatedSprite2D
@onready var next_preview_p1: AnimatedSprite2D = $NextPreviewP1
@onready var next_preview_p2: AnimatedSprite2D = $NextPreviewP2

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

func _ready():
	# Conectar señales de PieceLogic
	var piece_logic = get_node("../PieceLogic")
	if piece_logic:
		piece_logic.next_piece_index.connect(_on_next_piece_index)
		print("✅ HUD: Señal next_piece_index conectada")
	else:
		print("❌ HUD: No se encontró PieceLogic")

func initialize(main_node, referee_node) -> void:
	main = main_node
	referee = referee_node
	
	# Configurar UI inicial
	if game_over_label:
		game_over_label.visible = false
	if start_new_game:
		start_new_game.visible = false
	
	# Conectar botones
	if start_new_game:
		start_new_game.pressed.connect(_on_restart_pressed)
	
	# Configurar textos iniciales
	update_initial_display()
	
	# Configurar previews inicialmente ocultos
	if next_preview_p1:
		next_preview_p1.visible = false
	if next_preview_p2:
		next_preview_p2.visible = false
	
	print("HUD inicializado correctamente")

func update_initial_display() -> void:
	if time_label: time_label.text = "00:00"
	if p1_score_label: p1_score_label.text = "P1: 0"
	if p1_charges_label: p1_charges_label.text = "Cargas: 0/5"
	if p2_score_label: p2_score_label.text = "P2: 0" 
	if p2_charges_label: p2_charges_label.text = "Cargas: 0/5"
	if p1_initial_label: p1_initial_label.text = "Inicial: 0/10"
	if p2_initial_label: p2_initial_label.text = "Inicial: 0/10"

func _on_restart_pressed() -> void:
	restart_requested.emit()

# === Sistema de preview con AnimatedSprite2D ===

func _on_next_piece_index(player_id: String, piece_index: int):
	print("🎯 HUD: Preview por ÍNDICE - ", player_id, " - Índice: ", piece_index)
	
	var preview_sprite = $NextPreviewP1 if player_id == "P1" else $NextPreviewP2
	if preview_sprite == null:
		print("❌ HUD: No se encontró AnimatedSprite2D para: ", player_id)
		return
	
	# Obtener la pieza REAL de shared_piece_sequence
	var piece_logic = get_node("../PieceLogic")
	if piece_logic == null:
		print("❌ HUD: No se pudo acceder a PieceLogic")
		return
	
	# Verificar que el índice esté en rango
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
	
	# Obtener los colores de la primera rotación
	var first_rotation = piece_data[0]
	var colors: Array[int] = []
	
	for element in first_rotation:
		if element is int:
			colors.append(element)
	
	# Determinar el tipo de pieza por sus colores
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
# === Actualizaciones del HUD ===
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
	elif player == p2 and p2_charges_label:
		p2_charges_label.text = "Cargas: " + str(charges) + "/" + str(max_charges)

func _on_initial_pieces_updated(p1_cleared: int, p2_cleared: int) -> void:
	if p1_initial_label:
		p1_initial_label.text = "Inicial: " + str(p1_cleared) + "/10"
	if p2_initial_label:
		p2_initial_label.text = "Inicial: " + str(p2_cleared) + "/10"

func _on_board_changed(_player) -> void:
	# Esta función puede no ser necesaria si usamos _on_initial_pieces_updated
	pass

# === Sistema de Game Over ===
func _on_game_over(message: String) -> void:
	ScreenShakeManager.game_over_shake()
	print("🎯 Activando screen shake desde HUD...")
	await get_tree().process_frame
	if game_over_label:
		game_over_label.text = message
		game_over_label.visible = true
		$DarkScreen.visible = true
		
	if start_new_game:
		start_new_game.visible = true
	
	# Agregar información adicional de scores
	if referee and referee.has_method("get_p1") and referee.has_method("get_p2"):
		var p1 = referee.get_p1()
		var p2 = referee.get_p2()
		
		if p1 and p2:
			var p1_score = p1.display_score if "display_score" in p1 else 0
			var p2_score = p2.display_score if "display_score" in p2 else 0
			var p1_cleared = 0
			var p2_cleared = 0
			
			# Obtener piezas iniciales limpias
			if main and main.piece_logic and main.piece_logic.has_method("get_initial_pieces_cleared"):
				p1_cleared = main.piece_logic.get_initial_pieces_cleared(p1)
				p2_cleared = main.piece_logic.get_initial_pieces_cleared(p2)
			
			if game_over_label:
				game_over_label.text = message + "\n\nPuntaje P1: " + str(p1_score) + " - Puntaje P2: " + str(p2_score) + "\n\nPiezas iniciales: P1 " + str(p1_cleared) + "/10 - P2 " + str(p2_cleared) + "/10"

# === Funciones de utilidad ===
func show_game_over(message: String) -> void:
	_on_game_over(message)

func hide_game_over() -> void:
	if game_over_label:
		game_over_label.visible = false
	if start_new_game:
		start_new_game.visible = false
