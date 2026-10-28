extends Control

# Lista de aliados disponibles
var base_aliados = [
	{"nombre": "Nai", "vida": 80, "atk": 6},
	{"nombre": "Ken", "vida": 90, "atk": 3},
	{"nombre": "Sun", "vida": 60, "atk": 8},
	{"nombre": "Nawel", "vida": 50, "atk": 12}
]

# Aliado seleccionado actualmente (por defecto el primero)
var aliado_elegido = {}

func _ready():
	# 1. Limpiamos y llenamos el OptionButton con los nombres
	$SeleccionAliado.clear()
	for aliado in base_aliados:
		$SeleccionAliado.add_item(aliado["nombre"])
	
	# 2. Seleccionamos al primero de la lista al arrancar
	_actualizar_seleccion(0)
	
	# 3. Conectamos las señales por código para evitar errores
	$SeleccionAliado.item_selected.connect(_on_seleccion_aliado_item_selected)
	$BotonJugar.pressed.connect(_on_boton_jugar_pressed)


func _actualizar_seleccion(index: int):
	aliado_elegido = base_aliados[index]
	
	# Si tienes un Label llamado TextoStats, mostramos los datos del personaje
	if has_node("TextoStats"):
		$TextoStats.text = "Vida: " + str(aliado_elegido["vida"]) + " | Ataque: " + str(aliado_elegido["atk"])


func _on_seleccion_aliado_item_selected(index: int):
	_actualizar_seleccion(index)


func _on_boton_jugar_pressed():
	# Guardamos el personaje en el Autoload (DatosJuego) antes de cambiar de escena
	DatosJuego.aliado_seleccionado = aliado_elegido
	
	# Cambiamos a la escena del Escenario / Combate
	get_tree().change_scene_to_file("res://Combate.tscn") # Ajusta la ruta a tu escena
