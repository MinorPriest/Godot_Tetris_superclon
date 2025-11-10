extends Node2D

# === Tetrominos con colores ===
# Cada pieza ahora tiene [bloque1, bloque2, color1, color2]
var red_red_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 0, 0],    # Rojo-Rojo
	[Vector2i(0,1), Vector2i(0,2), 0, 0],
	[Vector2i(0,1), Vector2i(-1,1), 0, 0],
	[Vector2i(0,1), Vector2i(0,0), 0, 0]
]

var yellow_yellow_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 1, 1],    # Amarillo-Amarillo
	[Vector2i(0,1), Vector2i(0,2), 1, 1],
	[Vector2i(0,1), Vector2i(-1,1), 1, 1],
	[Vector2i(0,1), Vector2i(0,0), 1, 1]
]

var blue_blue_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 2, 2],    # Azul-Azul
	[Vector2i(0,1), Vector2i(0,2), 2, 2],
	[Vector2i(0,1), Vector2i(-1,1), 2, 2],
	[Vector2i(0,1), Vector2i(0,0), 2, 2]
]

# Piezas mixtas
var red_yellow_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 0, 1],    # Rojo-Amarillo
	[Vector2i(0,1), Vector2i(0,2), 0, 1],
	[Vector2i(0,1), Vector2i(-1,1), 0, 1],
	[Vector2i(0,1), Vector2i(0,0), 0, 1]
]

var red_blue_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 0, 2],    # Rojo-Azul
	[Vector2i(0,1), Vector2i(0,2), 0, 2],
	[Vector2i(0,1), Vector2i(-1,1), 0, 2],
	[Vector2i(0,1), Vector2i(0,0), 0, 2]
]

var yellow_blue_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 1, 2],    # Amarillo-Azul
	[Vector2i(0,1), Vector2i(0,2), 1, 2],
	[Vector2i(0,1), Vector2i(-1,1), 1, 2],
	[Vector2i(0,1), Vector2i(0,0), 1, 2]
]

var tetrominoes: Array = [
	red_red_piece, yellow_yellow_piece, blue_blue_piece,
	red_yellow_piece, red_blue_piece, yellow_blue_piece
]
var all_tetrominoes: Array = tetrominoes.duplicate(true)

# === Constantes ===
const START_POSITION: Vector2i = Vector2i(4,1)
const FALL_INTERVAL: float = 1.0
const FAST_FALL_MULTIPLIER: float = 10.0
const START_POSITION_P1: Vector2i = Vector2i(4, 1)
const START_POSITION_P2: Vector2i = Vector2i(29, 1)
const POINTS_PER_CHARGE: int = 150
const ATTACK_FALL_INTERVAL: float = 0.08
const MAX_CHARGES: int = 5

# === Sistema de colores ===
const COLOR_RED: int = 0
const COLOR_YELLOW: int = 1
const COLOR_BLUE: int = 2

# === Efectos de Match ===
var blinking_blocks: Array = []
const BLINK_COUNT: int = 3
const BLINK_DURATION: float = 0.1

# === Variables para el temporizador ===
var game_time: float = 0.0
var is_timer_running: bool = true

# === Sistema de presets para piezas iniciales ===
enum PresetType {
	CENTER,           # Todas en el centro (configuración actual)
	SPREAD,           # Distribuidas a lo ancho
	TOWERS,           # Dos torres en los extremos
	PYRAMID,          # Forma de pirámide
	RANDOM_SPREAD     # Posiciones aleatorias
}

var current_preset: PresetType = PresetType.CENTER
var preset_positions_p1: Array = []
var preset_positions_p2: Array = []

# === Sistema de piezas iniciales y secuencia compartida ===
var initial_pieces: Array = []
var shared_piece_sequence: Array = []
var is_setup_phase: bool = true
var initial_piece_fall_timer: float = 0.0
var current_initial_piece_index: int = 0
const INITIAL_PIECE_FALL_INTERVAL: float = 0.3
const INITIAL_PIECE_FALL_SPEED: float = 0.05

# === Variables para el control de piezas iniciales ===
var current_initial_piece_data: Array = []
var is_initial_piece_falling: bool = false

# === Variables para iluminación de piezas iniciales ===
var initial_pieces_blink_timer: float = 0.0
const INITIAL_PIECES_BLINK_INTERVAL: float = .5  # Un segundo
var show_initial_pieces: bool = true

# === Optimización: Cache de piezas completas ===
var complete_pieces_cache_p1: Dictionary = {}
var complete_pieces_cache_p2: Dictionary = {}
var cache_dirty_p1: bool = true
var cache_dirty_p2: bool = true

# === Sistema de grupos de piezas ===
var piece_groups_p1: Array = []
var piece_groups_p2: Array = []

# === Clase jugador - ACTUALIZADA CON SISTEMA DE RELACIONES ===
class Player:
	var board_layer: TileMapLayer
	var active_layer: TileMapLayer
	var current_position: Vector2i
	var fall_timer: float = 0.0
	var tetromino_type: Array
	var next_tetromino_type: Array
	var rotation_index: int = 0
	var active_tetromino: Array = []
	var tile_id: int = 0
	var piece_atlas: Vector2i
	var next_piece_atlas: Vector2i
	var display_score: int = 0
	var charge_score: int = 0
	var is_active: bool = true
	var is_frozen: bool = false
	var charge_points: int = 0
	var charges: int = 0
	var spent_charges: int = 0
	var pending_attacks: Array = []
	var board_colors: Dictionary = {}
	var initial_pieces_positions: Array = []
	var piece_index: int = 0  # ÍNDICE INDIVIDUAL PARA CADA JUGADOR
	
	# NUEVO: Sistema de relaciones entre piezas
	var piece_relationships: Dictionary = {}  # {piece_id: [pos1, pos2]}
	var block_to_piece: Dictionary = {}       # {pos: piece_id}
	var next_piece_id: int = 0

# === Jugadores ===
var p1: Player
var p2: Player

# === Control del juego ===
var game_paused: bool = false
var is_p2_falling_attack: bool = false
var current_attack_piece: Array = []
var current_attack_position: Vector2i
var is_p1_falling_attack: bool = false
var current_attack_piece_p1: Array = []
var current_attack_position_p1: Vector2i

# === Nodes ===
@onready var p1_board: TileMapLayer = $P1Board
@onready var p1_active: TileMapLayer = $P1Active
@onready var p2_board: TileMapLayer = $P2Board
@onready var p2_active: TileMapLayer = $P2Active
@onready var hud = $Hud

# === Referencias para el HUD ===
@onready var time_label: Label = $Hud/Time
@onready var p1_score_label: Label = $Hud/P1_Score
@onready var p1_charges_label: Label = $Hud/P1_SpecialCharges
@onready var p2_score_label: Label = $Hud/P2_Score
@onready var p2_charges_label: Label = $Hud/P2_SpecialCharges
@onready var p1_initial_label: Label = $Hud/P1_Initial
@onready var p2_initial_label: Label = $Hud/P2_Initial

# === FUNCIONES DE CACHÉ ===
func array_to_dict(array: Array) -> Dictionary:
	var dict = {}
	for item in array:
		dict[item] = true
	return dict

func dict_to_array(dict: Dictionary) -> Array:
	var array = []
	for key in dict:
		array.append(key)
	return array

func mark_cache_dirty(player: Player) -> void:
	if player == p1:
		cache_dirty_p1 = true
	else:
		cache_dirty_p2 = true

func on_board_changed(player: Player) -> void:
	mark_cache_dirty(player)

# === NUEVO: SISTEMA DE REGISTRO DE PIEZAS ===
func register_piece(player: Player, positions: Array):
	var piece_id = player.next_piece_id
	player.next_piece_id += 1
	player.piece_relationships[piece_id] = positions.duplicate()
	for pos in positions:
		player.block_to_piece[pos] = piece_id
	print("DEBUG: Pieza registrada ID ", piece_id, " en posiciones: ", positions)

func unregister_piece_positions(player: Player, positions: Array):
	for pos in positions:
		var piece_id = player.block_to_piece.get(pos, -1)
		if piece_id != -1:
			player.block_to_piece.erase(pos)
			# Actualizar la relación de la pieza
			if player.piece_relationships.has(piece_id):
				var piece_positions = player.piece_relationships[piece_id]
				piece_positions.erase(pos)
				if piece_positions.is_empty():
					player.piece_relationships.erase(piece_id)
					print("DEBUG: Pieza ID ", piece_id, " eliminada completamente")
				else:
					print("DEBUG: Pieza ID ", piece_id, " actualizada: ", piece_positions)

# === SISTEMA DE GRUPOS DE PIEZAS MEJORADO ===
func update_piece_groups(player: Player) -> void:
	var groups: Array = []
	var processed: Dictionary = {}
	var board_positions = player.board_colors.keys()
	
	for pos in board_positions:
		if processed.get(pos, false):
			continue
		
		var group = find_connected_pieces_by_relationship(player, pos, {})
		if group.size() > 0:
			groups.append(group)
			for group_pos in group:
				processed[group_pos] = true
	
	if player == p1:
		piece_groups_p1 = groups
	else:
		piece_groups_p2 = groups

func find_connected_pieces_by_relationship(player: Player, start_pos: Vector2i, visited: Dictionary) -> Array:
	if visited.get(start_pos, false):
		return []
	
	visited[start_pos] = true
	var group = [start_pos]
	
	# Obtener el ID de la pieza original
	var start_piece_id = player.block_to_piece.get(start_pos, -1)
	
	# Direcciones de conexión (horizontal y vertical)
	var directions = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	
	for dir in directions:
		var neighbor_pos = start_pos + dir
		if (player.board_colors.has(neighbor_pos) and 
			not visited.get(neighbor_pos, false)):
			
			var neighbor_piece_id = player.block_to_piece.get(neighbor_pos, -2)
			
			# SOLO se conectan si son de la MISMA PIEZA original
			if start_piece_id == neighbor_piece_id:
				var neighbor_group = find_connected_pieces_by_relationship(player, neighbor_pos, visited)
				group.append_array(neighbor_group)
	
	return group

func is_position_supported(player: Player, pos: Vector2i, ignore_groups: Array = []) -> bool:
	# Si está en el fondo, está soportado
	if pos.y >= 19:
		return true
	
	# Verificar si hay algo directamente debajo
	var pos_below = pos + Vector2i.DOWN
	if player.board_colors.has(pos_below):
		# Verificar que el bloque de abajo no esté en el mismo grupo (ignorado)
		var is_in_ignored_group = false
		for group in ignore_groups:
			if pos_below in group:
				is_in_ignored_group = true
				break
		if not is_in_ignored_group:
			return true
	
	return false

func can_piece_fall(player: Player, piece_group: Array) -> bool:
	# Verificar si NINGUNO de los bloques del grupo está soportado
	for pos in piece_group:
		if is_position_supported(player, pos, [piece_group]):
			return false
	return true

func get_piece_fall_distance(player: Player, piece_group: Array) -> int:
	var max_fall_distance = 20  # Máxima distancia posible
	
	for pos in piece_group:
		var fall_distance_for_pos = 20
		
		# Buscar hacia abajo hasta encontrar un obstáculo
		for distance in range(1, 21):
			var check_pos = pos + Vector2i(0, distance)
			
			# Si llegamos al fondo
			if check_pos.y > 19:
				fall_distance_for_pos = distance - 1
				break
			
			# Si encontramos un bloque que no está en nuestro grupo
			if player.board_colors.has(check_pos) and not (check_pos in piece_group):
				fall_distance_for_pos = distance - 1
				break
		
		# Tomar la distancia mínima de todos los bloques del grupo
		max_fall_distance = min(max_fall_distance, fall_distance_for_pos)
	
	return max_fall_distance

# === SISTEMA DE GRAVEDAD RECURSIVA MEJORADO ===
func apply_gravity_improved(player: Player, min_x: int, max_x: int) -> void:
	# Primero actualizar los grupos de piezas
	update_piece_groups(player)
	
	var player_groups = piece_groups_p1 if player == p1 else piece_groups_p2
	var groups_to_fall = []
	var fall_distances = {}
	
	# Identificar qué grupos pueden caer y cuánto
	for group in player_groups:
		if can_piece_fall(player, group):
			var distance = get_piece_fall_distance(player, group)
			if distance > 0:
				groups_to_fall.append(group)
				fall_distances[group] = distance
	
	# Aplicar gravedad a los grupos que pueden caer
	if groups_to_fall.size() > 0:
		# Mover todos los grupos que pueden caer
		for group in groups_to_fall:
			var distance = fall_distances[group]
			move_piece_group_down(player, group, distance)
		
		# Esperar un poco y verificar si hay más piezas que caer (gravedad recursiva)
		await get_tree().create_timer(0.1).timeout
		
		# Verificar si después de mover hay más piezas que puedan caer
		var more_groups_fell = await apply_recursive_gravity(player, 25)  # Máximo 5 niveles de recursión
		
		# Actualizar visibilidad después de toda la gravedad
		update_initial_pieces_visibility()
		
		# Solo verificar matches si no hubo más gravedad recursiva
		# para evitar verificaciones múltiples
		if not more_groups_fell:
			if player == p1:
				check_and_clear_matches_p1()
			else:
				check_and_clear_matches_p2()

func apply_recursive_gravity(player: Player, max_recursion: int) -> bool:
	if max_recursion <= 0:
		return false
	
	update_piece_groups(player)
	var player_groups = piece_groups_p1 if player == p1 else piece_groups_p2
	var groups_to_fall = []
	var fall_distances = {}
	var any_group_fell = false
	
	# Identificar qué grupos pueden caer después del movimiento anterior
	for group in player_groups:
		if can_piece_fall(player, group):
			var distance = get_piece_fall_distance(player, group)
			if distance > 0:
				groups_to_fall.append(group)
				fall_distances[group] = distance
				any_group_fell = true
	
	# Mover los grupos que pueden caer
	if groups_to_fall.size() > 0:
		for group in groups_to_fall:
			var distance = fall_distances[group]
			move_piece_group_down(player, group, distance)
		
		# Esperar un poco
		await get_tree().create_timer(0.05).timeout
		
		# Llamar recursivamente
		return await apply_recursive_gravity(player, max_recursion - 1)
	
	return any_group_fell

func move_piece_group_down(player: Player, group: Array, distance: int = 1) -> void:
	if distance <= 0:
		return
	
	# Primero limpiar las posiciones actuales
	var colors_to_restore = {}
	var initial_positions_to_restore = []
	var active_layer_positions_to_restore = []
	var piece_ids_to_restore = {}
	
	for pos in group:
		# Guardar información para restaurar
		colors_to_restore[pos] = player.board_colors[pos]
		piece_ids_to_restore[pos] = player.block_to_piece.get(pos, -1)
		if player.initial_pieces_positions.has(pos):
			initial_positions_to_restore.append(pos)
		if (player == p1 and p1_active.get_cell_source_id(pos) != -1) or (player == p2 and p2_active.get_cell_source_id(pos) != -1):
			active_layer_positions_to_restore.append(pos)
		
		# Limpiar
		player.board_layer.erase_cell(pos)
		player.board_colors.erase(pos)
		player.block_to_piece.erase(pos)
		if player.initial_pieces_positions.has(pos):
			player.initial_pieces_positions.erase(pos)
		if player == p1:
			p1_active.erase_cell(pos)
		else:
			p2_active.erase_cell(pos)
	
	# Calcular nuevas posiciones
	var new_positions = []
	for pos in group:
		var new_pos = pos + Vector2i(0, distance)
		new_positions.append(new_pos)
	
	# Colocar en nuevas posiciones
	for i in range(group.size()):
		var old_pos = group[i]
		var new_pos = new_positions[i]
		var color = colors_to_restore[old_pos]
		var piece_id = piece_ids_to_restore[old_pos]
		var atlas_coords = Vector2i(color, 0)
		
		player.board_layer.set_cell(new_pos, player.tile_id, atlas_coords)
		player.board_colors[new_pos] = color
		
		# Restaurar relaciones de pieza
		if piece_id != -1:
			player.block_to_piece[new_pos] = piece_id
			# Actualizar piece_relationships
			if player.piece_relationships.has(piece_id):
				var positions = player.piece_relationships[piece_id]
				if old_pos in positions:
					positions.erase(old_pos)
					positions.append(new_pos)
		
		# Restaurar información adicional
		if old_pos in initial_positions_to_restore:
			player.initial_pieces_positions.append(new_pos)
		
		if old_pos in active_layer_positions_to_restore and show_initial_pieces:
			if player == p1:
				p1_active.set_cell(new_pos, p1.tile_id, Vector2i(6, 0))
			else:
				p2_active.set_cell(new_pos, p2.tile_id, Vector2i(6, 0))

# === Inicio ===
func _ready() -> void:
	print("=== INICIANDO JUEGO ===")
	p1 = Player.new()
	p1.board_layer = p1_board
	p1.active_layer = p1_active
	p1.tile_id = 1
	p1.board_colors = {}
	p1.initial_pieces_positions = []
	p1.piece_index = 0
	p1.piece_relationships = {}
	p1.block_to_piece = {}
	p1.next_piece_id = 0

	p2 = Player.new()
	p2.board_layer = p2_board
	p2.active_layer = p2_active
	p2.tile_id = 0
	p2.board_colors = {}
	p2.initial_pieces_positions = []
	p2.piece_index = 0
	p2.piece_relationships = {}
	p2.block_to_piece = {}
	p2.next_piece_id = 0

	setup_initial_pieces()
	setup_shared_sequence()
	select_random_preset()
	setup_preset_positions()
	
	freeze_all_players(true)
	is_setup_phase = true
	
	hud.get_node("GameOverLabel").visible = false
	hud.get_node("StartNewGame").visible = false
	
	game_time = 0.0
	is_timer_running = true
	initial_pieces_blink_timer = 0.0
	show_initial_pieces = true
	
	update_hud_display()
	print("DEBUG: _ready() completado. Preset seleccionado: ", PresetType.keys()[current_preset])

# === Sistema de Presets ===
func select_random_preset() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	current_preset = rng.randi() % PresetType.size() as PresetType
	print("DEBUG: Preset seleccionado: ", PresetType.keys()[current_preset])

func setup_preset_positions() -> void:
	preset_positions_p1.clear()
	preset_positions_p2.clear()
	
	match current_preset:
		PresetType.CENTER:
			for i in range(10):
				preset_positions_p1.append(START_POSITION_P1)
				preset_positions_p2.append(START_POSITION_P2)
		
		PresetType.SPREAD:
			var x_positions = [2, 3, 4, 5, 6, 7, 8, 2, 5, 8]
			var y_starts = [1, 1, 1, 1, 1, 1, 1, 3, 3, 3]
			for i in range(10):
				preset_positions_p1.append(Vector2i(x_positions[i], y_starts[i]))
				preset_positions_p2.append(Vector2i(x_positions[i] + 25, y_starts[i]))
		
		PresetType.TOWERS:
			var left_tower_x = [1, 1, 1, 2, 2]
			var left_tower_y = [1, 2, 3, 1, 2]
			var right_tower_x = [8, 8, 8, 7, 7]
			var right_tower_y = [1, 2, 3, 1, 2]
			
			var x_positions = left_tower_x + right_tower_x
			var y_positions = left_tower_y + right_tower_y
			
			for i in range(10):
				preset_positions_p1.append(Vector2i(x_positions[i], y_positions[i]))
				preset_positions_p2.append(Vector2i(x_positions[i] + 25, y_positions[i]))
		
		PresetType.PYRAMID:
			var pyramid_positions = [
				Vector2i(5, 1), Vector2i(4, 2), Vector2i(6, 2),
				Vector2i(3, 3), Vector2i(5, 3), Vector2i(7, 3),
				Vector2i(2, 4), Vector2i(4, 4), Vector2i(6, 4), Vector2i(8, 4)
			]
			
			for i in range(10):
				preset_positions_p1.append(pyramid_positions[i])
				preset_positions_p2.append(Vector2i(pyramid_positions[i].x + 25, pyramid_positions[i].y))
		
		PresetType.RANDOM_SPREAD:
			var rng = RandomNumberGenerator.new()
			rng.seed = 54321
			
			for i in range(10):
				var x = rng.randi_range(1, 8)
				var y = rng.randi_range(1, 5)
				preset_positions_p1.append(Vector2i(x, y))
				preset_positions_p2.append(Vector2i(x + 25, y))
	
	print("DEBUG: Posiciones del preset configuradas")

# === Configuración de piezas iniciales ===
func setup_initial_pieces() -> void:
	initial_pieces = [
		red_red_piece, yellow_yellow_piece, blue_blue_piece,
		red_yellow_piece, red_blue_piece, yellow_blue_piece,
		red_red_piece, yellow_yellow_piece, blue_blue_piece, red_yellow_piece
	]
	print("DEBUG: ", initial_pieces.size(), " piezas iniciales configuradas")

# === Configuración de secuencia compartida ===
func setup_shared_sequence() -> void:
	shared_piece_sequence = []
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	for i in range(200):
		if tetrominoes.is_empty():
			tetrominoes = all_tetrominoes.duplicate(true)
		tetrominoes.shuffle()
		var t = tetrominoes.pop_front()
		if t == null or t.is_empty():
			t = all_tetrominoes.pick_random()
		shared_piece_sequence.append(t)
	
	print("DEBUG: Secuencia de 200 piezas creada")

# === Obtener siguiente pieza para un jugador específico ===
func get_next_piece_for_player(player: Player) -> Array:
	if shared_piece_sequence.is_empty():
		return all_tetrominoes.pick_random()
	
	var piece = shared_piece_sequence[player.piece_index]
	player.piece_index = (player.piece_index + 1) % shared_piece_sequence.size()
	return piece

# === Sistema de colocación de piezas iniciales ===
func place_initial_pieces(delta: float) -> void:
	if not is_setup_phase:
		return
	
	if not is_initial_piece_falling and current_initial_piece_index < initial_pieces.size():
		initial_piece_fall_timer += delta
		
		if initial_piece_fall_timer >= INITIAL_PIECE_FALL_INTERVAL:
			initial_piece_fall_timer = 0.0
			start_next_initial_piece()
	
	elif is_initial_piece_falling:
		process_initial_piece_fall(delta)

func start_next_initial_piece() -> void:
	print("DEBUG: start_next_initial_piece() - current_initial_piece_index = ", current_initial_piece_index)
	
	if current_initial_piece_index >= initial_pieces.size():
		return
	
	current_initial_piece_data = initial_pieces[current_initial_piece_index]
	print("DEBUG: Colocando pieza inicial ", current_initial_piece_index + 1, " de ", initial_pieces.size())
	
	place_initial_piece_for_both_players()
	current_initial_piece_index += 1

func clear_all_active_layers() -> void:
	print("DEBUG: Limpiando TODAS las capas activas")
	
	for x in range(1, 10):
		for y in range(1, 20):
			p1_active.erase_cell(Vector2i(x, y))
	
	for x in range(26, 35):
		for y in range(1, 20):
			p2_active.erase_cell(Vector2i(x, y))
	
	print("DEBUG: Capas activas limpiadas")

func place_initial_piece_for_both_players() -> void:
	var preset_pos_p1 = preset_positions_p1[current_initial_piece_index]
	var preset_pos_p2 = preset_positions_p2[current_initial_piece_index]
	
	p1.current_position = preset_pos_p1
	p1.rotation_index = 0
	p1.active_tetromino = current_initial_piece_data[0]
	
	p2.current_position = preset_pos_p2
	p2.rotation_index = 0
	p2.active_tetromino = current_initial_piece_data[0]
	
	render_initial_piece_both()
	is_initial_piece_falling = true
	print("DEBUG: Pieza inicial ", current_initial_piece_index, " colocada")

func render_initial_piece_both() -> void:
	if current_initial_piece_data == null or current_initial_piece_data.is_empty():
		return
	
	var rotation_data = current_initial_piece_data[0]
	if rotation_data == null or rotation_data.size() < 4:
		return
	
	for i in range(2):
		var block_pos = p1.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1_active.set_cell(block_pos, p1.tile_id, atlas_coords)
	
	for i in range(2):
		var block_pos = p2.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2_active.set_cell(block_pos, p2.tile_id, atlas_coords)

func clear_initial_piece_both() -> void:
	if current_initial_piece_data == null or current_initial_piece_data.is_empty():
		return
	
	var rotation_data = current_initial_piece_data[0]
	if rotation_data == null or rotation_data.size() < 2:
		return
	
	for i in range(2):
		var block_pos = p1.current_position + rotation_data[i]
		p1_active.erase_cell(block_pos)
	
	for i in range(2):
		var block_pos = p2.current_position + rotation_data[i]
		p2_active.erase_cell(block_pos)

func process_initial_piece_fall(delta: float) -> void:
	p1.fall_timer += delta
	p2.fall_timer += delta
	
	if p1.fall_timer >= INITIAL_PIECE_FALL_SPEED or p2.fall_timer >= INITIAL_PIECE_FALL_SPEED:
		var p1_blocked = is_initial_piece_blocked_below(p1)
		var p2_blocked = is_initial_piece_blocked_below(p2)
		
		if p1_blocked and p2_blocked:
			land_initial_piece_both()
			is_initial_piece_falling = false
			p1.fall_timer = 0.0
			p2.fall_timer = 0.0
			
			if current_initial_piece_index >= initial_pieces.size():
				print("DEBUG: Última pieza aterrizada - activando transición al juego normal")
				transition_to_normal_game()
		else:
			clear_initial_piece_both()
			
			if not p1_blocked:
				p1.current_position += Vector2i.DOWN
			if not p2_blocked:
				p2.current_position += Vector2i.DOWN
				
			render_initial_piece_both()
			p1.fall_timer = 0.0
			p2.fall_timer = 0.0

func transition_to_normal_game() -> void:
	print("DEBUG: ¡TRANSICIÓN AL JUEGO NORMAL ACTIVADA!")
	is_setup_phase = false
	is_initial_piece_falling = false
	
	clear_all_active_layers()
	
	start_new_game_p1()
	start_new_game_p2()
	
	initial_pieces_blink_timer = 0.0
	show_initial_pieces = true
	update_initial_pieces_visibility()
	
	freeze_all_players(false)
	
	print("DEBUG: ¡JUEGO NORMAL INICIADO!")

func is_initial_piece_blocked_below(player: Player) -> bool:
	if current_initial_piece_data == null or current_initial_piece_data.is_empty():
		return true
	
	var rotation_data = current_initial_piece_data[0]
	if rotation_data == null or rotation_data.size() < 2:
		return true
	
	for i in range(2):
		var pos = player.current_position + rotation_data[i] + Vector2i.DOWN
		if pos.y > 19:
			return true
		if player.board_layer.get_cell_source_id(pos) != -1:
			return true
	return false

func land_initial_piece_both() -> void:
	if current_initial_piece_data == null or current_initial_piece_data.is_empty():
		return
	
	var rotation_data = current_initial_piece_data[0]
	if rotation_data == null or rotation_data.size() < 4:
		return
	
	print("DEBUG: Aterrizando pieza inicial ", current_initial_piece_index)
	
	# Registrar pieza para P1
	var p1_positions = []
	for i in range(2):
		var block_pos = p1.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1.board_layer.set_cell(block_pos, p1.tile_id, atlas_coords)
		p1.board_colors[block_pos] = color_index
		p1_positions.append(block_pos)
	p1.initial_pieces_positions.append_array(p1_positions)
	register_piece(p1, p1_positions)
	
	# Registrar pieza para P2
	var p2_positions = []
	for i in range(2):
		var block_pos = p2.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2.board_layer.set_cell(block_pos, p2.tile_id, atlas_coords)
		p2.board_colors[block_pos] = color_index
		p2_positions.append(block_pos)
	p2.initial_pieces_positions.append_array(p2_positions)
	register_piece(p2, p2_positions)
	
	clear_initial_piece_both()
	
	check_and_clear_matches_p1()
	check_and_clear_matches_p2()

# === Sistema de iluminación constante para piezas iniciales ===
func update_initial_pieces_blink(delta: float) -> void:
	if is_setup_phase:
		return
	
	if p1.initial_pieces_positions.size() > 0 or p2.initial_pieces_positions.size() > 0:
		initial_pieces_blink_timer += delta
		if initial_pieces_blink_timer >= INITIAL_PIECES_BLINK_INTERVAL:
			initial_pieces_blink_timer = 0.0
			show_initial_pieces = not show_initial_pieces
			update_initial_pieces_visibility()

func update_initial_pieces_visibility() -> void:
	for pos in p1.initial_pieces_positions:
		if p1.board_colors.has(pos):
			var color = p1.board_colors[pos]
			p1.board_layer.set_cell(pos, p1.tile_id, Vector2i(color, 0))
			
			if show_initial_pieces:
				p1_active.set_cell(pos, p1.tile_id, Vector2i(6, 0))
			else:
				p1_active.erase_cell(pos)
	
	for pos in p2.initial_pieces_positions:
		if p2.board_colors.has(pos):
			var color = p2.board_colors[pos]
			p2.board_layer.set_cell(pos, p2.tile_id, Vector2i(color, 0))
			
			if show_initial_pieces:
				p2_active.set_cell(pos, p2.tile_id, Vector2i(6, 0))
			else:
				p2_active.erase_cell(pos)

# === Sistema de Congelamiento ===
func freeze_player(player: Player, freeze: bool) -> void:
	player.is_frozen = freeze

func freeze_all_players(freeze: bool) -> void:
	p1.is_frozen = freeze
	p2.is_frozen = freeze

func freeze_game(freeze: bool) -> void:
	game_paused = freeze
	freeze_all_players(freeze)

# === Sistema de Cargas ===
func add_points_to_charges(player: Player, points: int) -> void:
	player.display_score += points
	
	if player.charges < MAX_CHARGES:
		player.charge_score += points
		player.charge_points += points
		
		while player.charge_points >= POINTS_PER_CHARGE and player.charges < MAX_CHARGES:
			player.charge_points -= POINTS_PER_CHARGE
			player.charges += 1
	else:
		print("Cargas al máximo (", MAX_CHARGES, "), puntos para cargas perdidos: ", points, " pero puntos totales aumentan")
	
	update_hud_display()

# === Actualización del HUD ===
func update_hud_display() -> void:
	var minutes: int = int(game_time / 60.0)
	var seconds: int = int(game_time) % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
	var p1_initial_cleared = get_initial_pieces_cleared(p1)
	p1_score_label.text = "P1: " + str(p1.display_score)
	p1_charges_label.text = "Cargas: " + str(p1.charges) + "/" + str(MAX_CHARGES)
	p1_initial_label.text = "Inicial: " + str(p1_initial_cleared) + "/10"
	
	var p2_initial_cleared = get_initial_pieces_cleared(p2)
	p2_score_label.text = "P2: " + str(p2.display_score)
	p2_charges_label.text = "Cargas: " + str(p2.charges) + "/" + str(MAX_CHARGES)
	p2_initial_label.text = "Inicial: " + str(p2_initial_cleared) + "/10"

# === Verificar condición de victoria ===
func check_initial_pieces_win_condition() -> void:
	var p1_cleared = get_initial_pieces_cleared(p1)
	var p2_cleared = get_initial_pieces_cleared(p2)
	
	print("DEBUG: Verificando victoria - P1: ", p1_cleared, "/10, P2: ", p2_cleared, "/10")
	
	if p1_cleared >= 10 and p2_cleared >= 10:
		hud.get_node("GameOverLabel").text = "EMPATE!\nAmbos limpiaron las 10 piezas iniciales!"
		hud.get_node("GameOverLabel").visible = true
		hud.get_node("StartNewGame").visible = true
		freeze_game(true)
		is_timer_running = false
		print("DEBUG: ¡EMPATE DETECTADO!")
	elif p1_cleared >= 10:
		hud.get_node("GameOverLabel").text = "JUGADOR 1 GANA!\nLimpio las 10 piezas iniciales primero!"
		hud.get_node("GameOverLabel").visible = true
		hud.get_node("StartNewGame").visible = true
		freeze_game(true)
		is_timer_running = false
		print("DEBUG: ¡VICTORIA P1 DETECTADA!")
	elif p2_cleared >= 10:
		hud.get_node("GameOverLabel").text = "JUGADOR 2 GANA!\nLimpio las 10 piezas iniciales primero!"
		hud.get_node("GameOverLabel").visible = true
		hud.get_node("StartNewGame").visible = true
		freeze_game(true)
		is_timer_running = false
		print("DEBUG: ¡VICTORIA P2 DETECTADA!")

# === Contar piezas iniciales eliminadas ===
func get_initial_pieces_cleared(player: Player) -> int:
	var total_initial_blocks = 20
	var remaining_initial_blocks = 0
	
	for pos in player.initial_pieces_positions:
		if player.board_layer.get_cell_source_id(pos) != -1:
			remaining_initial_blocks += 1
	
	var cleared_blocks = total_initial_blocks - remaining_initial_blocks
	var cleared_pieces = int(cleared_blocks / 2.0)
	cleared_pieces = min(cleared_pieces, 10)
	
	print("DEBUG: Piezas iniciales limpias - Jugador: ", "P1" if player == p1 else "P2", 
		  " - Bloques: ", cleared_blocks, "/20 - Piezas: ", cleared_pieces, "/10")
	
	return cleared_pieces

# === Sistema de efectos visuales para matches ===
func start_match_animation(player: Player, matched_positions: Array) -> void:
	blinking_blocks = matched_positions.duplicate()
	start_blink_sequence(player, matched_positions, 0)

func start_blink_sequence(player: Player, matched_positions: Array, current_blink: int) -> void:
	if current_blink >= BLINK_COUNT * 2:
		clear_matches_after_animation(player, matched_positions)
		return
	
	var target_alpha = 0.0 if current_blink % 2 == 0 else 1.0
	update_block_visibility(target_alpha)
	
	await get_tree().create_timer(BLINK_DURATION).timeout
	start_blink_sequence(player, matched_positions, current_blink + 1)

func update_block_visibility(alpha: float) -> void:
	for block_pos in blinking_blocks:
		if block_pos.x >= 1 and block_pos.x <= 9:
			if alpha == 0.0:
				p1.board_layer.set_cell(block_pos, p1.tile_id, Vector2i(3, 0))
			else:
				var color = p1.board_colors[block_pos]
				p1.board_layer.set_cell(block_pos, p1.tile_id, Vector2i(color, 0))
		
		elif block_pos.x >= 26 and block_pos.x <= 34:
			if alpha == 0.0:
				p2.board_layer.set_cell(block_pos, p2.tile_id, Vector2i(3, 0))
			else:
				var color = p2.board_colors[block_pos]
				p2.board_layer.set_cell(block_pos, p2.tile_id, Vector2i(color, 0))

func clear_matches_after_animation(player: Player, matched_positions: Array) -> void:
	clear_matches_directly(player, matched_positions)
	blinking_blocks.clear()
	check_initial_pieces_win_condition()

func clear_matches_directly(player: Player, matched_positions: Array) -> void:
	# NUEVO: Desregistrar las posiciones antes de limpiar
	unregister_piece_positions(player, matched_positions)
	
	for pos in matched_positions:
		player.board_layer.erase_cell(pos)
		player.board_colors.erase(pos)
		if player == p1:
			p1_active.erase_cell(pos)
		else:
			p2_active.erase_cell(pos)
		if player.initial_pieces_positions.has(pos):
			player.initial_pieces_positions.erase(pos)
	
	on_board_changed(player)
	
	if player == p1:
		apply_gravity_improved(p1, 1, 10)
	else:
		apply_gravity_improved(p2, 26, 35)

# === P1 - FUNCIONES ESPECÍFICAS ===
func start_new_game_p1() -> void:
	p1.display_score = 0
	p1.charge_score = 0
	p1.is_active = true
	p1.is_frozen = false
	p1.charge_points = 0
	p1.charges = 0
	p1.spent_charges = 0
	p1.pending_attacks = []
	# NO limpiar relaciones de piezas iniciales
	
	clear_tetromino_p1()
	
	p1.tetromino_type = get_next_piece_for_player(p1)
	p1.next_tetromino_type = get_next_piece_for_player(p1)
	p1.rotation_index = 0
	p1.current_position = START_POSITION_P1
	if p1.tetromino_type != null and not p1.tetromino_type.is_empty():
		p1.active_tetromino = p1.tetromino_type[p1.rotation_index]
	render_tetromino_p1()
	
	update_hud_display()
	print("DEBUG: P1 - Pieza normal inicializada. Índice actual: ", p1.piece_index)

func initialize_tetromino_p1() -> void:
	p1.current_position = START_POSITION_P1
	p1.rotation_index = 0
	if p1.tetromino_type != null and not p1.tetromino_type.is_empty():
		p1.active_tetromino = p1.tetromino_type[p1.rotation_index]
		render_tetromino_p1()
		print("DEBUG: Tetromino P1 inicializado y renderizado")

func render_tetromino_p1() -> void:
	if p1.tetromino_type == null or p1.tetromino_type.is_empty():
		print("DEBUG: ERROR - No hay tetromino_type para P1")
		return
	
	var rotation_data = p1.tetromino_type[p1.rotation_index]
	if rotation_data == null or rotation_data.size() < 4:
		print("DEBUG: ERROR - Datos de rotación inválidos para P1")
		return
	
	for i in range(2):
		var block_pos = p1.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1_active.set_cell(block_pos, p1.tile_id, atlas_coords)
	
	print("DEBUG: Tetromino P1 renderizado en posición: ", p1.current_position)

func clear_tetromino_p1() -> void:
	if p1.tetromino_type == null or p1.tetromino_type.is_empty():
		return
	
	var rotation_data = p1.tetromino_type[p1.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return
	
	for i in range(2):
		var block_pos = p1.current_position + rotation_data[i]
		p1_active.erase_cell(block_pos)

func move_tetromino_p1(direction: Vector2i) -> void:
	if p1.is_frozen or game_paused:
		print("DEBUG: P1 congelado o juego pausado")
		return
	if is_valid_move_p1(direction):
		clear_tetromino_p1()
		p1.current_position += direction
		render_tetromino_p1()
		print("DEBUG: P1 movido: ", direction)

func rotate_tetromino_p1() -> void:
	if p1.is_frozen or game_paused:
		return
	if is_valid_rotation_p1():
		clear_tetromino_p1()
		p1.rotation_index = (p1.rotation_index + 1) % 4
		if p1.tetromino_type != null and not p1.tetromino_type.is_empty():
			p1.active_tetromino = p1.tetromino_type[p1.rotation_index]
		render_tetromino_p1()
		print("DEBUG: P1 rotado")

func is_valid_move_p1(direction: Vector2i) -> bool:
	if p1.tetromino_type == null or p1.tetromino_type.is_empty():
		return false
	
	var rotation_data = p1.tetromino_type[p1.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return false
	
	for i in range(2):
		var pos = p1.current_position + rotation_data[i] + direction
		if pos.x < 1 or pos.x > 9 or pos.y > 19:
			return false
		if p1.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

func is_valid_rotation_p1() -> bool:
	if p1.tetromino_type == null or p1.tetromino_type.is_empty():
		return false
	
	var next_rotation = (p1.rotation_index + 1) % 4
	var rotated = p1.tetromino_type[next_rotation]
	if rotated == null or rotated.size() < 2:
		return false
	
	for i in range(2):
		var pos = p1.current_position + rotated[i]
		if pos.x < 1 or pos.x > 9 or pos.y > 19:
			return false
		if p1.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

func land_tetromino_p1() -> void:
	if p1.tetromino_type == null or p1.tetromino_type.is_empty():
		return
	
	var rotation_data = p1.tetromino_type[p1.rotation_index]
	if rotation_data == null or rotation_data.size() < 4:
		return
	
	# Registrar la nueva pieza
	var positions = []
	for i in range(2):
		var block_pos = p1.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1.board_layer.set_cell(block_pos, p1.tile_id, atlas_coords)
		p1.board_colors[block_pos] = color_index
		positions.append(block_pos)
	
	register_piece(p1, positions)
	
	check_and_clear_matches_p1()
	spawn_next_tetromino_p1()

func is_blocked_below_p1() -> bool:
	if p1.tetromino_type == null or p1.tetromino_type.is_empty():
		return true
	
	var rotation_data = p1.tetromino_type[p1.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return true
	
	for i in range(2):
		var pos = p1.current_position + rotation_data[i] + Vector2i.DOWN
		if pos.y > 19:
			return true
		if p1.board_layer.get_cell_source_id(pos) != -1:
			return true
	return false

# === P2 - FUNCIONES ESPECÍFICAS ===
func start_new_game_p2() -> void:
	p2.display_score = 0
	p2.charge_score = 0
	p2.is_active = true
	p2.is_frozen = false
	p2.charge_points = 0
	p2.charges = 0
	p2.spent_charges = 0
	p2.pending_attacks = []
	# NO limpiar relaciones de piezas iniciales
	
	clear_tetromino_p2()
	
	p2.tetromino_type = get_next_piece_for_player(p2)
	p2.next_tetromino_type = get_next_piece_for_player(p2)
	p2.rotation_index = 0
	p2.current_position = START_POSITION_P2
	if p2.tetromino_type != null and not p2.tetromino_type.is_empty():
		p2.active_tetromino = p2.tetromino_type[p2.rotation_index]
	render_tetromino_p2()
	
	update_hud_display()
	print("DEBUG: P2 - Pieza normal inicializada. Índice actual: ", p2.piece_index)

func initialize_tetromino_p2() -> void:
	p2.current_position = START_POSITION_P2
	p2.rotation_index = 0
	if p2.tetromino_type != null and not p2.tetromino_type.is_empty():
		p2.active_tetromino = p2.tetromino_type[p2.rotation_index]
		render_tetromino_p2()
		print("DEBUG: Tetromino P2 inicializado y renderizado")

func render_tetromino_p2() -> void:
	if p2.tetromino_type == null or p2.tetromino_type.is_empty():
		print("DEBUG: ERROR - No hay tetromino_type para P2")
		return
	
	var rotation_data = p2.tetromino_type[p2.rotation_index]
	if rotation_data == null or rotation_data.size() < 4:
		print("DEBUG: ERROR - Datos de rotación inválidos para P2")
		return
	
	for i in range(2):
		var block_pos = p2.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2_active.set_cell(block_pos, p2.tile_id, atlas_coords)
	
	print("DEBUG: Tetromino P2 renderizado en posición: ", p2.current_position)

func clear_tetromino_p2() -> void:
	if p2.tetromino_type == null or p2.tetromino_type.is_empty():
		return
	
	var rotation_data = p2.tetromino_type[p2.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return
	
	for i in range(2):
		var block_pos = p2.current_position + rotation_data[i]
		p2_active.erase_cell(block_pos)

func move_tetromino_p2(direction: Vector2i) -> void:
	if p2.is_frozen or game_paused:
		print("DEBUG: P2 congelado o juego pausado")
		return
	if is_valid_move_p2(direction):
		clear_tetromino_p2()
		p2.current_position += direction
		render_tetromino_p2()
		print("DEBUG: P2 movido: ", direction)

func rotate_tetromino_p2() -> void:
	if p2.is_frozen or game_paused:
		return
	if is_valid_rotation_p2():
		clear_tetromino_p2()
		p2.rotation_index = (p2.rotation_index + 1) % 4
		if p2.tetromino_type != null and not p2.tetromino_type.is_empty():
			p2.active_tetromino = p2.tetromino_type[p2.rotation_index]
		render_tetromino_p2()
		print("DEBUG: P2 rotado")

func is_valid_move_p2(direction: Vector2i) -> bool:
	if p2.tetromino_type == null or p2.tetromino_type.is_empty():
		return false
	
	var rotation_data = p2.tetromino_type[p2.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return false
	
	for i in range(2):
		var pos = p2.current_position + rotation_data[i] + direction
		if pos.x < 26 or pos.x > 34 or pos.y > 19:
			return false
		if p2.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

func is_valid_rotation_p2() -> bool:
	if p2.tetromino_type == null or p2.tetromino_type.is_empty():
		return false
	
	var next_rotation = (p2.rotation_index + 1) % 4
	var rotated = p2.tetromino_type[next_rotation]
	if rotated == null or rotated.size() < 2:
		return false
	
	for i in range(2):
		var pos = p2.current_position + rotated[i]
		if pos.x < 26 or pos.x > 34 or pos.y > 19:
			return false
		if p2.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

func land_tetromino_p2() -> void:
	if p2.tetromino_type == null or p2.tetromino_type.is_empty():
		return
	
	var rotation_data = p2.tetromino_type[p2.rotation_index]
	if rotation_data == null or rotation_data.size() < 4:
		return
	
	# Registrar la nueva pieza
	var positions = []
	for i in range(2):
		var block_pos = p2.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2.board_layer.set_cell(block_pos, p2.tile_id, atlas_coords)
		p2.board_colors[block_pos] = color_index
		positions.append(block_pos)
	
	register_piece(p2, positions)
	
	check_and_clear_matches_p2()
	spawn_next_tetromino_p2()

func is_blocked_below_p2() -> bool:
	if p2.tetromino_type == null or p2.tetromino_type.is_empty():
		return true
	
	var rotation_data = p2.tetromino_type[p2.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return true
	
	for i in range(2):
		var pos = p2.current_position + rotation_data[i] + Vector2i.DOWN
		if pos.y > 19:
			return true
		if p2.board_layer.get_cell_source_id(pos) != -1:
			return true
	return false

# === Sistema de detección de matches ===
func check_and_clear_matches_p1() -> void:
	var matched_positions = find_matches(p1, 1, 10)
	process_matches(p1, matched_positions)

func check_and_clear_matches_p2() -> void:
	var matched_positions = find_matches(p2, 26, 35)
	process_matches(p2, matched_positions)

func find_matches(player: Player, min_x: int, max_x: int) -> Array:
	var matched_positions = []
	
	for y in range(1, 20):
		var current_color = -1
		var current_line = []
		
		for x in range(min_x, max_x):
			var pos = Vector2i(x, y)
			if player.board_colors.has(pos):
				var color = player.board_colors[pos]
				if color == current_color:
					current_line.append(pos)
				else:
					if current_line.size() >= 4:
						matched_positions.append_array(current_line)
					current_color = color
					current_line = [pos]
			else:
				if current_line.size() >= 4:
					matched_positions.append_array(current_line)
				current_color = -1
				current_line = []
		
		if current_line.size() >= 4:
			matched_positions.append_array(current_line)
	
	for x in range(min_x, max_x):
		var current_color = -1
		var current_line = []
		
		for y in range(1, 20):
			var pos = Vector2i(x, y)
			if player.board_colors.has(pos):
				var color = player.board_colors[pos]
				if color == current_color:
					current_line.append(pos)
				else:
					if current_line.size() >= 4:
						matched_positions.append_array(current_line)
					current_color = color
					current_line = [pos]
			else:
				if current_line.size() >= 4:
					matched_positions.append_array(current_line)
				current_color = -1
				current_line = []
		
		if current_line.size() >= 4:
			matched_positions.append_array(current_line)
	
	var unique_matches = []
	for pos in matched_positions:
		if not unique_matches.has(pos):
			unique_matches.append(pos)
	
	return unique_matches

func process_matches(player: Player, matched_positions: Array) -> void:
	if matched_positions.size() > 0:
		var points = matched_positions.size() * 25
		
		var initial_pieces_cleared = count_initial_pieces_cleared(player, matched_positions)
		if initial_pieces_cleared > 0:
			print("DEBUG: Se limpiaron ", initial_pieces_cleared, " bloques iniciales en el match")
			check_initial_pieces_win_condition()
		
		start_match_animation(player, matched_positions)
		add_points_to_charges(player, points)

func count_initial_pieces_cleared(player: Player, matched_positions: Array) -> int:
	var count = 0
	for pos in matched_positions:
		if player.initial_pieces_positions.has(pos):
			count += 1
	return count

# === Sistema de gravedad ===
func apply_gravity_p1() -> void:
	apply_gravity_improved(p1, 1, 10)

func apply_gravity_p2() -> void:
	apply_gravity_improved(p2, 26, 35)

# === Sistema de spawn de piezas ===
func spawn_next_tetromino_p1() -> void:
	if p2.pending_attacks.size() > 0:
		freeze_player(p1, true)
		freeze_player(p2, false)
		execute_next_attack_p1()
		return
	
	var next_piece = get_next_piece_for_player(p1)
	
	p1.tetromino_type = p1.next_tetromino_type
	p1.next_tetromino_type = next_piece
	p1.rotation_index = 0
	p1.current_position = START_POSITION_P1
	if p1.tetromino_type != null and not p1.tetromino_type.is_empty():
		p1.active_tetromino = p1.tetromino_type[p1.rotation_index]
	
	update_hud_display()
	
	if not is_valid_move_p1(Vector2i.ZERO):
		p1.is_active = false
		check_game_over()
	else:
		render_tetromino_p1()
		print("DEBUG: P1 - Nueva pieza. Índice actual: ", p1.piece_index)

func spawn_next_tetromino_p2() -> void:
	if p1.pending_attacks.size() > 0:
		freeze_player(p2, true)
		freeze_player(p1, false)
		execute_next_attack_p2()
		return
	
	var next_piece = get_next_piece_for_player(p2)
	
	p2.tetromino_type = p2.next_tetromino_type
	p2.next_tetromino_type = next_piece
	p2.rotation_index = 0
	p2.current_position = START_POSITION_P2
	if p2.tetromino_type != null and not p2.tetromino_type.is_empty():
		p2.active_tetromino = p2.tetromino_type[p2.rotation_index]
	
	update_hud_display()
	
	if not is_valid_move_p2(Vector2i.ZERO):
		p2.is_active = false
		check_game_over()
	else:
		render_tetromino_p2()
		print("DEBUG: P2 - Nueva pieza. Índice actual: ", p2.piece_index)

func clear_board_p1() -> void:
	for y in range(1, 20):
		for x in range(1, 10):
			p1.board_layer.erase_cell(Vector2i(x, y))
			p1_active.erase_cell(Vector2i(x, y))
	p1.board_colors.clear()
	p1.initial_pieces_positions.clear()
	p1.piece_relationships.clear()
	p1.block_to_piece.clear()
	p1.next_piece_id = 0
	p1.piece_index = 0

func clear_board_p2() -> void:
	for y in range(1, 20):
		for x in range(26, 35):
			p2.board_layer.erase_cell(Vector2i(x, y))
			p2_active.erase_cell(Vector2i(x, y))
	p2.board_colors.clear()
	p2.initial_pieces_positions.clear()
	p2.piece_relationships.clear()
	p2.block_to_piece.clear()
	p2.next_piece_id = 0
	p2.piece_index = 0

# === Sistema de Game Over ===
func check_game_over() -> void:
	is_timer_running = false
	
	check_initial_pieces_win_condition()
	
	if not hud.get_node("GameOverLabel").visible:
		var p1_game_over = not p1.is_active or is_board_full(p1)
		var p2_game_over = not p2.is_active or is_board_full(p2)
		
		if p1_game_over and p2_game_over:
			show_game_over("EMPATE!")
		elif p1_game_over:
			show_game_over("JUGADOR 2 GANA!")
		elif p2_game_over:
			show_game_over("JUGADOR 1 GANA!")

func is_board_full(player: Player) -> bool:
	var spawn_positions = []
	if player == p1:
		spawn_positions = [START_POSITION_P1, START_POSITION_P1 + Vector2i(0,1), START_POSITION_P1 + Vector2i(1,0)]
	else:
		spawn_positions = [START_POSITION_P2, START_POSITION_P2 + Vector2i(0,1), START_POSITION_P2 + Vector2i(1,0)]
	
	for pos in spawn_positions:
		if player.board_layer.get_cell_source_id(pos) != -1:
			return true
	return false

func show_game_over(message: String) -> void:
	var p1_initial_cleared = get_initial_pieces_cleared(p1)
	var p2_initial_cleared = get_initial_pieces_cleared(p2)
	hud.get_node("GameOverLabel").text = message + "\nP1: " + str(p1.display_score) + " - P2: " + str(p2.display_score) + "\nPiezas iniciales: P1 " + str(p1_initial_cleared) + "/10 - P2 " + str(p2_initial_cleared) + "/10"
	hud.get_node("GameOverLabel").visible = true
	hud.get_node("StartNewGame").visible = true
	freeze_game(true)

# === Loop principal ===
func _physics_process(delta: float) -> void:
	if is_setup_phase:
		place_initial_pieces(delta)
		return
	
	update_initial_pieces_blink(delta)
	
	if is_timer_running and not game_paused:
		game_time += delta
		update_hud_display()
	
	if hud.get_node("StartNewGame").visible and Input.is_action_just_pressed("ui_accept"):
		restart_game()
		return
	
	if game_paused:
		return
	
	if is_p2_falling_attack:
		p2.fall_timer += delta
		if p2.fall_timer >= ATTACK_FALL_INTERVAL:
			if not move_attack_piece_down():
				pass
			p2.fall_timer = 0.0
	
	if is_p1_falling_attack:
		p1.fall_timer += delta
		if p1.fall_timer >= ATTACK_FALL_INTERVAL:
			if not move_attack_piece_p1_down():
				pass
			p1.fall_timer = 0.0
	
	if p1.is_active and not p1.is_frozen and not is_setup_phase:
		if Input.is_action_just_pressed("p1_attack_left"):
			if p1.charges > 0:
				add_attack_to_p2("left")
		
		if Input.is_action_just_pressed("p1_attack_right"):
			if p1.charges > 0:
				add_attack_to_p2("right")
		
		if Input.is_action_just_pressed("p1_left"):
			move_tetromino_p1(Vector2i.LEFT)
		
		if Input.is_action_just_pressed("p1_right"):
			move_tetromino_p1(Vector2i.RIGHT)
		
		if Input.is_action_just_pressed("p1_rotate"):
			rotate_tetromino_p1()
		
		p1.fall_timer += delta
		var interval_p1 = FALL_INTERVAL
		if Input.is_action_pressed("p1_down"):
			interval_p1 /= FAST_FALL_MULTIPLIER
		
		if p1.fall_timer >= interval_p1:
			if is_blocked_below_p1():
				clear_tetromino_p1()
				land_tetromino_p1()
			else:
				move_tetromino_p1(Vector2i.DOWN)
			p1.fall_timer = 0.0

	if p2.is_active and not p2.is_frozen and not is_setup_phase:
		if Input.is_action_just_pressed("p2_attack_left"):
			if p2.charges > 0:
				add_attack_to_p1("left")
		
		if Input.is_action_just_pressed("p2_attack_right"):
			if p2.charges > 0:
				add_attack_to_p1("right")
		
		if Input.is_action_just_pressed("p2_left"):
			move_tetromino_p2(Vector2i.LEFT)
		
		if Input.is_action_just_pressed("p2_right"):
			move_tetromino_p2(Vector2i.RIGHT)
		
		if Input.is_action_just_pressed("p2_rotate"):
			rotate_tetromino_p2()
		
		p2.fall_timer += delta
		var interval_p2 = FALL_INTERVAL
		if Input.is_action_pressed("p2_down"):
			interval_p2 /= FAST_FALL_MULTIPLIER
		
		if p2.fall_timer >= interval_p2:
			if is_blocked_below_p2():
				clear_tetromino_p2()
				land_tetromino_p2()
			else:
				move_tetromino_p2(Vector2i.DOWN)
			p2.fall_timer = 0.0

func restart_game() -> void:
	print("DEBUG: Reiniciando juego")
	setup_initial_pieces()
	setup_shared_sequence()
	select_random_preset()
	setup_preset_positions()
	current_initial_piece_index = 0
	is_setup_phase = true
	is_initial_piece_falling = false
	freeze_all_players(true)
	
	clear_board_p1()
	clear_board_p2()
	p1.board_colors = {}
	p1.initial_pieces_positions = []
	p1.piece_index = 0
	p2.board_colors = {}
	p2.initial_pieces_positions = []
	p2.piece_index = 0
	
	hud.get_node("GameOverLabel").visible = false
	hud.get_node("StartNewGame").visible = false
	freeze_game(false)
	game_time = 0.0
	is_timer_running = true
	initial_pieces_blink_timer = 0.0
	show_initial_pieces = true
	update_hud_display()

# === Sistema de Ataques P1 → P2 ===
func add_attack_to_p2(side: String) -> void:
	if p1.charges <= 0:
		return
	
	if p1.pending_attacks.size() < 10:
		p1.pending_attacks.append(side)
		p1.charges -= 1
		p1.spent_charges += 1
		update_hud_display()

func execute_next_attack_p2() -> void:
	if p1.pending_attacks.size() > 0:
		var attack_side = p1.pending_attacks.pop_front()
		start_attack_on_p2(attack_side)

func start_attack_on_p2(side: String) -> void:
	var attack_tetromino = get_next_piece_for_player(p1)
	if attack_tetromino == null or attack_tetromino.is_empty():
		return
	
	var attack_rotation = 0
	var attack_piece = attack_tetromino[attack_rotation]
	
	var start_x = 0
	if side == "left":
		start_x = randi_range(26, 30)
	else:
		start_x = randi_range(30, 33)
	
	current_attack_position = Vector2i(start_x, 1)
	current_attack_piece = attack_piece
	is_p2_falling_attack = true
	
	freeze_player(p2, true)
	freeze_player(p1, false)
	render_attack_piece()

func render_attack_piece() -> void:
	if current_attack_piece == null or current_attack_piece.size() < 4:
		return
	
	for i in range(2):
		var block_pos = current_attack_position + current_attack_piece[i]
		var color_index = current_attack_piece[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2_active.set_cell(block_pos, p2.tile_id, atlas_coords)

func clear_attack_piece() -> void:
	if current_attack_piece == null or current_attack_piece.size() < 2:
		return
	
	for i in range(2):
		var block_pos = current_attack_position + current_attack_piece[i]
		p2_active.erase_cell(block_pos)

func move_attack_piece_down() -> bool:
	if can_attack_piece_move(Vector2i.DOWN):
		clear_attack_piece()
		current_attack_position += Vector2i.DOWN
		render_attack_piece()
		return true
	else:
		land_attack_piece()
		return false

func can_attack_piece_move(direction: Vector2i) -> bool:
	if current_attack_piece == null or current_attack_piece.size() < 2:
		return false
	
	for i in range(2):
		var pos = current_attack_position + current_attack_piece[i] + direction
		if pos.y > 19:
			return false
		if p2.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

func land_attack_piece() -> void:
	if current_attack_piece == null or current_attack_piece.size() < 4:
		return
	
	# Registrar la pieza de ataque
	var positions = []
	for i in range(2):
		var block_pos = current_attack_position + current_attack_piece[i]
		var color_index = current_attack_piece[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2.board_layer.set_cell(block_pos, p2.tile_id, atlas_coords)
		p2.board_colors[block_pos] = color_index
		positions.append(block_pos)
	
	register_piece(p2, positions)
	
	check_and_clear_matches_p2()
	
	clear_attack_piece()
	current_attack_piece = []
	is_p2_falling_attack = false
	
	if p1.pending_attacks.size() > 0:
		execute_next_attack_p2()
	else:
		freeze_player(p2, false)

# === Sistema de Ataques P2 → P1 ===
func add_attack_to_p1(side: String) -> void:
	if p2.charges <= 0:
		return
	
	if p2.pending_attacks.size() < 10:
		p2.pending_attacks.append(side)
		p2.charges -= 1
		p2.spent_charges += 1
		update_hud_display()

func execute_next_attack_p1() -> void:
	if p2.pending_attacks.size() > 0:
		var attack_side = p2.pending_attacks.pop_front()
		start_attack_on_p1(attack_side)

func start_attack_on_p1(side: String) -> void:
	var attack_tetromino = get_next_piece_for_player(p2)
	if attack_tetromino == null or attack_tetromino.is_empty():
		return
	
	var attack_rotation = 0
	var attack_piece = attack_tetromino[attack_rotation]
	
	var start_x = 0
	if side == "left":
		start_x = randi_range(1, 4)
	else:
		start_x = randi_range(5, 8)
	
	current_attack_position_p1 = Vector2i(start_x, 1)
	current_attack_piece_p1 = attack_piece
	is_p1_falling_attack = true
	
	freeze_player(p1, true)
	freeze_player(p2, false)
	render_attack_piece_p1()

func render_attack_piece_p1() -> void:
	if current_attack_piece_p1 == null or current_attack_piece_p1.size() < 4:
		return
	
	for i in range(2):
		var block_pos = current_attack_position_p1 + current_attack_piece_p1[i]
		var color_index = current_attack_piece_p1[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1_active.set_cell(block_pos, p1.tile_id, atlas_coords)

func clear_attack_piece_p1() -> void:
	if current_attack_piece_p1 == null or current_attack_piece_p1.size() < 2:
		return
	
	for i in range(2):
		var block_pos = current_attack_position_p1 + current_attack_piece_p1[i]
		p1_active.erase_cell(block_pos)

func move_attack_piece_p1_down() -> bool:
	if can_attack_piece_p1_move(Vector2i.DOWN):
		clear_attack_piece_p1()
		current_attack_position_p1 += Vector2i.DOWN
		render_attack_piece_p1()
		return true
	else:
		land_attack_piece_p1()
		return false

func can_attack_piece_p1_move(direction: Vector2i) -> bool:
	if current_attack_piece_p1 == null or current_attack_piece_p1.size() < 2:
		return false
	
	for i in range(2):
		var pos = current_attack_position_p1 + current_attack_piece_p1[i] + direction
		if pos.y > 19:
			return false
		if p1.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

func land_attack_piece_p1() -> void:
	if current_attack_piece_p1 == null or current_attack_piece_p1.size() < 4:
		return
	
	# Registrar la pieza de ataque
	var positions = []
	for i in range(2):
		var block_pos = current_attack_position_p1 + current_attack_piece_p1[i]
		var color_index = current_attack_piece_p1[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1.board_layer.set_cell(block_pos, p1.tile_id, atlas_coords)
		p1.board_colors[block_pos] = color_index
		positions.append(block_pos)
	
	register_piece(p1, positions)
	
	check_and_clear_matches_p1()
	
	clear_attack_piece_p1()
	current_attack_piece_p1 = []
	is_p1_falling_attack = false
	
	if p2.pending_attacks.size() > 0:
		execute_next_attack_p1()
	else:
		freeze_player(p1, false)

# === Función auxiliar para encontrar piezas completas ===
func find_complete_pieces(_player: Player) -> Array:
	return []
