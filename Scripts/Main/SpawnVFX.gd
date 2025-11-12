# SpawnVFX.gd
extends Node2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	# ✅ FORZAR que este nodo se ejecute aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	animated_sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	
	print("🎬 SpawnVFX iniciado (PROCESS_MODE_ALWAYS)")
	animated_sprite.play("SpawnVFX")
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished():
	print("✅ SpawnVFX animación COMPLETADA")
	
	# ✅ OCULTAR el sprite antes de destruir
	animated_sprite.visible = false
	
	# Pequeño delay para asegurar que se procese el cambio de visibilidad
	await get_tree().process_frame
	queue_free()
