extends Node2D

var base_enemigos = [
	{"nombre": "Slime",     "vida": 15, "atk": 4, "puntos": 1},
	{"nombre": "Esqueleto", "vida": 25, "atk": 7, "puntos": 2},
	{"nombre": "Goblin",    "vida": 20, "atk": 5, "puntos": 1},
	{"nombre": "Ogro (Jefe)", "vida": 60, "atk": 9, "puntos": 5, "jefe": true},
]

var recompensas = [
	{"nombre": "Curación",  "desc": "Recupera 30 de vida",    "tipo": "curar",    "valor": 30},
	{"nombre": "Vitalidad", "desc": "+15 vida máxima",        "tipo": "vida_max", "valor": 15},
	{"nombre": "Fuerza",    "desc": "+2 ataque",              "tipo": "atk",      "valor": 2},
	{"nombre": "Furia",     "desc": "+4 ataque",              "tipo": "atk",      "valor": 4},
	{"nombre": "Botín",     "desc": "+3 puntos de habilidad", "tipo": "puntos",   "valor": 3},
]

# Aliado
var aliado_nombre = ""
var aliado_vida = 0
var aliado_vida_max = 0
var aliado_atk = 0

# Enemigo
var enemigo_nombre = ""
var enemigo_vida = 0
var enemigo_atk = 0
var enemigo_puntos = 0
var enemigo_jefe = false

# Estado del combate
var derrotados = 0
var activa = {}
var activa_espera = 0
var enemigo_aturdido = 0     # turnos que el enemigo no ataca
var humo = 0                 # ataques que Josu todavía esquiva (activa)
var lloro_usado = false      # pasiva de Nawel
var fallos_josu = {"stun": 0, "esquiva": 0}   # pasiva de Josu (pity)


func _ready():
	# Todo cerrado al iniciar
	%PanelPausa.visible = false
	%PanelHabilidades.visible = false
	%PanelOpciones.visible = false
	%PanelRecompensa.visible = false
	%PanelDerrota.visible = false
	%Fondo.visible = false

	# 1. Stats base
	if DatosJuego.aliado_seleccionado.size() > 0:
		aliado_nombre = DatosJuego.aliado_seleccionado["nombre"]
		aliado_vida = DatosJuego.aliado_seleccionado["vida"]
		aliado_atk = DatosJuego.aliado_seleccionado["atk"]
	else:
		aliado_nombre = "Nai"
		aliado_vida = 80
		aliado_atk = 6
	aliado_vida_max = aliado_vida

	activa = DatosJuego.aliado_seleccionado.get("activa",
		{"id": "vacas", "nombre": "Embestida de vacas", "espera": 3})

	# 2. Habilidades del árbol ya compradas
	var prog = DatosJuego.obtener(aliado_nombre)
	for h in DatosJuego.arbol.get(aliado_nombre, []):
		if prog["habilidades"].has(h["id"]):
			_aplicar_bonus(h["bonus"])

	_actualizar_vida_aliado()

	# 3. Conectar botones
	%BtnMenu.pressed.connect(_alternar_pausa)
	%BtnHabilidades.pressed.connect(_alternar_habilidades)
	%BtnContinuar.pressed.connect(_cerrar_todo)
	%BtnCerrarHab.pressed.connect(_cerrar_todo)
	%BtnOpciones.pressed.connect(func(): _mostrar_panel(%PanelOpciones))
	%BtnGuardar.pressed.connect(_guardar)
	%BtnReiniciar.pressed.connect(_reiniciar)
	%BtnInicio.pressed.connect(_volver_inicio)
	%BtnCerrarOpc.pressed.connect(func(): _mostrar_panel(%PanelPausa))
	%BtnReiniciarDerrota.pressed.connect(_reiniciar)
	%BtnInicioDerrota.pressed.connect(_volver_inicio)
	%BtnActiva.pressed.connect(_usar_activa)
	%SliderVolumen.value_changed.connect(_cambiar_volumen)
	%CheckPantalla.toggled.connect(_cambiar_pantalla)

	_actualizar_boton_activa()
	aparecer_enemigo_aleatorio()


# ---------- COMBATE ----------

func aparecer_enemigo_aleatorio():
	var e = base_enemigos.pick_random()
	enemigo_nombre = e["nombre"]
	enemigo_vida = e["vida"]
	enemigo_atk = e["atk"]
	enemigo_puntos = e["puntos"]
	enemigo_jefe = e.get("jefe", false)
	enemigo_aturdido = 0
	humo = 0
	$VidaEnemigo.text = enemigo_nombre + ": " + str(enemigo_vida)


func Atacar():
	if get_tree().paused or aliado_vida <= 0:
		return
	_inicio_turno()
	if _dañar_enemigo(_daño_ataque(1.0)):
		return
	# Pasiva de Josu: 30% de stun al golpear
	if aliado_nombre == "Josu" and _tirada_josu("stun"):
		enemigo_aturdido = max(enemigo_aturdido, 1)
		print("¡Josu stunea a %s!" % enemigo_nombre)
	_terminar_turno()


func _on_atacar_pressed() -> void:
	Atacar()


func _terminar_turno():
	if activa_espera > 0:
		activa_espera -= 1
	_actualizar_boton_activa()
	enemigo_ataca()


func enemigo_ataca():
	if enemigo_aturdido > 0:
		enemigo_aturdido -= 1
		print("%s está aturdido y no ataca" % enemigo_nombre)
		return

	# Activa de Josu: tira humo
	if humo > 0:
		humo -= 1
		print("%s ataca, pero Josu no estaba ahí" % enemigo_nombre)
		if humo == 0:
			print("¡Josu aparece!")
			if not _dañar_enemigo(_daño_ataque(3.0)):
				enemigo_aturdido = 1
		return

	_recibir_daño(enemigo_atk)


# Resta vida al enemigo. Devuelve true si murió.
func _dañar_enemigo(cantidad: int) -> bool:
	enemigo_vida -= cantidad
	print("%s recibe %d de daño" % [enemigo_nombre, cantidad])
	if enemigo_vida <= 0:
		enemigo_vida = 0
		$VidaEnemigo.text = enemigo_nombre + ": 0"
		var prog = DatosJuego.obtener(aliado_nombre)
		prog["puntos"] = int(prog["puntos"]) + enemigo_puntos
		derrotados += 1
		_mostrar_recompensas()
		return true
	$VidaEnemigo.text = enemigo_nombre + ": " + str(enemigo_vida)
	return false


func _actualizar_vida_aliado():
	$VidaActual.text = "%s: %d/%d" % [aliado_nombre, aliado_vida, aliado_vida_max]


# ---------- PASIVAS ----------

# Ataque actual del aliado (Nawel sube 50% con menos de la mitad de vida)
func _atk_actual() -> int:
	if aliado_nombre == "Nawel" and aliado_vida * 2 < aliado_vida_max:
		return int(aliado_atk * 1.5)
	return aliado_atk


# Daño que hace el aliado con un multiplicador (Sun puede hacer daño doble)
func _daño_ataque(mult: float) -> int:
	var d = _atk_actual() * mult
	if aliado_nombre == "Sun":
		var prob = 0.35 if enemigo_jefe else 0.20
		if randf() < prob:
			d *= 2
			print("¡Normal Stratos! Daño doble")
	return int(d)


# Pasiva de Nai: al inicio de cada turno se cura 10
func _inicio_turno():
	if aliado_nombre == "Nai":
		aliado_vida = min(aliado_vida + 10, aliado_vida_max)
		_actualizar_vida_aliado()
		print("Nai se come una milanesa (+10 de vida)")


# Pasiva de Josu: 30% de éxito, y si falla 2 veces la tercera es segura
func _tirada_josu(tipo: String) -> bool:
	if fallos_josu[tipo] >= 2 or randf() < 0.3:
		fallos_josu[tipo] = 0
		return true
	fallos_josu[tipo] += 1
	return false


# Todo el daño que recibe el aliado pasa por aquí
func _recibir_daño(d: int):
	# Josu: 30% de esquivar
	if aliado_nombre == "Josu" and _tirada_josu("esquiva"):
		print("Josu esquivó el ataque de %s" % enemigo_nombre)
		return

	# Ken: reduce 5 de daño (mínimo 1 para no ser invencible)
	if aliado_nombre == "Ken":
		d = max(d - 5, 1)

	# Nawel: la primera vez que bajaría del 50%, no recibe daño
	if aliado_nombre == "Nawel" and not lloro_usado \
			and aliado_vida * 2 >= aliado_vida_max \
			and (aliado_vida - d) * 2 < aliado_vida_max:
		lloro_usado = true
		print("Nawel se pone a llorar y no recibe daño")
		return

	aliado_vida -= d
	print("%s te hace %d de daño" % [enemigo_nombre, d])
	if aliado_vida <= 0:
		aliado_vida = 0
		_actualizar_vida_aliado()
		_mostrar_derrota()
		return
	_actualizar_vida_aliado()


# ---------- HABILIDAD ACTIVA ----------

func _actualizar_boton_activa():
	if activa_espera > 0:
		%BtnActiva.text = "%s (%d)" % [activa["nombre"], activa_espera]
	else:
		%BtnActiva.text = activa["nombre"]
	%BtnActiva.disabled = activa_espera > 0


func _usar_activa():
	if get_tree().paused or aliado_vida <= 0 or activa_espera > 0:
		return
	_inicio_turno()

	# +1 porque _terminar_turno resta uno al final de este mismo turno
	activa_espera = activa["espera"] + 1

	match activa["id"]:
		"vacas":
			if randf() < 0.25:
				print("Nai se olvidó de qué iba a hacer...")
			elif _dañar_enemigo(_daño_ataque(2.0)):
				return
		"edopro":
			enemigo_aturdido = 2
			aliado_vida = max(aliado_vida - 5, 1)
			_actualizar_vida_aliado()
			print("¡Se crasheó el EDOPro! %s se congela" % enemigo_nombre)
		"sudo":
			aliado_vida = min(aliado_vida + 15, aliado_vida_max)
			_actualizar_vida_aliado()
			if _dañar_enemigo(_daño_ataque(1.5)):
				return
		"gacha":
			var tirada = randf()
			var mult = 1.0
			if tirada < 0.05:
				mult = 5.0
				print("¡SSR!")
			elif tirada < 0.30:
				mult = 2.5
				print("¡Raro!")
			else:
				print("Común...")
			if _dañar_enemigo(_daño_ataque(mult)):
				return
		"humo":
			humo = 2
			print("Josu: ya llego, 5 min...")

	_terminar_turno()


# ---------- HABILIDADES (ÁRBOL) ----------

func _aplicar_bonus(bonus: Dictionary):
	if bonus.has("vida"):
		aliado_vida_max += bonus["vida"]
		aliado_vida += bonus["vida"]
	if bonus.has("atk"):
		aliado_atk += bonus["atk"]


func _abrir_habilidades():
	if %PanelRecompensa.visible or %PanelDerrota.visible:
		return
	get_tree().paused = true
	_mostrar_panel(%PanelHabilidades)
	_refrescar_habilidades()


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


# ---------- RECOMPENSAS Y DERROTA ----------

func _mostrar_recompensas():
	get_tree().paused = true
	_mostrar_panel(%PanelRecompensa)

	for hijo in %OpcionesRecompensa.get_children():
		hijo.queue_free()

	var pool = recompensas.duplicate()
	pool.shuffle()
	for r in pool.slice(0, 3):
		var b = Button.new()
		b.text = "%s\n%s" % [r["nombre"], r["desc"]]
		b.custom_minimum_size = Vector2(200, 80)
		b.pressed.connect(_elegir_recompensa.bind(r))
		%OpcionesRecompensa.add_child(b)


func _elegir_recompensa(r: Dictionary):
	match r["tipo"]:
		"curar":
			aliado_vida = min(aliado_vida + r["valor"], aliado_vida_max)
		"vida_max":
			aliado_vida_max += r["valor"]
			aliado_vida += r["valor"]
		"atk":
			aliado_atk += r["valor"]
		"puntos":
			var prog = DatosJuego.obtener(aliado_nombre)
			prog["puntos"] = int(prog["puntos"]) + r["valor"]

	_actualizar_vida_aliado()
	%PanelRecompensa.visible = false
	%Fondo.visible = false
	get_tree().paused = false
	aparecer_enemigo_aleatorio()


func _mostrar_derrota():
	get_tree().paused = true
	%LabelDerrota.text = "¡Derrota!\nEnemigos derrotados: %d" % derrotados
	_mostrar_panel(%PanelDerrota)


# ---------- MENÚ ----------

func _mostrar_panel(panel: Control):
	for p in [%PanelPausa, %PanelHabilidades, %PanelOpciones, %PanelRecompensa, %PanelDerrota]:
		p.visible = false
	%Fondo.visible = true
	panel.visible = true


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


func _abrir_pausa():
	if %PanelRecompensa.visible or %PanelDerrota.visible:
		return
	get_tree().paused = true
	_mostrar_panel(%PanelPausa)


func _cerrar_todo():
	if aliado_vida <= 0:
		return
	%PanelPausa.visible = false
	%PanelHabilidades.visible = false
	%PanelOpciones.visible = false
	%Fondo.visible = false
	get_tree().paused = false


func _guardar():
	DatosJuego.guardar()
	%BtnGuardar.text = "¡Guardado!"


func _reiniciar():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _volver_inicio():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu_principal.tscn")  # ajusta el nombre


func _cambiar_volumen(valor: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(valor))


func _cambiar_pantalla(activado: bool):
	if activado:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
