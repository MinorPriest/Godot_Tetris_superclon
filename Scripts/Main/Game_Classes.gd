# game_classes.gd
# Definiciones de clase globales para evitar dependencias circulares

class_name GameClasses

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
	var piece_index: int = 0
	var piece_relationships: Dictionary = {}
	var block_to_piece: Dictionary = {}
	var next_piece_id: int = 0
	
	# Constructor para facilitar la creación
	func _init(board, active, tile_id, start_pos):
		board_layer = board
		active_layer = active
		self.tile_id = tile_id
		current_position = start_pos
		board_colors = {}
		initial_pieces_positions = []
		piece_relationships = {}
		block_to_piece = {}
