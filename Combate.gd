extends Node2D

# Catálogo de enemigos posibles
var base_enemigos = [
	{"nombre": "Slime", "vida": 15, "atk": 4},
	{"nombre": "Esqueleto", "vida": 25, "atk": 7},
	{"nombre": "Goblin", "vida": 20, "atk": 5},
]

# Datos del Aliado Actual (se cargan desde el Autoload)
var aliado_nombre = ""
var aliado_vida = 0
var aliado_atk = 0

# Datos del Enemigo Actual
var enemigo_nombre = ""
var enemigo_vida = 0
var enemigo_atk = 0


func _ready():
	# 1. Leemos la selección guardada en DatosJuego
	if DatosJuego.aliado_seleccionado.size() > 0:
		aliado_nombre = DatosJuego.aliado_seleccionado["nombre"]
		aliado_vida = DatosJuego.aliado_seleccionado["vida"]
		aliado_atk = DatosJuego.aliado_seleccionado["atk"]
	else:
		# Personaje por defecto si probamos la escena sola (F6)
		aliado_nombre = "Nai"
		aliado_vida = 80
		aliado_atk = 6

	# 2. Mostramos los datos del jugador en la interfaz
	$VidaActual.text = aliado_nombre + ": " + str(aliado_vida)
	
	# 3. Generamos al primer enemigo
	aparecer_enemigo_aleatorio()


func aparecer_enemigo_aleatorio():
	var enemigo_elegido = base_enemigos.pick_random()
	
	enemigo_nombre = enemigo_elegido["nombre"]
	enemigo_vida = enemigo_elegido["vida"]
	enemigo_atk = enemigo_elegido["atk"]
	
	$VidaEnemigo.text = enemigo_nombre + ": " + str(enemigo_vida)
	print("¡Un " + enemigo_nombre + " ha aparecido!")


func Atacar():
	enemigo_vida -= aliado_atk
	print("Has infligido " + str(aliado_atk) + " de Daño a " + enemigo_nombre)
	
	if enemigo_vida <= 0:
		enemigo_vida = 0
		$VidaEnemigo.text = enemigo_nombre + ": 0"
		print("¡Has derrotado al " + enemigo_nombre + "!")
	else:
		$VidaEnemigo.text = enemigo_nombre + ": " + str(enemigo_vida)
		enemigo_ataca()


func enemigo_ataca():
	aliado_vida -= enemigo_atk
	
	if aliado_vida <= 0:
		aliado_vida = 0
		print("¡Has sido derrotado!")
	else:
		print("¡" + enemigo_nombre + " te atacó! Tu vida es: " + str(aliado_vida))
		
	$VidaActual.text = aliado_nombre + ": " + str(aliado_vida)

func _on_atacar_pressed() -> void:
	Atacar()
