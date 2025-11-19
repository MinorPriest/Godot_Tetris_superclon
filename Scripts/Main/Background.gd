# FondoAleatorio.gd
extends Node2D

# Array de escenas de fondo - puedes asignarlas desde el inspector
@export var escenas_fondo: Array[PackedScene] = [
	preload("res://Scenes/BackgroundScenes/PacManScene.tscn"),
	preload("res://Scenes/BackgroundScenes/GalagaScene.tscn"),
	preload("res://Scenes/BackgroundScenes/TopGearScene.tscn")
]

# Referencia a la escena actual instanciada
var escena_actual: Node2D = null

# Opcional: Evitar que se repita el mismo fondo consecutivamente
var ultimo_indice: int = -1

func _ready():
	randomize()  # Para mayor aleatoriedad
	seleccionar_fondo_aleatorio()

func seleccionar_fondo_aleatorio():
	if escenas_fondo.is_empty():
		print("❌ Error: No hay escenas cargadas en el array")
		return
	
	var indice_aleatorio = generar_indice_no_repetido()
	
	# Eliminar la escena anterior si existe
	if escena_actual:
		escena_actual.queue_free()
		escena_actual = null
	
	# Instanciar la nueva escena
	var nueva_escena = escenas_fondo[indice_aleatorio].instantiate()
	
	# Configurar la posición y propiedades
	nueva_escena.position = Vector2.ZERO
	
	# Agregar como hijo de este nodo
	add_child(nueva_escena)
	escena_actual = nueva_escena
	
	ultimo_indice = indice_aleatorio
	print("🎮 Fondo escena seleccionado: ", escenas_fondo[indice_aleatorio].resource_path.get_file(), " (Índice: ", indice_aleatorio + 1, " de ", escenas_fondo.size(), ")")
	
	# DEBUG: Verificar que la escena se agregó correctamente
	print("🔍 DEBUG: Hijos del fondo: ", get_child_count())
	if escena_actual:
		print("🔍 DEBUG: Escena actual es válida: ", escena_actual != null)
		print("🔍 DEBUG: Escena actual visible: ", escena_actual.visible)
		print("🔍 DEBUG: Tipo de escena: ", escena_actual.get_class())

func generar_indice_no_repetido() -> int:
	if escenas_fondo.size() <= 1:
		return 0
	
	var indice_aleatorio = randi() % escenas_fondo.size()
	
	# Si solo hay 2 fondos, evita repetir el mismo
	if escenas_fondo.size() == 2 and indice_aleatorio == ultimo_indice:
		indice_aleatorio = (indice_aleatorio + 1) % escenas_fondo.size()
	
	# Para más de 2 fondos, intenta una vez no repetir
	elif escenas_fondo.size() > 2 and indice_aleatorio == ultimo_indice:
		indice_aleatorio = randi() % escenas_fondo.size()
	
	return indice_aleatorio

# Función pública para cambiar el fondo manualmente si lo necesitas
func cambiar_fondo_aleatorio():
	seleccionar_fondo_aleatorio()

# Función para obtener el índice actual (útil para debug)
func get_indice_actual() -> int:
	return ultimo_indice

# Función para obtener la escena actual (útil si necesitas referenciarla)
func get_escena_actual() -> Node2D:
	return escena_actual
