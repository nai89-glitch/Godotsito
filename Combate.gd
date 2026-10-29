extends Node2D

var base_enemigos = [
	{"nombre": "Slime",     "vida": 15, "atk": 4, "puntos": 1},
	{"nombre": "Esqueleto", "vida": 25, "atk": 7, "puntos": 2},
	{"nombre": "Goblin",    "vida": 20, "atk": 5, "puntos": 1},
]

var aliado_nombre = ""
var aliado_vida = 0
var aliado_vida_max = 0
var aliado_atk = 0

var enemigo_nombre = ""
var enemigo_vida = 0
var enemigo_atk = 0
var enemigo_puntos = 0


func _ready():
	# 1. Stats base
	%PanelPausa.visible = false
	%PanelHabilidades.visible = false
	%PanelOpciones.visible = false
	%Fondo.visible = false
	
	if DatosJuego.aliado_seleccionado.size() > 0:
		aliado_nombre = DatosJuego.aliado_seleccionado["nombre"]
		aliado_vida = DatosJuego.aliado_seleccionado["vida"]
		aliado_atk = DatosJuego.aliado_seleccionado["atk"]
	else:
		aliado_nombre = "Nai"
		aliado_vida = 80
		aliado_atk = 6
	aliado_vida_max = aliado_vida

	# 2. Aplicamos las habilidades ya compradas
	var prog = DatosJuego.obtener(aliado_nombre)
	for h in DatosJuego.arbol.get(aliado_nombre, []):
		if prog["habilidades"].has(h["id"]):
			_aplicar_bonus(h["bonus"])

	_actualizar_vida_aliado()

	# 3. Conectar botones del menú
	%BtnMenu.pressed.connect(_alternar_pausa)
	%BtnHabilidades.pressed.connect(_alternar_habilidades)
	%BtnContinuar.pressed.connect(_cerrar_todo)
	%BtnCerrarHab.pressed.connect(_cerrar_todo)
	%BtnOpciones.pressed.connect(func(): _mostrar_panel(%PanelOpciones))
	%BtnGuardar.pressed.connect(_guardar)
	%BtnReiniciar.pressed.connect(_reiniciar)
	%BtnInicio.pressed.connect(_volver_inicio)
	%BtnCerrarOpc.pressed.connect(func(): _mostrar_panel(%PanelPausa))
	%SliderVolumen.value_changed.connect(_cambiar_volumen)
	%CheckPantalla.toggled.connect(_cambiar_pantalla)

	aparecer_enemigo_aleatorio()


# ---------- COMBATE ----------

func aparecer_enemigo_aleatorio():
	var e = base_enemigos.pick_random()
	enemigo_nombre = e["nombre"]
	enemigo_vida = e["vida"]
	enemigo_atk = e["atk"]
	enemigo_puntos = e["puntos"]
	$VidaEnemigo.text = enemigo_nombre + ": " + str(enemigo_vida)


func Atacar():
	if aliado_vida <= 0:
		return
	enemigo_vida -= aliado_atk

	if enemigo_vida <= 0:
		# Ganamos puntos al matar
		var prog = DatosJuego.obtener(aliado_nombre)
		prog["puntos"] = int(prog["puntos"]) + enemigo_puntos
		print("¡Derrotaste a %s! +%d puntos" % [enemigo_nombre, enemigo_puntos])
		aparecer_enemigo_aleatorio()
	else:
		$VidaEnemigo.text = enemigo_nombre + ": " + str(enemigo_vida)
		enemigo_ataca()


func enemigo_ataca():
	aliado_vida -= enemigo_atk
	if aliado_vida <= 0:
		aliado_vida = 0
		_abrir_pausa()   # usamos el menú como pantalla de derrota
	_actualizar_vida_aliado()


func _actualizar_vida_aliado():
	$VidaActual.text = "%s: %d/%d" % [aliado_nombre, aliado_vida, aliado_vida_max]


func _on_atacar_pressed() -> void:
	Atacar()


# ---------- HABILIDADES ----------

func _aplicar_bonus(bonus: Dictionary):
	if bonus.has("vida"):
		aliado_vida_max += bonus["vida"]
		aliado_vida += bonus["vida"]
	if bonus.has("atk"):
		aliado_atk += bonus["atk"]


func _abrir_habilidades():
	get_tree().paused = true
	_mostrar_panel(%PanelHabilidades)
	_refrescar_habilidades()


func _alternar_pausa():
	if %PanelPausa.visible:
		_cerrar_todo()
	else:
		_abrir_pausa()


func _alternar_habilidades():
	if %PanelHabilidades.visible:
		_cerrar_todo()
	else:
		_abrir_habilidades()


func _cerrar_todo():
	if aliado_vida <= 0:
		return   # si moriste, solo puedes reiniciar o volver al inicio
	%PanelPausa.visible = false
	%PanelHabilidades.visible = false
	%PanelOpciones.visible = false
	%Fondo.visible = false
	get_tree().paused = false
	
func _refrescar_habilidades():
	var prog = DatosJuego.obtener(aliado_nombre)
	%LabelPuntos.text = "Puntos: %d" % int(prog["puntos"])

	for hijo in %ListaHabilidades.get_children():
		hijo.queue_free()

	for h in DatosJuego.arbol.get(aliado_nombre, []):
		var comprada = prog["habilidades"].has(h["id"])
		var bloqueada = h["req"] != "" and not prog["habilidades"].has(h["req"])
		var sin_puntos = int(prog["puntos"]) < h["costo"]

		var b = Button.new()
		var estado = ""
		if comprada: estado = " ✔"
		elif bloqueada: estado = " 🔒"
		b.text = "%s (%d pts): %s%s" % [h["nombre"], h["costo"], h["desc"], estado]
		b.disabled = comprada or bloqueada or sin_puntos
		b.pressed.connect(_comprar.bind(h))
		%ListaHabilidades.add_child(b)


func _comprar(h: Dictionary):
	var prog = DatosJuego.obtener(aliado_nombre)
	prog["puntos"] = int(prog["puntos"]) - h["costo"]
	prog["habilidades"].append(h["id"])
	_aplicar_bonus(h["bonus"])
	_actualizar_vida_aliado()
	_refrescar_habilidades()


# ---------- MENÚ ----------

func _mostrar_panel(panel: Control):
	%PanelPausa.visible = false
	%PanelHabilidades.visible = false
	%PanelOpciones.visible = false
	panel.visible = true


func _abrir_pausa():
	get_tree().paused = true
	%BtnContinuar.disabled = aliado_vida <= 0   # si moriste, no puedes continuar
	_mostrar_panel(%PanelPausa)


func _guardar():
	DatosJuego.guardar()
	%BtnGuardar.text = "¡Guardado!"


func _reiniciar():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _volver_inicio():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu_principal.tscn")  # ajusta el nombre de tu escena


func _cambiar_volumen(valor: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(valor))


func _cambiar_pantalla(activado: bool):
	if activado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
