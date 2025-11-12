extends Node
#
## Señales
#signal profile_loaded(profile_data)
#signal profiles_updated()
#signal match_recorded(winner_profile, loser_profile, winner_score, loser_score)
#
## Clase para datos del perfil
#class_name PlayerProfile
#
#var profile_name: String
#var matches_played: int = 0
#var matches_won: int = 0
#var matches_lost: int = 0
#var total_score: int = 0
#var highest_score: int = 0
#var play_time: float = 0.0
#var created_date: String
#var last_played: String
#var vs_records: Dictionary = {}  # {"Jose": {"won": 10, "lost": 5, "score_for": 50000, "score_against": 45000}}
#
#func _init(name: String):
	#profile_name = name
	#created_date = Time.get_date_string_from_system()
	#last_played = created_date
#
#func get_win_rate() -> float:
	#if matches_played == 0:
		#return 0.0
	#return float(matches_won) / float(matches_played) * 100.0
#
#func get_record_against(opponent: String) -> Dictionary:
	#return vs_records.get(opponent, {"won": 0, "lost": 0, "score_for": 0, "score_against": 0})
#
## Variables globales
#var profiles: Dictionary = {}
#var current_profiles: Array[String] = ["", ""]  # [P1, P2]
#var save_path: String = "user://profiles.save"
#
#func _ready():
	#load_profiles()
	#print("✅ ProfileManager inicializado - Perfiles cargados: ", profiles.size())
#
## === Gestión de Perfiles ===
#func create_profile(profile_name: String) -> bool:
	#if profile_name.strip_edges().is_empty():
		#print("❌ Nombre de perfil vacío")
		#return false
	#
	#if profiles.has(profile_name):
		#print("❌ El perfil ya existe: ", profile_name)
		#return false
	#
	#var new_profile = PlayerProfile.new(profile_name)
	#profiles[profile_name] = new_profile
	#save_profiles()
	#
	#print("✅ Perfil creado: ", profile_name)
	#profiles_updated.emit()
	#return true
#
#func delete_profile(profile_name: String) -> bool:
	#if profiles.has(profile_name):
		#profiles.erase(profile_name)
		#save_profiles()
		#
		## Remover de perfiles actuales si estaban seleccionados
		#for i in range(current_profiles.size()):
			#if current_profiles[i] == profile_name:
				#current_profiles[i] = ""
		#
		#print("✅ Perfil eliminado: ", profile_name)
		#profiles_updated.emit()
		#return true
	#return false
#
#func get_profile(profile_name: String) -> PlayerProfile:
	#return profiles.get(profile_name, null)
#
#func get_all_profiles() -> Array:
	#return profiles.keys()
#
## === Gestión de Partida Actual ===
#func set_player_profile(player_index: int, profile_name: String) -> bool:
	#if player_index < 0 or player_index > 1:
		#print("❌ Índice de jugador inválido: ", player_index)
		#return false
	#
	#if profile_name.is_empty() or profiles.has(profile_name):
		#current_profiles[player_index] = profile_name
		#print("✅ Jugador ", player_index + 1, " asignado a perfil: ", profile_name)
		#
		#if not profile_name.is_empty():
			#profile_loaded.emit(profiles[profile_name])
		#
		#return true
	#
	#print("❌ Perfil no encontrado: ", profile_name)
	#return false
#
#func get_current_profile(player_index: int) -> PlayerProfile:
	#if player_index < 0 or player_index > 1:
		#return null
	#
	#var profile_name = current_profiles[player_index]
	#if profile_name.is_empty():
		#return null
	#
	#return profiles.get(profile_name, null)
#
## === Registro de Resultados ===
#func record_match_result(p1_score: int, p2_score: int, game_duration: float) -> void:
	#var p1_profile = get_current_profile(0)
	#var p2_profile = get_current_profile(1)
	#
	#if not p1_profile or not p2_profile:
		#print("❌ No se pueden registrar resultados - perfiles no asignados")
		#return
	#
	## Determinar ganador y perdedor
	#var winner_profile: PlayerProfile
	#var loser_profile: PlayerProfile
	#var winner_score: int
	#var loser_score: int
	#
	#if p1_score > p2_score:
		#winner_profile = p1_profile
		#loser_profile = p2_profile
		#winner_score = p1_score
		#loser_score = p2_score
	#elif p2_score > p1_score:
		#winner_profile = p2_profile
		#loser_profile = p1_profile
		#winner_score = p2_score
		#loser_score = p1_score
	#else:
		## Empate - ambos ganan y pierden? O tratamos diferente?
		#print("⚡ Partida empatada - registrando como empate")
		## Por ahora, tratamos empates como victorias para ambos? O ninguno?
		## Decidamos que en empate, nadie gana pero se registra la partida
		#record_tie(p1_profile, p2_profile, p1_score, p2_score, game_duration)
		#return
	#
	## Actualizar estadísticas del ganador
	#winner_profile.matches_played += 1
	#winner_profile.matches_won += 1
	#winner_profile.total_score += winner_score
	#winner_profile.highest_score = max(winner_profile.highest_score, winner_score)
	#winner_profile.play_time += game_duration
	#winner_profile.last_played = Time.get_date_string_from_system()
	#
	## Actualizar estadísticas del perdedor
	#loser_profile.matches_played += 1
	#loser_profile.matches_lost += 1
	#loser_profile.total_score += loser_score
	#loser_profile.highest_score = max(loser_profile.highest_score, loser_score)
	#loser_profile.play_time += game_duration
	#loser_profile.last_played = Time.get_date_string_from_system()
	#
	## Actualizar records cara a cara
	#update_vs_record(winner_profile, loser_profile, winner_score, loser_score, true)
	#update_vs_record(loser_profile, winner_profile, loser_score, winner_score, false)
	#
	## Guardar cambios
	#save_profiles()
	#
	#print("✅ Partida registrada:")
	#print("   Ganador: ", winner_profile.profile_name, " - Puntos: ", winner_score)
	#print("   Perdedor: ", loser_profile.profile_name, " - Puntos: ", loser_score)
	#print("   VS Record: ", winner_profile.profile_name, " vs ", loser_profile.profile_name, 
		  #" - ", winner_profile.get_record_against(loser_profile.profile_name))
	#
	#match_recorded.emit(winner_profile, loser_profile, winner_score, loser_score)
#
#func record_tie(profile1: PlayerProfile, profile2: PlayerProfile, score1: int, score2: int, game_duration: float) -> void:
	## En empate, ambos juegan pero nadie gana
	#profile1.matches_played += 1
	#profile1.total_score += score1
	#profile1.highest_score = max(profile1.highest_score, score1)
	#profile1.play_time += game_duration
	#profile1.last_played = Time.get_date_string_from_system()
	#
	#profile2.matches_played += 1
	#profile2.total_score += score2
	#profile2.highest_score = max(profile2.highest_score, score2)
	#profile2.play_time += game_duration
	#profile2.last_played = Time.get_date_string_from_system()
	#
	## En empate, no actualizamos records VS
	#save_profiles()
	#
	#print("✅ Empate registrado entre ", profile1.profile_name, " y ", profile2.profile_name)
#
#func update_vs_record(profile: PlayerProfile, opponent: PlayerProfile, score_for: int, score_against: int, is_win: bool) -> void:
	#var opponent_name = opponent.profile_name
	#
	#if not profile.vs_records.has(opponent_name):
		#profile.vs_records[opponent_name] = {"won": 0, "lost": 0, "score_for": 0, "score_against": 0}
	#
	#var record = profile.vs_records[opponent_name]
	#
	#if is_win:
		#record["won"] += 1
	#else:
		#record["lost"] += 1
	#
	#record["score_for"] += score_for
	#record["score_against"] += score_against
#
## === Persistencia ===
#func save_profiles() -> void:
	#var save_data = {
		#"profiles": {},
		#"current_profiles": current_profiles
	#}
	#
	#for profile_name in profiles:
		#var profile = profiles[profile_name]
		#save_data["profiles"][profile_name] = {
			#"matches_played": profile.matches_played,
			#"matches_won": profile.matches_won,
			#"matches_lost": profile.matches_lost,
			#"total_score": profile.total_score,
			#"highest_score": profile.highest_score,
			#"play_time": profile.play_time,
			#"created_date": profile.created_date,
			#"last_played": profile.last_played,
			#"vs_records": profile.vs_records
		#}
	#
	#var file = FileAccess.open(save_path, FileAccess.WRITE)
	#if file:
		#file.store_var(save_data)
		#file.close()
		#print("💾 Perfiles guardados: ", profiles.size())
	#else:
		#print("❌ Error guardando perfiles")
#
#func load_profiles() -> void:
	#var file = FileAccess.open(save_path, FileAccess.READ)
	#if file:
		#var save_data = file.get_var()
		#file.close()
		#
		#if save_data is Dictionary:
			#profiles.clear()
			#
			## Cargar perfiles
			#for profile_name in save_data.get("profiles", {}):
				#var data = save_data["profiles"][profile_name]
				#var profile = PlayerProfile.new(profile_name)
				#
				#profile.matches_played = data.get("matches_played", 0)
				#profile.matches_won = data.get("matches_won", 0)
				#profile.matches_lost = data.get("matches_lost", 0)
				#profile.total_score = data.get("total_score", 0)
				#profile.highest_score = data.get("highest_score", 0)
				#profile.play_time = data.get("play_time", 0.0)
				#profile.created_date = data.get("created_date", Time.get_date_string_from_system())
				#profile.last_played = data.get("last_played", Time.get_date_string_from_system())
				#profile.vs_records = data.get("vs_records", {})
				#
				#profiles[profile_name] = profile
			#
			## Cargar perfiles actuales
			#current_profiles = save_data.get("current_profiles", ["", ""])
			#
			#print("📂 Perfiles cargados: ", profiles.size())
		#else:
			#print("❌ Datos de guardado corruptos")
	#else:
		#print("📂 No hay datos de perfiles guardados - creando nuevo sistema")
#
## === Utilidades ===
#func get_vs_stats(profile1: String, profile2: String) -> Dictionary:
	#var p1 = get_profile(profile1)
	#var p2 = get_profile(profile2)
	#
	#if not p1 or not p2:
		#return {}
	#
	#var p1_vs_p2 = p1.get_record_against(profile2)
	#var p2_vs_p1 = p2.get_record_against(profile1)
	#
	#return {
		#"profile1": {
			#"name": profile1,
			#"won": p1_vs_p2["won"],
			#"lost": p1_vs_p2["lost"],
			#"score_for": p1_vs_p2["score_for"],
			#"score_against": p1_vs_p2["score_against"]
		#},
		#"profile2": {
			#"name": profile2,
			#"won": p2_vs_p1["won"],
			#"lost": p2_vs_p1["lost"],
			#"score_for": p2_vs_p1["score_for"],
			#"score_against": p2_vs_p1["score_against"]
		#},
		#"total_matches": p1_vs_p2["won"] + p1_vs_p2["lost"]
	#}
#
#func clear_all_data() -> void:
	#profiles.clear()
	#current_profiles = ["", ""]
	#
	#if FileAccess.file_exists(save_path):
		#DirAccess.remove_absolute(save_path)
	#
	#print("🗑️ Todos los datos de perfiles eliminados")
	#profiles_updated.emit()
