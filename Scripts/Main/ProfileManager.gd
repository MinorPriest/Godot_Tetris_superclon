# ProfileManager.gd (Singleton/Autoload) - VERSIÓN CORREGIDA
extends Node

class Profile:
	var profile_name: String
	var wins: int = 0
	var losses: int = 0
	var max_score: int = 0
	var vs_wins: Dictionary = {}  # Solo contendrá los otros 6 perfiles
	
	func _init(name: String):
		profile_name = name
		# CORREGIDO: Solo inicializar vs_wins para los otros 6 perfiles
		vs_wins = {}
		for i in range(7):
			var other_profile = "Perfil " + str(i + 1)
			if other_profile != name:
				vs_wins[other_profile] = 0

var profiles: Array = []
var selected_profiles: Dictionary = {}  # {1: profile_index, 2: profile_index}
var current_players: Dictionary = {}    # {1: profile, 2: profile}

# Variables para acceso fácil desde otras escenas
var current_profile_p1: String = ""
var current_profile_p2: String = ""
var current_profile_p1_index: int = -1
var current_profile_p2_index: int = -1

# Variables para guardar última selección
var last_used_profile_p1: int = -1
var last_used_profile_p2: int = -1

func _ready():
	# Inicializar los 7 perfiles
	for i in range(7):
		profiles.append(Profile.new("Perfil " + str(i + 1)))
	load_profiles()
	load_last_selection()
	print("✅ ProfileManager inicializado con ", profiles.size(), " perfiles")

func get_profile(index: int) -> Profile:
	if index >= 0 and index < profiles.size():
		return profiles[index]
	return null

func select_profile(player: int, profile_index: int) -> bool:
	# Verificar que no sea el mismo perfil
	if selected_profiles.values().has(profile_index):
		return false
	
	selected_profiles[player] = profile_index
	current_players[player] = profiles[profile_index]
	
	# Actualizar variables de acceso rápido
	if player == 1:
		current_profile_p1 = profiles[profile_index].profile_name
		current_profile_p1_index = profile_index
		last_used_profile_p1 = profile_index
	elif player == 2:
		current_profile_p2 = profiles[profile_index].profile_name
		current_profile_p2_index = profile_index
		last_used_profile_p2 = profile_index
	
	print("✅ Perfil seleccionado - P", player, ": ", profiles[profile_index].profile_name)
	
	# Guardar automáticamente cuando se selecciona
	save_profiles()
	save_last_selection()
	
	return true

func clear_selections():
	selected_profiles.clear()
	current_players.clear()
	current_profile_p1 = ""
	current_profile_p2 = ""
	current_profile_p1_index = -1
	current_profile_p2_index = -1
	print("🔃 Selecciones de perfil limpiadas")

# Cargar automáticamente los últimos perfiles usados
func auto_load_last_profiles():
	if last_used_profile_p1 != -1:
		select_profile(1, last_used_profile_p1)
		print("🔄 P1: Cargado último perfil usado - ", profiles[last_used_profile_p1].profile_name)
	
	if last_used_profile_p2 != -1:
		select_profile(2, last_used_profile_p2)
		print("🔄 P2: Cargado último perfil usado - ", profiles[last_used_profile_p2].profile_name)

func are_both_players_selected() -> bool:
	return selected_profiles.size() == 2

func get_selected_profile_name(player: int) -> String:
	if current_players.has(player):
		return current_players[player].profile_name
	return ""

# Función para registrar resultados
func register_game_result(winner_player: int, loser_player: int, winner_score: int = 0):
	if current_players.has(winner_player) and current_players.has(loser_player):
		var winner_profile = current_players[winner_player]
		var loser_profile = current_players[loser_player]
		
		# Actualizar wins/losses
		winner_profile.wins += 1
		loser_profile.losses += 1
		
		# Actualizar máximo puntaje
		if winner_score > winner_profile.max_score:
			winner_profile.max_score = winner_score
			print("🏆 Nuevo récord para ", winner_profile.profile_name, ": ", winner_score)
		
		# CORREGIDO: Actualizar VS wins dinámicamente
		var loser_profile_name = loser_profile.profile_name
		
		# Si el nombre del perfil perdedor no existe en vs_wins, actualizar todas las referencias
		if not winner_profile.vs_wins.has(loser_profile_name):
			# Buscar y actualizar todas las referencias a nombres antiguos
			update_all_vs_wins_references(loser_profile_name)
		
		# Incrementar el contador
		winner_profile.vs_wins[loser_profile_name] += 1
		
		print("✅ Resultado registrado: ", winner_profile.profile_name, " vs ", loser_profile_name)
		print("   ", winner_profile.profile_name, " - Victorias: ", winner_profile.wins, " | Récord: ", winner_profile.max_score)
		print("   ", loser_profile_name, " - Derrotas: ", loser_profile.losses)
		print("   VS Record actualizado: ", winner_profile.vs_wins[loser_profile_name])
		
		save_profiles()
	else:
		print("❌ Error: No se encontraron perfiles para registrar resultado")
		print("   Current players: ", current_players)
		print("   Winner: ", winner_player, " | Loser: ", loser_player)

# NUEVA FUNCIÓN: Actualizar todas las referencias VS cuando se renombra un perfil
func update_all_vs_wins_references(new_profile_name: String):
	print("🔄 Actualizando referencias VS para: ", new_profile_name)
	
	for profile in profiles:
		# Si este perfil tiene el nuevo nombre, actualizar todas sus referencias VS
		if profile.profile_name == new_profile_name:
			# Reemplazar todas las referencias antiguas por el nuevo nombre
			for other_profile in profiles:
				if other_profile.profile_name != new_profile_name:
					# Si el otro perfil tiene una referencia al nombre antiguo, moverla al nuevo
					var old_names_to_remove = []
					for vs_name in other_profile.vs_wins:
						if vs_name != new_profile_name and vs_name.begins_with("Perfil "):
							# Esta es una referencia antigua, transferir el valor
							if not other_profile.vs_wins.has(new_profile_name):
								other_profile.vs_wins[new_profile_name] = 0
							other_profile.vs_wins[new_profile_name] += other_profile.vs_wins[vs_name]
							old_names_to_remove.append(vs_name)
					
					# Eliminar las referencias antiguas
					for old_name in old_names_to_remove:
						other_profile.vs_wins.erase(old_name)

func save_profiles():
	var save_data = []
	for profile in profiles:
		var profile_data = {
			"name": profile.profile_name,
			"wins": profile.wins,
			"losses": profile.losses,
			"max_score": profile.max_score,
			"vs_wins": profile.vs_wins
		}
		save_data.append(profile_data)
	
	var file = FileAccess.open("user://profiles.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("💾 Perfiles guardados correctamente")
	else:
		print("❌ Error al guardar perfiles: ", FileAccess.get_open_error())

func load_profiles():
	if FileAccess.file_exists("user://profiles.save"):
		var file = FileAccess.open("user://profiles.save", FileAccess.READ)
		if file:
			var save_data = file.get_var()
			file.close()
			
			if save_data != null and save_data is Array:
				for i in range(min(profiles.size(), save_data.size())):
					var data = save_data[i]
					if data is Dictionary:
						profiles[i].profile_name = data.get("name", "Perfil " + str(i + 1))
						profiles[i].wins = data.get("wins", 0)
						profiles[i].losses = data.get("losses", 0)
						profiles[i].max_score = data.get("max_score", 0)
						profiles[i].vs_wins = data.get("vs_wins", {})
						
						# CORREGIDO: Solo asegurar referencias a los 7 perfiles
						ensure_basic_vs_wins(profiles[i])
				
				print("📂 Perfiles cargados desde disco - ", profiles.size(), " perfiles")
			else:
				print("❌ Datos de archivo corruptos, usando valores por defecto")
		else:
			print("❌ No se pudo abrir el archivo de perfiles")
	else:
		print("📂 No se encontró archivo de perfiles, usando valores por defecto")

# CORREGIDO: Solo asegurar referencias básicas a los 7 perfiles
func ensure_basic_vs_wins(profile: Profile):
	# Solo asegurar que existan referencias a los otros 6 perfiles base
	for i in range(7):
		var base_profile_name = "Perfil " + str(i + 1)
		if base_profile_name != profile.profile_name and not profile.vs_wins.has(base_profile_name):
			profile.vs_wins[base_profile_name] = 0

# Sistema de última selección
func save_last_selection():
	var last_selection_data = {
		"last_p1": last_used_profile_p1,
		"last_p2": last_used_profile_p2
	}
	
	var file = FileAccess.open("user://last_selection.save", FileAccess.WRITE)
	if file:
		file.store_var(last_selection_data)
		file.close()
		print("💾 Última selección guardada - P1: ", last_used_profile_p1, " | P2: ", last_used_profile_p2)

func load_last_selection():
	if FileAccess.file_exists("user://last_selection.save"):
		var file = FileAccess.open("user://last_selection.save", FileAccess.READ)
		if file:
			var last_selection_data = file.get_var()
			file.close()
			
			if last_selection_data != null and last_selection_data is Dictionary:
				last_used_profile_p1 = last_selection_data.get("last_p1", -1)
				last_used_profile_p2 = last_selection_data.get("last_p2", -1)
				print("📂 Última selección cargada - P1: ", last_used_profile_p1, " | P2: ", last_used_profile_p2)
			else:
				print("❌ Datos de última selección corruptos")
		else:
			print("❌ No se pudo abrir el archivo de última selección")
	else:
		print("📂 No se encontró archivo de última selección")

# Función para debug mejorada
func print_all_profiles():
	print("=== ESTADO DE TODOS LOS PERFILES ===")
	for i in range(profiles.size()):
		var profile = profiles[i]
		print("Perfil ", i + 1, ": ", profile.profile_name)
		print("   Victorias: ", profile.wins, " | Derrotas: ", profile.losses)
		print("   Récord: ", profile.max_score)
		print("   VS Wins: ")
		for vs_name in profile.vs_wins:
			print("     - ", vs_name, ": ", profile.vs_wins[vs_name])
	print("===================================")

# Función para forzar guardado (útil para testing)
func force_save():
	save_profiles()
	save_last_selection()

# Función para forzar carga (útil para testing)
func force_load():
	load_profiles()
	load_last_selection()
