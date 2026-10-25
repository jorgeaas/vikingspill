extends Control
## Kart over handelsnettverket og toktmålene, fra Irland til Volga og Bagdad.
## Kystlinjene er grove forenklinger tegnet ut fra lengde- og breddegrader.

signal mal_valgt(id: String)

const LON0 := -14.0
const LAT0 := 67.0
const SKALA := 15.5
const STR := Vector2(1085, 620)

const C_LAND := Color("d8c9a0")
const C_HAV := Color("8fb0bf")
const C_BLEKK := Color("4a3b2a")
const C_HANDEL := Color("a87a1c")
const C_TOKT := Color("8e3420")

const ATLANTEREN := [[-16, 68], [14, 68], [13, 66], [12, 65], [10.5, 64], [8, 63.3], [5, 62], [4.8, 61], [5, 60], [5.5, 59], [6, 58.1], [7, 58], [8.5, 58.3], [9.5, 59], [10.5, 59.6], [10.8, 59.0], [11.3, 59.1], [11.9, 58.3], [12.0, 57.6], [10.6, 57.7], [9.8, 57.3], [8.6, 57.1], [8.1, 56.5], [8.2, 55.6], [8.6, 55.0], [8.8, 54.0], [7.0, 53.6], [4.7, 52.9], [3.5, 51.4], [1.6, 50.9], [0.2, 49.6], [-1.5, 49.7], [-1.9, 48.7], [-4.7, 48.4], [-4.3, 47.8], [-2.2, 47.1], [-1.2, 46.2], [-1.4, 44.5], [-1.8, 43.4], [-4, 43.5], [-8, 43.7], [-9.3, 43.0], [-8.8, 41.5], [-9.5, 39], [-9, 37], [-7.5, 37.2], [-6.2, 36.4], [-5.6, 36.0], [-6.5, 34], [-9.8, 30], [-16, 26]]
const OSTERSJOEN := [[10.6, 57.7], [12.0, 57.6], [12.6, 56.2], [12.9, 55.5], [14.2, 55.4], [16, 56.2], [16.6, 57.6], [18.7, 59.5], [17.2, 60.7], [17.5, 62.5], [19, 63.5], [21, 64.8], [25.5, 65.2], [25, 64], [22, 63.3], [21.4, 61], [22.5, 60.2], [26, 60.4], [30.2, 60.0], [28, 59.5], [24, 59.4], [23.5, 58.3], [21.5, 57.3], [21, 56], [20, 54.6], [18.6, 54.4], [16, 54.3], [14.2, 53.9], [11.2, 54.0], [10.8, 54.6], [9.6, 54.5], [9.8, 54.8], [10.4, 55.6], [10.4, 56.5], [10.3, 57.2]]
const MIDDELHAVET := [[-5.6, 36.0], [-4, 36.7], [-0.5, 37.6], [0, 38.9], [-0.3, 39.5], [0.9, 41.0], [3.2, 41.9], [3.1, 43.1], [4.8, 43.4], [6.5, 43.1], [8.5, 44.4], [10.2, 43.9], [10.5, 42.9], [12.3, 41.7], [14, 40.8], [15.6, 40.1], [16.1, 38.9], [17.1, 39.0], [17.2, 40.5], [18.5, 40.1], [16.5, 41.2], [14.2, 42.4], [13.6, 43.6], [12.3, 44.3], [12.3, 45.3], [13.7, 45.7], [15.2, 44.3], [17.0, 43.0], [19.4, 41.8], [19.5, 40.4], [21.1, 37.8], [22.9, 36.5], [24, 38.2], [22.9, 40.5], [26.0, 40.8], [26.2, 39.4], [27, 37.8], [28, 36.8], [30.5, 36.6], [32.5, 36.1], [34.6, 36.8], [36.0, 36.5], [35.9, 35.0], [34.9, 32.5], [34.2, 31.3], [30, 31.3], [25, 31.8], [20, 32.2], [19, 30.4], [15.5, 31.5], [11, 33.5], [11, 35.3], [10.5, 36.9], [9.5, 37.3], [3, 36.8], [-1, 35.8], [-5.3, 35.9]]
const SVARTEHAVET := [[28, 41.2], [29.1, 41.2], [31, 41.1], [33.5, 42], [36, 41.6], [39, 41], [41.6, 41.6], [41.5, 42.6], [39.5, 44], [38, 44.5], [36.6, 45.4], [35, 45.2], [33.5, 44.4], [32.5, 45.4], [33.6, 46.1], [31.5, 46.6], [30.2, 45.8], [29.6, 45.2], [28.6, 44.2], [28, 42.7]]
const KASPIHAVET := [[47.0, 44.8], [46.7, 42.8], [47.8, 42.0], [49.5, 40.3], [48.8, 38.5], [49.0, 37.5], [51, 36.8], [54, 37.3], [53.9, 39.5], [53, 40.8], [52.8, 41.8], [53, 42.5], [51.3, 43.2], [51, 44.5], [53, 45.3], [52.8, 46.8], [51.2, 47.1], [49.2, 46.4], [47.8, 46.3]]
const PERSIAGOLFEN := [[47.9, 30.0], [48.9, 30.3], [50.2, 30.0], [51.5, 27.9], [56, 27], [57, 26], [56, 24], [51.5, 24.5], [51, 26.5], [50, 26.2], [49.5, 27.2], [48.5, 28.5]]
const BRITANNIA := [[-5.7, 50.1], [-3, 50.6], [1.4, 51.1], [1.7, 52.7], [0.3, 53.4], [-0.2, 54.4], [-1.6, 55.6], [-2.1, 56.7], [-1.8, 57.6], [-3.1, 58.6], [-5, 58.6], [-5.8, 57.3], [-5.6, 56.1], [-5.1, 55.2], [-3.1, 54.7], [-3.4, 54.0], [-3.0, 53.3], [-4.6, 53.2], [-4.2, 52.2], [-5.2, 51.7], [-3.3, 51.4], [-4.6, 51.0]]
const IRLAND := [[-6.0, 52.1], [-6.1, 53.9], [-5.6, 54.7], [-7.4, 55.3], [-8.5, 54.6], [-10.1, 54.2], [-9.8, 53.3], [-10.3, 51.9], [-9.6, 51.5], [-8.0, 51.7]]
const SJAELLAND := [[11.1, 55.7], [11.8, 56.0], [12.6, 56.0], [12.4, 55.3], [11.8, 55.1], [11.2, 55.2]]
const FYN := [[9.8, 55.4], [10.6, 55.6], [10.8, 55.1], [10.2, 55.0], [9.7, 55.2]]
const GOTLAND := [[18.1, 57.9], [18.9, 57.6], [18.5, 56.9], [18.1, 57.3]]
const ELVER := [
	[[33, 57], [36, 56.9], [39.9, 57.6], [44, 56.3], [48.5, 55.8], [49.2, 53.2], [46, 51.5], [45, 48.7], [46.5, 47.2], [47.8, 46.3]],
	[[31.3, 58.5], [32.3, 60.0], [31.8, 60.6]],
	[[30.2, 60.0], [31.2, 59.95]],
	[[31, 55.5], [30.5, 50.5], [33, 48], [32.5, 46.6]],
	[[43, 37], [44.4, 33.3], [47.5, 31], [48.4, 30.2]],
	[[38.5, 37], [40.5, 34.5], [44, 32], [47, 30.8]],
	[[0.2, 49.5], [1.0, 49.3], [2.35, 48.85], [3.5, 48.5]],
]
const OMRAADER := [
	["NORGE", [11.5, 63.6]], ["DANMARK", [9.0, 56.4]], ["SVEARIKE", [15.5, 61.5]],
	["ENGLAND", [-1.2, 52.4]], ["IRLAND", [-8.4, 52.0]], ["FRANKERRIKET", [3.5, 46.5]],
	["GARDARIKE", [37, 59.5]], ["BYSANTS", [33, 38.2]], ["KALIFATET", [41, 35.5]],
]
const BYER := [
	["Miklagard (Konstantinopel)", [28.9, 41.0]],
	["Bagdad", [44.4, 33.3]],
	["Itil", [47.8, 46.4]],
]
## Veien sølvet tok fra gruvene i Sentral-Asia og Bagdad nordover til Volga.
const SOLVVEI := [[49.1, 55.0], [47.8, 46.4], [50.5, 41.5], [53.0, 38.5], [57.0, 39.0]]
const SOLVVEI_BAGDAD := [[53.0, 38.5], [48.0, 35.5], [44.4, 33.3]]

var mal: Array = []
var hjem := [5.3, 60.4]
var valgt := ""
var kontakter := {}
var font: Font
var font_fet: Font

var hover := ""
var tid := 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(700, 700.0 * STR.y / STR.x)
	resized.connect(_hold_forhold)


## Kartet skal alltid ha samme forhold mellom bredde og høyde, så ingenting blir kuttet.
func _hold_forhold() -> void:
	var h := size.x * STR.y / STR.x
	if absf(custom_minimum_size.y - h) > 1.0:
		custom_minimum_size.y = h


func _process(delta: float) -> void:
	tid += delta
	queue_redraw()


func ll(p) -> Vector2:
	return Vector2((float(p[0]) - LON0) * SKALA, (LAT0 - float(p[1])) * SKALA)


func _poly(liste: Array) -> PackedVector2Array:
	var ut := PackedVector2Array()
	for p in liste:
		ut.append(ll(p))
	return ut


func _skala() -> float:
	return size.x / STR.x


func _til_kart(p: Vector2) -> Vector2:
	return p / _skala()


func _finn(p: Vector2) -> String:
	for m in mal:
		if p.distance_to(ll(m["pos"])) < 22:
			return m["id"]
	return ""


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var ny := _finn(_til_kart(e.position))
		if ny != hover:
			hover = ny
			mouse_default_cursor_shape = CURSOR_POINTING_HAND if hover != "" else CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var id := _finn(_til_kart(e.position))
		if id != "":
			valgt = id
			mal_valgt.emit(id)


func _tekst(p: Vector2, tekst: String, storrelse: int, farge: Color, f: Font = null, sentrert := true) -> void:
	var ff: Font = f if f else (font if font else get_theme_default_font())
	var w := ff.get_string_size(tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, storrelse).x
	var x := p.x - w / 2.0 if sentrert else p.x
	draw_string(ff, Vector2(x, p.y), tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, storrelse, farge)


## Navnet på et sted, på den siden av merket som er angitt (over, under, venstre eller hoyre).
func _navn(p: Vector2, r: float, tekst: String, side: String) -> void:
	var ff: Font = font_fet if font_fet else get_theme_default_font()
	var w := ff.get_string_size(tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	var pos := p + Vector2(-w / 2.0, -r - 8)
	match side:
		"under":
			pos = p + Vector2(-w / 2.0, r + 20)
		"venstre":
			pos = p + Vector2(-w - r - 8, 6)
		"hoyre":
			pos = p + Vector2(r + 8, 6)
	draw_rect(Rect2(pos + Vector2(-3, -15), Vector2(w + 6, 20)), Color(C_LAND, 0.75))
	draw_string(ff, pos, tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, C_BLEKK)


func _stiplet(punkter: PackedVector2Array, farge: Color, bredde: float, strek := 10.0) -> void:
	for i in punkter.size() - 1:
		draw_dashed_line(punkter[i], punkter[i + 1], farge, bredde, strek)


func _punkt_langs(punkter: PackedVector2Array, t: float) -> Vector2:
	var total := 0.0
	for i in punkter.size() - 1:
		total += punkter[i].distance_to(punkter[i + 1])
	var igjen := total * t
	for i in punkter.size() - 1:
		var d := punkter[i].distance_to(punkter[i + 1])
		if igjen <= d:
			return punkter[i].lerp(punkter[i + 1], igjen / maxf(d, 0.001))
		igjen -= d
	return punkter[punkter.size() - 1]


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * _skala())
	draw_rect(Rect2(Vector2.ZERO, STR), C_LAND)
	for hav in [ATLANTEREN, OSTERSJOEN, MIDDELHAVET, SVARTEHAVET, KASPIHAVET, PERSIAGOLFEN]:
		draw_colored_polygon(_poly(hav), C_HAV)
	for land in [BRITANNIA, IRLAND, SJAELLAND, FYN, GOTLAND]:
		draw_colored_polygon(_poly(land), C_LAND)
	for sjo in [[[31.5, 60.9], 1.2], [[35.5, 61.6], 0.8]]:
		draw_circle(ll(sjo[0]), sjo[1] * SKALA, C_HAV)
	for elv in ELVER:
		draw_polyline(_poly(elv), C_HAV.darkened(0.05), 3.0, true)
	for o in OMRAADER:
		_tekst(ll(o[1]), o[0], 17, Color(C_BLEKK, 0.45), font_fet)

	# Sølvets vei fra Sentral-Asia og Bagdad
	var solv := Color("8a8a8a")
	_stiplet(_poly(SOLVVEI), solv, 2.5, 6.0)
	_stiplet(_poly(SOLVVEI_BAGDAD), solv, 2.5, 6.0)
	_tekst(ll([50.5, 35.2]), "sølv fra Sentral-Asia", 14, solv.darkened(0.3))
	for b in BYER:
		draw_circle(ll(b[1]), 5, C_BLEKK)
		_tekst(ll(b[1]) + Vector2(0, 22), b[0], 15, C_BLEKK)

	# Rutene
	for m in mal:
		var rute := _poly(m["rute"])
		var farge := C_HANDEL if m["type"] == "handel" else C_TOKT
		var aktiv: bool = m["id"] == valgt or m["id"] == hover
		_stiplet(rute, Color(farge, 0.9 if aktiv else 0.5), 4.0 if aktiv else 2.5)
		if m["id"] == valgt:
			var skip := _punkt_langs(rute, fmod(tid * 0.12, 1.0))
			draw_circle(skip, 7, C_BLEKK)
			draw_circle(skip, 4, C_LAND)

	# Målene
	for m in mal:
		var p := ll(m["pos"])
		var handel: bool = m["type"] == "handel"
		var farge := C_HANDEL if handel else C_TOKT
		var r := 13.0 if (m["id"] == valgt or m["id"] == hover) else 10.0
		if kontakter.has(m["id"]):
			draw_arc(p, r + 6, 0, TAU, 24, C_HANDEL, 3.0)
		if handel:
			draw_circle(p, r, farge)
			draw_circle(p, r * 0.5, Color("e8c66a"))
		else:
			var rute := PackedVector2Array([p + Vector2(0, -r * 1.2), p + Vector2(r * 1.2, 0), p + Vector2(0, r * 1.2), p + Vector2(-r * 1.2, 0)])
			draw_colored_polygon(rute, farge)
		draw_arc(p, r, 0, TAU, 24, C_BLEKK, 1.5)
		_navn(p, r, m["navn"], m.get("etikett", "over"))

	# Hjemme
	var h := ll(hjem)
	draw_circle(h, 11, Color("f3e6c4"))
	draw_arc(h, 11, 0, TAU, 24, C_BLEKK, 3.0)
	draw_circle(h, 4, C_BLEKK)
	_navn(h, 11, "Gården din", "venstre")

	# Tegnforklaring
	var lx := 18.0
	var ly := STR.y - 70.0
	draw_rect(Rect2(lx - 8, ly - 22, 250, 84), Color(C_LAND, 0.9))
	draw_circle(Vector2(lx + 8, ly - 4), 7, C_HANDEL)
	_tekst(Vector2(lx + 24, ly + 1), "Handelssted", 15, C_BLEKK, null, false)
	draw_colored_polygon(PackedVector2Array([Vector2(lx + 8, ly + 12), Vector2(lx + 16, ly + 20), Vector2(lx + 8, ly + 28), Vector2(lx, ly + 20)]), C_TOKT)
	_tekst(Vector2(lx + 24, ly + 25), "Toktmål", 15, C_BLEKK, null, false)
	draw_arc(Vector2(lx + 8, ly + 44), 9, 0, TAU, 20, C_HANDEL, 3.0)
	_tekst(Vector2(lx + 24, ly + 49), "Fast handelsforbindelse", 15, C_BLEKK, null, false)
