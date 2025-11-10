extends Node

# Señales - DEFINIR TODAS LAS SEÑALES NECESARIAS
signal match_found(player, matched_positions, points)
signal piece_landed(player)
signal board_changed(player)
signal attack_piece_landed(player)
signal initial_pieces_updated(p1_cleared, p2_cleared)
signal setup_phase_finished()  # ← NUEVA SEÑAL

# Clase Player
class Player:
	var board_layer: TileMapLayer
	var active_layer: TileMapLayer
	var current_position: Vector2i
	var fall_timer: float = 0.0
	var tetromino_type: Array
	var next_tetromino_type: Array
	var rotation_index: int = 0
	var active_tetromino: Array = []
	var player_tile_id: int = 0  # Cambiado de tile_id para evitar shadowing
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
	var piece_index: int = 0
	var piece_relationships: Dictionary = {}
	var block_to_piece: Dictionary = {}
	var next_piece_id: int = 0
	
	func _init(board, active, tile_id, start_pos):
		board_layer = board
		active_layer = active
		player_tile_id = tile_id  # Usar nombre diferente
		current_position = start_pos
		board_colors = {}
		initial_pieces_positions = []
		piece_relationships = {}
		block_to_piece = {}

# Referencias
var main
var p1_board: TileMapLayer
var p1_active: TileMapLayer  
var p2_board: TileMapLayer
var p2_active: TileMapLayer

# Jugadores
var p1: Player
var p2: Player

# === Tetrominos con colores ===
var red_red_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 0, 0],
	[Vector2i(0,1), Vector2i(0,2), 0, 0],
	[Vector2i(0,1), Vector2i(-1,1), 0, 0],
	[Vector2i(0,1), Vector2i(0,0), 0, 0]
]

var yellow_yellow_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 1, 1],
	[Vector2i(0,1), Vector2i(0,2), 1, 1],
	[Vector2i(0,1), Vector2i(-1,1), 1, 1],
	[Vector2i(0,1), Vector2i(0,0), 1, 1]
]

var blue_blue_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 2, 2],
	[Vector2i(0,1), Vector2i(0,2), 2, 2],
	[Vector2i(0,1), Vector2i(-1,1), 2, 2],
	[Vector2i(0,1), Vector2i(0,0), 2, 2]
]

var red_yellow_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 0, 1],
	[Vector2i(0,1), Vector2i(0,2), 0, 1],
	[Vector2i(0,1), Vector2i(-1,1), 0, 1],
	[Vector2i(0,1), Vector2i(0,0), 0, 1]
]

var red_blue_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 0, 2],
	[Vector2i(0,1), Vector2i(0,2), 0, 2],
	[Vector2i(0,1), Vector2i(-1,1), 0, 2],
	[Vector2i(0,1), Vector2i(0,0), 0, 2]
]

var yellow_blue_piece: Array = [
	[Vector2i(0,1), Vector2i(1,1), 1, 2],
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

# === Sistema de presets para piezas iniciales ===
enum PresetType {
	CENTER,
	SPREAD,
	TOWERS,
	PYRAMID,
	RANDOM_SPREAD
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
const INITIAL_PIECES_BLINK_INTERVAL: float = .5
var show_initial_pieces: bool = true

# === Optimización: Cache de piezas completas ===
var complete_pieces_cache_p1: Dictionary = {}
var complete_pieces_cache_p2: Dictionary = {}
var cache_dirty_p1: bool = true
var cache_dirty_p2: bool = true

# === Sistema de grupos de piezas ===
var piece_groups_p1: Array = []
var piece_groups_p2: Array = []

# === Control del juego ===
var is_p2_falling_attack: bool = false
var current_attack_piece: Array = []
var current_attack_position: Vector2i
var is_p1_falling_attack: bool = false
var current_attack_piece_p1: Array = []
var current_attack_position_p1: Vector2i

func initialize(main_node, p1_b, p1_a, p2_b, p2_a) -> void:
	main = main_node
	p1_board = p1_b
	p1_active = p1_a
	p2_board = p2_b
	p2_active = p2_a
	
	# Inicializar jugadores
	p1 = Player.new(p1_board, p1_active, 1, START_POSITION_P1)
	p2 = Player.new(p2_board, p2_active, 0, START_POSITION_P2)
	
	print("PieceLogic inicializado - P1 y P2 creados")

func update(delta: float) -> void:
	# SOLO NO ACTUALIZAR SI ESTAMOS EN FASE DE SETUP Y EL JUEGO ESTÁ PAUSADO
	# Pero permitir actualización durante el juego normal
	if main and main.game_paused and not is_setup_phase:
		print("⏸️  PieceLogic: Juego pausado - saltando actualización")
		return
	
	if is_setup_phase:
		place_initial_pieces(delta)
		return
	
	update_initial_pieces_blink(delta)
	
	# Solo pausar la lógica del juego si realmente está pausado
	# pero permitir que las piezas iniciales sigan parpadeando
	if main and main.game_paused:
		return
	
	# Procesar ataques
	process_attacks(delta)
	
	# Procesar jugadores
	process_player(p1, delta, "p1")
	process_player(p2, delta, "p2")

func process_player(player: Player, delta: float, player_prefix: String) -> void:
	# VERIFICACIÓN COMPLETA: No procesar si el jugador está inactivo, congelado, en setup phase O el juego está pausado
	if not player.is_active or player.is_frozen or is_setup_phase or (main and main.game_paused):
		return
	
	# Manejar inputs
	handle_player_input(player, player_prefix)
	
	# Gravedad
	player.fall_timer += delta
	var interval = FALL_INTERVAL
	if Input.is_action_pressed(player_prefix + "_down"):
		interval /= FAST_FALL_MULTIPLIER
	
	if player.fall_timer >= interval:
		if is_blocked_below(player):
			clear_tetromino(player)
			land_tetromino(player)
		else:
			move_tetromino(player, Vector2i.DOWN)
		player.fall_timer = 0.0
func handle_player_input(player: Player, player_prefix: String) -> void:
	if Input.is_action_just_pressed(player_prefix + "_left"):
		move_tetromino(player, Vector2i.LEFT)
	
	if Input.is_action_just_pressed(player_prefix + "_right"):
		move_tetromino(player, Vector2i.RIGHT)
	
	if Input.is_action_just_pressed(player_prefix + "_rotate"):
		rotate_tetromino(player)

# === SISTEMA DE REGISTRO DE PIEZAS ===
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
func apply_gravity_improved(player: Player, _min_x: int, _max_x: int) -> void:  # Parámetros con _ para evitar warnings
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
		
		player.board_layer.set_cell(new_pos, player.player_tile_id, atlas_coords)
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
				p1_active.set_cell(new_pos, p1.player_tile_id, Vector2i(6, 0))
			else:
				p2_active.set_cell(new_pos, p2.player_tile_id, Vector2i(6, 0))
	
	board_changed.emit(player)

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
		red_red_piece, yellow_blue_piece, blue_blue_piece, red_yellow_piece
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
		p1_active.set_cell(block_pos, p1.player_tile_id, atlas_coords)
	
	for i in range(2):
		var block_pos = p2.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2_active.set_cell(block_pos, p2.player_tile_id, atlas_coords)

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
	
	# EMITIR SEÑAL DE QUE EL SETUP TERMINÓ
	if has_signal("setup_phase_finished"):
		emit_signal("setup_phase_finished")
	else:
		print("⚠️ Señal setup_phase_finished no existe en PieceLogic")
	
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
		p1.board_layer.set_cell(block_pos, p1.player_tile_id, atlas_coords)
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
		p2.board_layer.set_cell(block_pos, p2.player_tile_id, atlas_coords)
		p2.board_colors[block_pos] = color_index
		p2_positions.append(block_pos)
	p2.initial_pieces_positions.append_array(p2_positions)
	register_piece(p2, p2_positions)
	
	clear_initial_piece_both()
	
	check_and_clear_matches_p1()
	check_and_clear_matches_p2()
	
	board_changed.emit(p1)
	board_changed.emit(p2)
	
	# Emitir señal de actualización de piezas iniciales
	var p1_cleared = get_initial_pieces_cleared(p1)
	var p2_cleared = get_initial_pieces_cleared(p2)
	initial_pieces_updated.emit(p1_cleared, p2_cleared)

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
			p1.board_layer.set_cell(pos, p1.player_tile_id, Vector2i(color, 0))
			
			if show_initial_pieces:
				p1_active.set_cell(pos, p1.player_tile_id, Vector2i(6, 0))
			else:
				p1_active.erase_cell(pos)
	
	for pos in p2.initial_pieces_positions:
		if p2.board_colors.has(pos):
			var color = p2.board_colors[pos]
			p2.board_layer.set_cell(pos, p2.player_tile_id, Vector2i(color, 0))
			
			if show_initial_pieces:
				p2_active.set_cell(pos, p2.player_tile_id, Vector2i(6, 0))
			else:
				p2_active.erase_cell(pos)

# === Sistema de Congelamiento ===
func _on_freeze_player(player: Player, freeze: bool) -> void:
	player.is_frozen = freeze

func _on_freeze_all_players(freeze: bool) -> void:
	p1.is_frozen = freeze
	p2.is_frozen = freeze
	if freeze:
		print("🧊 PieceLogic: Juego congelado completamente")
	else:
		print("▶️ PieceLogic: Juego reanudado")
	
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
	
	clear_tetromino(p1)
	
	p1.tetromino_type = get_next_piece_for_player(p1)
	p1.next_tetromino_type = get_next_piece_for_player(p1)
	p1.rotation_index = 0
	p1.current_position = START_POSITION_P1
	if p1.tetromino_type != null and not p1.tetromino_type.is_empty():
		p1.active_tetromino = p1.tetromino_type[p1.rotation_index]
	render_tetromino(p1)
	
	print("DEBUG: P1 - Pieza normal inicializada. Índice actual: ", p1.piece_index)

func render_tetromino(player: Player) -> void:
	if player.tetromino_type == null or player.tetromino_type.is_empty():
		print("DEBUG: ERROR - No hay tetromino_type para jugador")
		return
	
	var rotation_data = player.tetromino_type[player.rotation_index]
	if rotation_data == null or rotation_data.size() < 4:
		print("DEBUG: ERROR - Datos de rotación inválidos para jugador")
		return
	
	var active_layer = p1_active if player == p1 else p2_active
	var tile_id = player.player_tile_id
	
	for i in range(2):
		var block_pos = player.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		active_layer.set_cell(block_pos, tile_id, atlas_coords)
	
	print("DEBUG: Tetromino renderizado en posición: ", player.current_position)

func clear_tetromino(player: Player) -> void:
	if player.tetromino_type == null or player.tetromino_type.is_empty():
		return
	
	var rotation_data = player.tetromino_type[player.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return
	
	var active_layer = p1_active if player == p1 else p2_active
	
	for i in range(2):
		var block_pos = player.current_position + rotation_data[i]
		active_layer.erase_cell(block_pos)

func move_tetromino(player: Player, direction: Vector2i) -> void:
	if player.is_frozen or (main and main.game_paused):
		print("DEBUG: Jugador congelado o juego pausado")
		return
	if is_valid_move(player, direction):
		clear_tetromino(player)
		player.current_position += direction
		render_tetromino(player)
		print("DEBUG: Jugador movido: ", direction)

func rotate_tetromino(player: Player) -> void:
	if player.is_frozen or (main and main.game_paused):
		return
	if is_valid_rotation(player):
		clear_tetromino(player)
		player.rotation_index = (player.rotation_index + 1) % 4
		if player.tetromino_type != null and not player.tetromino_type.is_empty():
			player.active_tetromino = player.tetromino_type[player.rotation_index]
		render_tetromino(player)
		print("DEBUG: Jugador rotado")

func is_valid_move(player: Player, direction: Vector2i) -> bool:
	if player.tetromino_type == null or player.tetromino_type.is_empty():
		return false
	
	var rotation_data = player.tetromino_type[player.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return false
	
	var min_x = 1 if player == p1 else 26
	var max_x = 9 if player == p1 else 34
	
	for i in range(2):
		var pos = player.current_position + rotation_data[i] + direction
		if pos.x < min_x or pos.x > max_x or pos.y > 19:
			return false
		if player.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

func is_valid_rotation(player: Player) -> bool:
	if player.tetromino_type == null or player.tetromino_type.is_empty():
		return false
	
	var next_rotation = (player.rotation_index + 1) % 4
	var rotated = player.tetromino_type[next_rotation]
	if rotated == null or rotated.size() < 2:
		return false
	
	var min_x = 1 if player == p1 else 26
	var max_x = 9 if player == p1 else 34
	
	for i in range(2):
		var pos = player.current_position + rotated[i]
		if pos.x < min_x or pos.x > max_x or pos.y > 19:
			return false
		if player.board_layer.get_cell_source_id(pos) != -1:
			return false
	return true

# === FUNCIÓN CRÍTICA CORREGIDA: land_tetromino ===
func land_tetromino(player: Player) -> void:
	if player.tetromino_type == null or player.tetromino_type.is_empty():
		return
	
	var rotation_data = player.tetromino_type[player.rotation_index]
	if rotation_data == null or rotation_data.size() < 4:
		return
	
	# Registrar la nueva pieza
	var positions = []
	for i in range(2):
		var block_pos = player.current_position + rotation_data[i]
		var color_index = rotation_data[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		player.board_layer.set_cell(block_pos, player.player_tile_id, atlas_coords)
		player.board_colors[block_pos] = color_index
		positions.append(block_pos)
	
	register_piece(player, positions)
	
	# PARTE CRÍTICA: Verificar matches y luego spawnear siguiente pieza
	if player == p1:
		check_and_clear_matches_p1()
		spawn_next_tetromino_p1()  # ← AQUÍ SE VERIFICAN ATAQUES
	else:
		check_and_clear_matches_p2()
		spawn_next_tetromino_p2()  # ← AQUÍ SE VERIFICAN ATAQUES
	
	piece_landed.emit(player)
	board_changed.emit(player)

func is_blocked_below(player: Player) -> bool:
	if player.tetromino_type == null or player.tetromino_type.is_empty():
		return true
	
	var rotation_data = player.tetromino_type[player.rotation_index]
	if rotation_data == null or rotation_data.size() < 2:
		return true
	
	for i in range(2):
		var pos = player.current_position + rotation_data[i] + Vector2i.DOWN
		if pos.y > 19:
			return true
		if player.board_layer.get_cell_source_id(pos) != -1:
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
	
	clear_tetromino(p2)
	
	p2.tetromino_type = get_next_piece_for_player(p2)
	p2.next_tetromino_type = get_next_piece_for_player(p2)
	p2.rotation_index = 0
	p2.current_position = START_POSITION_P2
	if p2.tetromino_type != null and not p2.tetromino_type.is_empty():
		p2.active_tetromino = p2.tetromino_type[p2.rotation_index]
	render_tetromino(p2)
	
	print("DEBUG: P2 - Pieza normal inicializada. Índice actual: ", p2.piece_index)

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
		
		print("🎯🎯🎯 MATCH ENCONTRADO - Jugador: ", "P1" if player == p1 else "P2")
		print("Posiciones: ", matched_positions.size())
		print("Puntos: ", points)
		print("EMITIENDO SEÑAL match_found...")
		
		var initial_pieces_cleared = count_initial_pieces_cleared(player, matched_positions)
		if initial_pieces_cleared > 0:
			print("DEBUG: Se limpiaron ", initial_pieces_cleared, " bloques iniciales en el match")
		
		start_match_animation(player, matched_positions)
		match_found.emit(player, matched_positions, points)
		
		# DEBUG: Verificar si la señal se emitió correctamente
		print("✅ Señal match_found emitida para ", points, " puntos")
	else:
		print("❌ No hay posiciones para procesar en match")
func count_initial_pieces_cleared(player: Player, matched_positions: Array) -> int:
	var count = 0
	for pos in matched_positions:
		if player.initial_pieces_positions.has(pos):
			count += 1
	return count

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
				p1.board_layer.set_cell(block_pos, p1.player_tile_id, Vector2i(3, 0))
			else:
				var color = p1.board_colors[block_pos]
				p1.board_layer.set_cell(block_pos, p1.player_tile_id, Vector2i(color, 0))
		
		elif block_pos.x >= 26 and block_pos.x <= 34:
			if alpha == 0.0:
				p2.board_layer.set_cell(block_pos, p2.player_tile_id, Vector2i(3, 0))
			else:
				var color = p2.board_colors[block_pos]
				p2.board_layer.set_cell(block_pos, p2.player_tile_id, Vector2i(color, 0))

func clear_matches_after_animation(player: Player, matched_positions: Array) -> void:
	clear_matches_directly(player, matched_positions)
	blinking_blocks.clear()

# En PieceLogic.gd, modifica clear_matches_directly():
func clear_matches_directly(player: Player, matched_positions: Array) -> void:
	# Desregistrar las posiciones antes de limpiar
	unregister_piece_positions(player, matched_positions)
	
	# VERIFICAR SI SE LIMPIARON PIEZAS INICIALES
	var cleared_initial_pieces = false
	for pos in matched_positions:
		if player.initial_pieces_positions.has(pos):
			cleared_initial_pieces = true
			break
	
	for pos in matched_positions:
		player.board_layer.erase_cell(pos)
		player.board_colors.erase(pos)
		if player == p1:
			p1_active.erase_cell(pos)
		else:
			p2_active.erase_cell(pos)
		if player.initial_pieces_positions.has(pos):
			player.initial_pieces_positions.erase(pos)
	
	# CORREGIDO: Cambiar on_board_changed(player) por:
	board_changed.emit(player)
	
	# VERIFICACIÓN INMEDIATA DE VICTORIA si se limpiaron piezas iniciales
	if cleared_initial_pieces:
		print("🔍 Se limpiaron piezas iniciales - verificando victoria inmediata")
		# Emitir señal para verificar victoria
		var p1_cleared = get_initial_pieces_cleared(p1)
		var p2_cleared = get_initial_pieces_cleared(p2)
		initial_pieces_updated.emit(p1_cleared, p2_cleared)
	
	if player == p1:
		apply_gravity_improved(p1, 1, 10)
	else:
		apply_gravity_improved(p2, 26, 35)

# === Sistema de gravedad ===
func apply_gravity_p1() -> void:
	apply_gravity_improved(p1, 1, 10)

func apply_gravity_p2() -> void:
	apply_gravity_improved(p2, 26, 35)

# === FUNCIONES CRÍTICAS CORREGIDAS: Spawn de piezas con verificación de ataques ===
func spawn_next_tetromino_p1() -> void:
	print("DEBUG: spawn_next_tetromino_p1 - Verificando ataques de P2: ", p2.pending_attacks.size())
	
	# VERIFICACIÓN CRÍTICA: Si P2 tiene ataques pendientes contra P1
	if p2.pending_attacks.size() > 0:
		print("DEBUG: P1 congelado - ejecutando ataque pendiente de P2")
		_on_freeze_player(p1, true)   # Congelar a P1 (el objetivo)
		_on_freeze_player(p2, false)  # Descongelar a P2 (el atacante)
		execute_next_attack_p1()      # Ejecutar el ataque
		return  # IMPORTANTE: No spawnear nueva pieza aún
	
	# Si no hay ataques, spawnear pieza normal
	var next_piece = get_next_piece_for_player(p1)
	
	p1.tetromino_type = p1.next_tetromino_type
	p1.next_tetromino_type = next_piece
	p1.rotation_index = 0
	p1.current_position = START_POSITION_P1
	if p1.tetromino_type != null and not p1.tetromino_type.is_empty():
		p1.active_tetromino = p1.tetromino_type[p1.rotation_index]
	
	if not is_valid_move(p1, Vector2i.ZERO):
		p1.is_active = false
		print("DEBUG: P1 - GAME OVER - No hay espacio para nueva pieza")
	else:
		render_tetromino(p1)
		print("DEBUG: P1 - Nueva pieza spawneda. Índice: ", p1.piece_index)

func spawn_next_tetromino_p2() -> void:
	print("DEBUG: spawn_next_tetromino_p2 - Verificando ataques de P1: ", p1.pending_attacks.size())
	
	# VERIFICACIÓN CRÍTICA: Si P1 tiene ataques pendientes contra P2
	if p1.pending_attacks.size() > 0:
		print("DEBUG: P2 congelado - ejecutando ataque pendiente de P1")
		_on_freeze_player(p2, true)   # Congelar a P2 (el objetivo)
		_on_freeze_player(p1, false)  # Descongelar a P1 (el atacante)
		execute_next_attack_p2()      # Ejecutar el ataque
		return  # IMPORTANTE: No spawnear nueva pieza aún
	
	# Si no hay ataques, spawnear pieza normal
	var next_piece = get_next_piece_for_player(p2)
	
	p2.tetromino_type = p2.next_tetromino_type
	p2.next_tetromino_type = next_piece
	p2.rotation_index = 0
	p2.current_position = START_POSITION_P2
	if p2.tetromino_type != null and not p2.tetromino_type.is_empty():
		p2.active_tetromino = p2.tetromino_type[p2.rotation_index]
	
	if not is_valid_move(p2, Vector2i.ZERO):
		p2.is_active = false
		print("DEBUG: P2 - GAME OVER - No hay espacio para nueva pieza")
	else:
		render_tetromino(p2)
		print("DEBUG: P2 - Nueva pieza spawneda. Índice: ", p2.piece_index)

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

func restart_game() -> void:
	print("DEBUG: Reiniciando juego")
	setup_initial_pieces()
	setup_shared_sequence()
	select_random_preset()
	setup_preset_positions()
	current_initial_piece_index = 0
	is_setup_phase = true
	is_initial_piece_falling = false
	
	clear_board_p1()
	clear_board_p2()
	p1.board_colors = {}
	p1.initial_pieces_positions = []
	p1.piece_index = 0
	p2.board_colors = {}
	p2.initial_pieces_positions = []
	p2.piece_index = 0

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

# === Sistema de Ataques ===
# En PieceLogic.gd, verifica que esta función exista:
func _on_add_attack(from_player: Player, to_player: Player, side: String) -> void:
	print("🎯 _on_add_attack RECIBIDO en PieceLogic")
	print("De: ", "P1" if from_player == p1 else "P2")
	print("A: ", "P1" if to_player == p1 else "P2") 
	print("Lado: ", side)
	
	if from_player.charges <= 0:
		print("❌ Ataque rechazado - sin cargas")
		return
	
	if from_player.pending_attacks.size() < 10:
		from_player.charges -= 1  # Gastar una carga
		from_player.spent_charges += 1
		from_player.pending_attacks.append(side)
		
		print("✅ Ataque AGREGADO A COLA")
		print("Cargas restantes: ", from_player.charges)
		print("Ataques pendientes: ", from_player.pending_attacks)
		
		# EMITIR SEÑAL PARA ACTUALIZAR HUD - ESTO ES LO QUE FALTA
		if main and main.referee and main.referee.has_signal("charges_updated"):
			main.referee.charges_updated.emit(from_player, from_player.charges, MAX_CHARGES)
			print("✅ Señal charges_updated emitida para HUD")
		else:
			print("❌ No se pudo emitir charges_updated")
	else:
		print("❌ Cola de ataques llena")

func process_attacks(delta: float) -> void:
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

func execute_next_attack_p1() -> void:
	if p2.pending_attacks.size() > 0:
		var attack_side = p2.pending_attacks.pop_front()
		print("DEBUG: execute_next_attack_p1 - Ejecutando ataque de P2: ", attack_side)
		start_attack_on_p1(attack_side)
	else:
		print("DEBUG: execute_next_attack_p1 - No hay más ataques pendientes de P2")
		# Si no hay más ataques, reanudar juego normal
		_on_freeze_player(p1, false)
		# Spawnear nueva pieza para P1
		spawn_next_tetromino_p1()

func execute_next_attack_p2() -> void:
	if p1.pending_attacks.size() > 0:
		var attack_side = p1.pending_attacks.pop_front()
		print("DEBUG: execute_next_attack_p2 - Ejecutando ataque de P1: ", attack_side)
		start_attack_on_p2(attack_side)
	else:
		print("DEBUG: execute_next_attack_p2 - No hay más ataques pendientes de P1")
		# Si no hay más ataques, reanudar juego normal
		_on_freeze_player(p2, false)
		# Spawnear nueva pieza para P2
		spawn_next_tetromino_p2()

# === Sistema de Ataques P1 → P2 ===
func start_attack_on_p2(side: String) -> void:
	print("DEBUG: start_attack_on_p2 - Iniciando ataque desde P1 a P2, lado: ", side)
	
	var attack_tetromino = get_next_piece_for_player(p1)
	if attack_tetromino == null or attack_tetromino.is_empty():
		print("DEBUG: ERROR - No se pudo obtener tetromino de ataque")
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
	
	print("DEBUG: Ataque P1→P2 en posición: ", current_attack_position, " lado: ", side)
	
	_on_freeze_player(p2, true)
	_on_freeze_player(p1, false)
	render_attack_piece()

func render_attack_piece() -> void:
	if current_attack_piece == null or current_attack_piece.size() < 4:
		return
	
	for i in range(2):
		var block_pos = current_attack_position + current_attack_piece[i]
		var color_index = current_attack_piece[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2_active.set_cell(block_pos, p2.player_tile_id, atlas_coords)

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
	
	print("DEBUG: land_attack_piece - Aterrizando pieza de ataque en P2")
	
	# Registrar la pieza de ataque
	var positions = []
	for i in range(2):
		var block_pos = current_attack_position + current_attack_piece[i]
		var color_index = current_attack_piece[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p2.board_layer.set_cell(block_pos, p2.player_tile_id, atlas_coords)
		p2.board_colors[block_pos] = color_index
		positions.append(block_pos)
	
	register_piece(p2, positions)
	
	check_and_clear_matches_p2()
	
	clear_attack_piece()
	current_attack_piece = []
	is_p2_falling_attack = false
	
	attack_piece_landed.emit(p2)
	
	# VERIFICAR SI HAY MÁS ATAQUES PENDIENTES
	if p1.pending_attacks.size() > 0:
		print("DEBUG: Hay más ataques pendientes de P1: ", p1.pending_attacks.size())
		execute_next_attack_p2()
	else:
		print("DEBUG: No hay más ataques pendientes de P1 - Reanudando juego normal")
		_on_freeze_player(p2, false)
		# Spawnear nueva pieza para P2
		spawn_next_tetromino_p2()

# === Sistema de Ataques P2 → P1 ===
func start_attack_on_p1(side: String) -> void:
	print("DEBUG: start_attack_on_p1 - Iniciando ataque desde P2 a P1, lado: ", side)
	
	var attack_tetromino = get_next_piece_for_player(p2)
	if attack_tetromino == null or attack_tetromino.is_empty():
		print("DEBUG: ERROR - No se pudo obtener tetromino de ataque")
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
	
	print("DEBUG: Ataque P2→P1 en posición: ", current_attack_position_p1, " lado: ", side)
	
	_on_freeze_player(p1, true)
	_on_freeze_player(p2, false)
	render_attack_piece_p1()

func render_attack_piece_p1() -> void:
	if current_attack_piece_p1 == null or current_attack_piece_p1.size() < 4:
		return
	
	for i in range(2):
		var block_pos = current_attack_position_p1 + current_attack_piece_p1[i]
		var color_index = current_attack_piece_p1[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1_active.set_cell(block_pos, p1.player_tile_id, atlas_coords)

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
	
	print("DEBUG: land_attack_piece_p1 - Aterrizando pieza de ataque en P1")
	
	# Registrar la pieza de ataque
	var positions = []
	for i in range(2):
		var block_pos = current_attack_position_p1 + current_attack_piece_p1[i]
		var color_index = current_attack_piece_p1[i + 2]
		var atlas_coords = Vector2i(color_index, 0)
		p1.board_layer.set_cell(block_pos, p1.player_tile_id, atlas_coords)
		p1.board_colors[block_pos] = color_index
		positions.append(block_pos)
	
	register_piece(p1, positions)
	
	check_and_clear_matches_p1()
	
	clear_attack_piece_p1()
	current_attack_piece_p1 = []
	is_p1_falling_attack = false
	
	attack_piece_landed.emit(p1)
	
	# VERIFICAR SI HAY MÁS ATAQUES PENDIENTES
	if p2.pending_attacks.size() > 0:
		print("DEBUG: Hay más ataques pendientes de P2: ", p2.pending_attacks.size())
		execute_next_attack_p1()
	else:
		print("DEBUG: No hay más ataques pendientes de P2 - Reanudando juego normal")
		_on_freeze_player(p1, false)
		# Spawnear nueva pieza para P1
		spawn_next_tetromino_p1()

# === Funciones de acceso ===
func get_p1() -> Player:
	return p1

func get_p2() -> Player:
	return p2

# === Función auxiliar para encontrar piezas completas ===
func find_complete_pieces(_player: Player) -> Array:
	return []
