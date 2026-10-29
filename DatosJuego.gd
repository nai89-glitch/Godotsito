extends Node

var aliado_seleccionado = {}

# Progreso por personaje: { "Nai": {"puntos": 0, "habilidades": ["nai_1"]} }
var progreso = {}

const RUTA_GUARDADO = "user://partida.json"

# Árbol de habilidades. "req" = id de la habilidad que se necesita antes ("" = ninguna)
var arbol = {
	"Nai": [
		{"id": "nai_1", "nombre": "Grasa",     "desc": "+10 vida", "costo": 1, "req": "",      "bonus": {"vida": 10}},
		{"id": "nai_2", "nombre": "Fuerza",      "desc": "+2 ataque", "costo": 2, "req": "nai_1", "bonus": {"atk": 2}},
		{"id": "nai_3", "nombre": "Cardio",   "desc": "+20 vida", "costo": 3, "req": "nai_1", "bonus": {"vida": 20}},
	],
	"Ken": [
		{"id": "ken_1", "nombre": "Grasa",    "desc": "+15 vida", "costo": 1, "req": "",      "bonus": {"vida": 15}},
		{"id": "ken_2", "nombre": "Fuerza",     "desc": "+2 ataque", "costo": 2, "req": "ken_1", "bonus": {"atk": 2}},
	],"Nawel": [
		{"id": "ken_1", "nombre": "Grasa",    "desc": "+15 vida", "costo": 1, "req": "",      "bonus": {"vida": 15}},
		{"id": "ken_2", "nombre": "Fuerza",     "desc": "+2 ataque", "costo": 2, "req": "ken_1", "bonus": {"atk": 2}},
	],"Sun": [
		{"id": "ken_1", "nombre": "Grasa",    "desc": "+15 vida", "costo": 1, "req": "",      "bonus": {"vida": 15}},
		{"id": "ken_2", "nombre": "Fuerza",     "desc": "+2 ataque", "costo": 2, "req": "ken_1", "bonus": {"atk": 2}},
	],"Josu": [
		{"id": "ken_1", "nombre": "Coraza",    "desc": "+15 vida", "costo": 1, "req": "",      "bonus": {"vida": 15}},
		{"id": "ken_2", "nombre": "Puños",     "desc": "+2 ataque", "costo": 2, "req": "ken_1", "bonus": {"atk": 2}},
	],

}

func _ready():
	cargar()


func obtener(nombre: String) -> Dictionary:
	if not progreso.has(nombre):
		progreso[nombre] = {"puntos": 0, "habilidades": []}
	return progreso[nombre]


func guardar():
	var f = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	f.store_string(JSON.stringify(progreso))


func cargar():
	if not FileAccess.file_exists(RUTA_GUARDADO):
		return
	var f = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	var datos = JSON.parse_string(f.get_as_text())
	if datos is Dictionary:
		progreso = datos
