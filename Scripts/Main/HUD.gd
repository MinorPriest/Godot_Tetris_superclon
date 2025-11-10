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

func _ready() -> void:
	# Inicializar puede llamarse desde aquí o desde Main
	print("HUD listo")

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

# === Actualizaciones del HUD ===
func _on_time_updated(time: float) -> void:
	if not time_label:
		return
	var minutes: int = int(time / 60.0)
	var seconds: int = int(time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func _on_score_updated(player, score: int, _charge_score: int) -> void:  # _charge_score no usado
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

func _on_board_changed(_player) -> void:  # _player no usado
	# Esta función puede no ser necesaria si usamos _on_initial_pieces_updated
	pass

# En HUD.gd, función _on_game_over(), reemplazar:
# En HUD.gd, reemplaza la función _on_game_over():
func _on_game_over(message: String) -> void:
	if game_over_label:
		game_over_label.text = message
		game_over_label.visible = true
	if start_new_game:
		start_new_game.visible = true
	
	# Agregar información adicional de scores
	if referee and referee.has_method("get_p1") and referee.has_method("get_p2"):
		var p1 = referee.get_p1()
		var p2 = referee.get_p2()
		
		# CORRECCIÓN: Verificar si los jugadores tienen las propiedades necesarias
		if p1 and p2:
			var p1_score = p1.get("display_score") if p1.has_method("get") or ("display_score" in p1) else 0
			var p2_score = p2.get("display_score") if p2.has_method("get") or ("display_score" in p2) else 0
			var p1_cleared = 0
			var p2_cleared = 0
			
			# CORRECCIÓN: Verificar si piece_logic existe y tiene el método
			if main and main.piece_logic and main.piece_logic.has_method("get_initial_pieces_cleared"):
				p1_cleared = main.piece_logic.get_initial_pieces_cleared(p1)
				p2_cleared = main.piece_logic.get_initial_pieces_cleared(p2)
			
			if game_over_label:
				game_over_label.text = message + "\nP1: " + str(p1_score) + " - P2: " + str(p2_score) + "\nPiezas iniciales: P1 " + str(p1_cleared) + "/10 - P2 " + str(p2_cleared) + "/10"
# === Funciones de utilidad ===
func show_game_over(message: String) -> void:
	_on_game_over(message)

func hide_game_over() -> void:
	if game_over_label:
		game_over_label.visible = false
	if start_new_game:
		start_new_game.visible = false
