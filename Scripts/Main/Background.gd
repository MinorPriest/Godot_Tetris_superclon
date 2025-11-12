# FondoAleatorio.gd
extends Sprite2D

# Array de texturas - puedes asignarlas desde el inspector
@export var texturas_fondo: Array[Texture2D] = [
	preload("res://Assets/Backgrounds/Arcade2.jpg"),
	preload("res://Assets/Backgrounds/TopRacer.jpg"),
	preload("res://Assets/Backgrounds/City1.jpg"),
	preload("res://Assets/Backgrounds/Pacman.jpg"),
	preload("res://Assets/Backgrounds/Retro.jpg")
]

# Opcional: Evitar que se repita el mismo fondo consecutivamente
var ultimo_indice: int = -1

func _ready():
	randomize()  # Para mayor aleatoriedad
	seleccionar_fondo_aleatorio()

func seleccionar_fondo_aleatorio():
	if texturas_fondo.size() > 0:
		var indice_aleatorio = generar_indice_no_repetido()
		texture = texturas_fondo[indice_aleatorio]
		ultimo_indice = indice_aleatorio
		print("Fondo seleccionado: ", indice_aleatorio + 1, " de ", texturas_fondo.size())
	else:
		print("Error: No hay texturas cargadas en el array")

func generar_indice_no_repetido() -> int:
	if texturas_fondo.size() <= 1:
		return 0
	
	var indice_aleatorio = randi() % texturas_fondo.size()
	
	# Si solo hay 2 fondos, evita repetir el mismo
	if texturas_fondo.size() == 2 and indice_aleatorio == ultimo_indice:
		indice_aleatorio = (indice_aleatorio + 1) % texturas_fondo.size()
	
	# Para más de 2 fondos, intenta una vez no repetir
	elif texturas_fondo.size() > 2 and indice_aleatorio == ultimo_indice:
		indice_aleatorio = randi() % texturas_fondo.size()
	
	return indice_aleatorio

# Función pública para cambiar el fondo manualmente si lo necesitas
func cambiar_fondo_aleatorio():
	seleccionar_fondo_aleatorio()

# Función para obtener el índice actual (útil para debug)
func get_indice_actual() -> int:
	return ultimo_indice
