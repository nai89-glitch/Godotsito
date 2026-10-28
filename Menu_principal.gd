extends Control

# Nombre del nodo en la escena + sus stats
var personajes = [
	{
		"nodo": "Nai", "nombre": "Nai", "vida": 80, "atk": 6,
		"pasiva": "Comedor: recupera 10 de vida al inicio de cada turno.",
		"estilo": "Gordo que come una milanesa al comienzo del turno, full curacion."
	},
	{
		"nodo": "Ken", "nombre": "Ken", "vida": 90, "atk": 5,
		"pasiva": "Piel de Suciedad: reduce 5 de daño en cada golpe recibido.",
		"estilo": "Gordo combo, pega poco, pero muchas veces,es ken."
	},
	{
		"nodo": "Sun", "nodo_extra": "", "nombre": "Sun", "vida": 60, "atk": 8,
		"pasiva": "Normal Stratos: 20% de probabilidad de hacer daño doble, contra jefes 35%.",
		"estilo": "Chance de reventar al enemigo de un golpe con su puño de mil hamburguesas."
	},
	{
		"nodo": "Nawel", "nombre": "Nawel", "vida": 50, "atk": 12,
		"pasiva": "El lloros: Con menos de la mitad de vida, su ataque sube 50%, no recibe daño la primera vez que baja del 50% su vida",
		"estilo": "Cuando Nawel llora aumenta su ataque en un 50%, mucho riesgo y lloros."
	},
	{
		"nodo": "Josu", "nombre": "Josu", "vida": 20, "atk": 10,
		"pasiva": "En un rato estoy: 30% de stun al golpear, 30% de esquivar ataques, 
		si falla 2 veces la tercera es asegurada",
		"estilo": "Si el gordo no esta nadie puede jugar, ignora lo que le preguntes como los ataques."
	}
]
var indice = 0

func _ready():
	$Izquierda.pressed.connect(_anterior)
	$Derecha.pressed.connect(_siguiente)
	$Jugar.pressed.connect(_on_Jugar_pressed)
	_mostrar_personaje()


func _unhandled_input(event):
	# También funciona con las flechas del teclado
	if event.is_action_pressed("ui_left"):
		_anterior()
	elif event.is_action_pressed("ui_right"):
		_siguiente()


func _anterior():
	indice = posmod(indice - 1, personajes.size())
	_mostrar_personaje()


func _siguiente():
	indice = posmod(indice + 1, personajes.size())
	_mostrar_personaje()


func _mostrar_personaje():
	# Oculta todos y deja visible solo el seleccionado
	for i in personajes.size():
		var n = get_node_or_null(personajes[i]["nodo"])
		if n:
			n.visible = (i == indice)

	var p = personajes[indice]
	$TextoStats.text = "%s\nVida: %d | Ataque: %d\nPasiva: %s" % [
		p["nombre"], p["vida"], p["atk"], p["pasiva"]
	]
	$TextoDescripcion.text = p["estilo"]


func _on_Jugar_pressed():
	DatosJuego.aliado_seleccionado = personajes[indice]
	get_tree().change_scene_to_file("res://Combate.tscn")
