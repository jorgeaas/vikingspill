extends Control
## Gården sett ovenfra. Alt tegnes med kode, så det trengs ingen bildefiler.
## Sender sted_klikket når spilleren klikker på en bygning eller på noen som venter.

signal sted_klikket(sted: String)

const VERDEN := Vector2(1600, 900)

## Klikkområder i verdenskoordinater.
const STEDER := {
	"skogen": Rect2(20, 20, 250, 230),
	"offerlunden": Rect2(310, 120, 170, 170),
	"smia": Rect2(560, 220, 110, 75),
	"akrene": Rect2(762, 77, 336, 196),
	"nyaakeren": Rect2(1142, 77, 401, 201),
	"langhuset": Rect2(660, 380, 360, 125),
	"buret": Rect2(1060, 300, 60, 60),
	"fjoset": Rect2(1090, 410, 190, 85),
	"trellehuset": Rect2(920, 585, 120, 65),
	"gravhaugene": Rect2(430, 390, 230, 190),
	"naustet": Rect2(350, 555, 85, 115),
	"holmen": Rect2(95, 715, 150, 90),
	"tingstedet": Rect2(1330, 680, 190, 170),
	"nabogarden": Rect2(960, 740, 210, 130),
}

const VANN := [Vector2(-900, 520), Vector2(120, 540), Vector2(300, 640), Vector2(520, 760), Vector2(700, 860), Vector2(780, 1800), Vector2(-900, 1800)]
const STIER := [
	[Vector2(840, 515), Vector2(700, 580), Vector2(560, 610), Vector2(440, 650)],
	[Vector2(840, 515), Vector2(880, 690), Vector2(1200, 740), Vector2(1350, 755)],
	[Vector2(760, 390), Vector2(640, 330), Vector2(520, 300), Vector2(470, 260)],
	[Vector2(1000, 470), Vector2(1100, 470)],
]
## Steder folk går mellom.
const MAAL := [Vector2(840, 520), Vector2(1185, 505), Vector2(400, 680), Vector2(615, 305), Vector2(1090, 370), Vector2(980, 660), Vector2(900, 290), Vector2(1300, 295), Vector2(1420, 690), Vector2(560, 610)]
const BEITE := Rect2(1110, 530, 200, 120)

const C_GRESS := Color("6d8a4a")
const C_SAND := Color("cbb98a")
const C_VANN := Color("3f6f8a")
const C_STI := Color("a8916a")
const C_TORV := Color("7b8a45")
const C_VEGG := Color("6e4f33")
const C_TRE := Color("5a3d24")
const C_STEIN := Color("8f8d86")
const C_RODT := Color("8e3420")
const C_LYS := Color("f3e6c4")

var saker: Array = []
var flagg := {}
## Byggbare steder som er bygd. Steder som ikke kan bygges, finnes alltid.
var bygget := {}
## Tekst som vises når musa er over en tom byggetomt.
var tomt_tekst := {}
var puffer := []
var stats := {"gudene": 50}
var stedsnavn := {}
var font_fet: Font

var tid := 0.0
var hover := ""
var rng := RandomNumberGenerator.new()
var graslapper := []
var traer := []
var bolger := []
var folk := []
var sauer := []
var royk := []
var royk_klokke := 0.0


func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_STOP
	rng.seed = 980
	for i in 90:
		graslapper.append([Vector2(rng.randf_range(-300, 1900), rng.randf_range(-200, 1100)), rng.randf_range(20, 70), rng.randf() < 0.5])
	for i in 34:
		traer.append([Vector2(rng.randf_range(35, 255), rng.randf_range(35, 235)), rng.randf_range(16, 26)])
	for i in 7:
		var a := TAU * i / 7.0
		traer.append([Vector2(395, 205) + Vector2(cos(a), sin(a)) * 70, 17.0])
	for p in [Vector2(300, 40), Vector2(520, 90), Vector2(700, 40), Vector2(1580, 330), Vector2(1560, 480), Vector2(1600, 620), Vector2(1250, 880), Vector2(880, 880), Vector2(1560, 40)]:
		traer.append([p, rng.randf_range(15, 22)])
	traer.sort_custom(func(a, b): return a[0].y < b[0].y)

	var vann := PackedVector2Array(VANN)
	while bolger.size() < 34:
		var p := Vector2(rng.randf_range(-300, 760), rng.randf_range(560, 1100))
		if Geometry2D.is_point_in_polygon(p, vann) and not STEDER["holmen"].grow(30).has_point(p):
			bolger.append(p)

	var farger := [Color("8e3420"), Color("3d5a80"), Color("7a6a4f"), Color("4f6b3a"), Color("a0703a")]
	for i in farger.size():
		folk.append({"pos": MAAL[i], "maal": MAAL[(i + 4) % MAAL.size()], "farge": farger[i], "fart": rng.randf_range(24, 36), "pause": 0.0})
	for i in 6:
		var p := BEITE.position + Vector2(rng.randf() * BEITE.size.x, rng.randf() * BEITE.size.y)
		sauer.append({"pos": p, "maal": p, "retning": 1.0})


# ---------------------------------------------------------------- oppdatering

func _process(delta: float) -> void:
	tid += delta
	for f in folk:
		if f.pause > 0.0:
			f.pause -= delta
			continue
		var til: Vector2 = f.maal - f.pos
		if til.length() < 2.0:
			f.pause = rng.randf_range(1.0, 4.0)
			f.maal = MAAL.pick_random()
		else:
			f.pos += til.normalized() * f.fart * delta
	for s in sauer:
		var til: Vector2 = s.maal - s.pos
		if til.length() < 1.5:
			if rng.randf() < 0.01:
				s.maal = BEITE.position + Vector2(rng.randf() * BEITE.size.x, rng.randf() * BEITE.size.y)
		else:
			s.pos += til.normalized() * 8.0 * delta
			s.retning = signf(til.x) if absf(til.x) > 0.5 else s.retning

	royk_klokke -= delta
	if royk_klokke <= 0.0:
		royk_klokke = 0.25
		royk.append({"pos": Vector2(840, 425), "alder": 0.0})
		if _har("smia"):
			royk.append({"pos": Vector2(615, 240), "alder": 0.0})
	for r in royk:
		r.alder += delta
		r.pos += Vector2(9, -16) * delta
	royk = royk.filter(func(r): return r.alder < 4.0)
	puffer = puffer.filter(func(p): return tid - p.start < 1.5)
	queue_redraw()


## Er stedet på plass? Steder uten tomt_tekst kan ikke bygges og finnes alltid.
func _har(sted: String) -> bool:
	return bygget.has(sted) or not tomt_tekst.has(sted)


## Støvsky der noe nettopp er bygd.
func puff(sted: String) -> void:
	if STEDER.has(sted):
		puffer.append({"rect": STEDER[sted], "start": tid})


# ---------------------------------------------------------------- koordinater og klikk

func _skala() -> float:
	return minf(size.x / VERDEN.x, size.y / VERDEN.y)


func _forskyvning() -> Vector2:
	return (size - VERDEN * _skala()) / 2.0


func _til_verden(p: Vector2) -> Vector2:
	return (p - _forskyvning()) / _skala()


func _merker() -> Array:
	var ut := []
	var antall := {}
	for h in saker:
		var sted: String = h.get("sted", "langhuset")
		antall[sted] = int(antall.get(sted, 0)) + 1
	# Flere som venter på samme sted, står ved siden av hverandre så navnelappene ikke overlapper.
	var teller := {}
	for h in saker:
		var sted: String = h.get("sted", "langhuset")
		var r: Rect2 = STEDER.get(sted, STEDER["langhuset"])
		var n: int = teller.get(sted, 0)
		teller[sted] = n + 1
		var x := r.get_center().x + (n - (int(antall[sted]) - 1) / 2.0) * 200.0
		ut.append([Vector2(x, maxf(r.position.y - 20, 45)), h])
	return ut


## Klikkområdet til et merke: sirkelen med utropstegn og navnelappen over den.
func _merke_omraade(base: Vector2, person: String) -> Rect2:
	var f: Font = font_fet if font_fet else get_theme_default_font()
	var w := maxf(f.get_string_size(person, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 18.0, 60.0)
	return Rect2(base.x - w / 2.0, base.y - 62.0, w, 96.0)


func _finn(p: Vector2) -> String:
	# Merkene ligger øverst, så de vinner over bygninger og byggetomter under dem.
	for m in _merker():
		if p.distance_to(m[0]) < 34 or _merke_omraade(m[0], m[1].get("person", "")).has_point(p):
			return m[1].get("sted", "langhuset")
	var beste := ""
	var minste := INF
	for sted in STEDER:
		var r: Rect2 = STEDER[sted]
		if r.has_point(p) and r.get_area() < minste:
			beste = sted
			minste = r.get_area()
	return beste


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var ny := _finn(_til_verden(e.position))
		if ny != hover:
			hover = ny
			mouse_default_cursor_shape = CURSOR_POINTING_HAND if hover != "" else CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var sted := _finn(_til_verden(e.position))
		if sted != "":
			sted_klikket.emit(sted)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover = ""


# ---------------------------------------------------------------- tegning

func _draw() -> void:
	draw_set_transform(_forskyvning(), 0.0, Vector2.ONE * _skala())
	draw_rect(Rect2(-3000, -3000, 8000, 7000), C_GRESS)
	for g in graslapper:
		draw_circle(g[0], g[1], Color(0.25, 0.35, 0.15, 0.08) if g[2] else Color(0.85, 0.9, 0.5, 0.04))
	_tegn_vann()
	_tegn_stier()
	_tegn_akre()
	_tegn_beite()
	_tegn_gravhauger()
	_tegn_tingsted()
	_tegn_offerlund()
	for t in traer:
		_tre(t[0], t[1])
	_tegn_bygninger()
	for r in royk:
		var a: float = 1.0 - r.alder / 4.0
		draw_circle(r.pos, 6.0 + r.alder * 5.0, Color(0.88, 0.88, 0.86, 0.35 * a))
	_tegn_folk()
	_tegn_skip()
	for p in puffer:
		var t: float = (tid - p.start) / 1.5
		var r: Rect2 = p.rect
		for k in 10:
			var a := TAU * k / 10.0
			var pos := r.get_center() + Vector2(cos(a) * r.size.x * 0.5, sin(a) * r.size.y * 0.5) * (0.6 + t * 0.6)
			draw_circle(pos, 10.0 + t * 18.0, Color(0.85, 0.78, 0.62, 0.55 * (1.0 - t)))
	_tegn_hover()
	_tegn_merker()


func _ellipse(c: Vector2, rx: float, ry: float, farge: Color) -> void:
	var p := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(p, farge)


func _skygge(c: Vector2, rx: float, ry: float) -> void:
	_ellipse(c, rx, ry, Color(0, 0, 0, 0.18))


func _tre(p: Vector2, r: float) -> void:
	draw_circle(p + Vector2(r * 0.3, r * 0.4), r, Color(0, 0, 0, 0.2))
	draw_circle(p, r, Color("3e5a2e"))
	draw_circle(p + Vector2(-r * 0.25, -r * 0.25), r * 0.6, Color("527539"))


func _tegn_vann() -> void:
	var sand := PackedVector2Array()
	for p in VANN:
		sand.append(p + Vector2(22, -22))
	draw_colored_polygon(sand, C_SAND)
	draw_colored_polygon(PackedVector2Array(VANN), C_VANN)
	draw_polyline(PackedVector2Array(VANN.slice(0, 5)), C_VANN.lightened(0.18), 8.0, true)
	for b in bolger:
		var x: float = b.x + sin(tid * 0.6 + b.y) * 12.0
		draw_arc(Vector2(x, b.y), 12, PI * 1.15, PI * 1.85, 8, Color(1, 1, 1, 0.25), 2.0)
	# holmen
	_ellipse(Vector2(170, 762), 72, 42, C_SAND)
	_ellipse(Vector2(168, 756), 56, 31, C_GRESS)
	_ellipse(Vector2(150, 750), 12, 8, C_STEIN)
	if _har("naustet"):
		draw_rect(Rect2(432, 655, 24, 95), C_TRE.lightened(0.15))
		for y in range(660, 750, 10):
			draw_line(Vector2(432, y), Vector2(456, y), C_TRE.darkened(0.2), 1.5)


func _tegn_stier() -> void:
	for s in STIER:
		draw_polyline(PackedVector2Array(s), C_STI, 16.0, true)
		draw_polyline(PackedVector2Array(s), C_STI.lightened(0.12), 6.0, true)


func _tegn_akre() -> void:
	var g: int = stats.get("gudene", 50)
	var bunn := Color("a8b25a")
	var striper := Color("939d4b")
	if g >= 65:
		bunn = Color("d6b34a")
		striper = Color("c19c38")
	elif g < 30:
		bunn = Color("8a7048")
		striper = Color("74603d")
	for sted in ["akrene", "nyaakeren"]:
		if not _har(sted):
			continue
		var r: Rect2 = STEDER[sted].grow(-8)
		draw_rect(r.grow(4), C_STI.darkened(0.15))
		draw_rect(r, bunn)
		var y: float = r.position.y + 8
		while y < r.end.y:
			draw_line(Vector2(r.position.x + 4, y), Vector2(r.end.x - 4, y), striper, 4.0)
			y += 14
		_gjerde(STEDER[sted])
	# nabogårdens lille åker
	var liten := Rect2(1090, 785, 70, 70)
	draw_rect(liten, bunn.darkened(0.1))
	for y in range(790, 855, 12):
		draw_line(Vector2(1093, y), Vector2(1157, y), striper.darkened(0.1), 3.0)


func _gjerde(r: Rect2) -> void:
	draw_rect(r, C_TRE, false, 2.5)
	var x := r.position.x
	while x <= r.end.x:
		draw_rect(Rect2(x - 2, r.position.y - 2, 4, 4), C_TRE.darkened(0.3))
		draw_rect(Rect2(x - 2, r.end.y - 2, 4, 4), C_TRE.darkened(0.3))
		x += 30


func _tegn_beite() -> void:
	if not _har("fjoset"):
		return
	draw_rect(BEITE.grow(8), Color("78964f"))
	_gjerde(BEITE.grow(8))
	for s in sauer:
		_skygge(s.pos + Vector2(1, 4), 9, 4)
		_ellipse(s.pos, 9, 6.5, Color("eeeae0"))
		draw_circle(s.pos + Vector2(8.0 * s.retning, -1), 3.5, Color("3b332c"))


func _haug(p: Vector2, r: float) -> void:
	_skygge(p + Vector2(r * 0.15, r * 0.25), r * 1.05, r * 0.75)
	_ellipse(p, r, r * 0.75, Color("5c7a3a"))
	_ellipse(p + Vector2(-r * 0.2, -r * 0.18), r * 0.65, r * 0.45, Color("6e8f47"))


func _tegn_gravhauger() -> void:
	_haug(Vector2(510, 430), 44)
	_haug(Vector2(612, 470), 32)
	if flagg.has("storhaug"):
		_haug(Vector2(505, 530), 58)
	if flagg.has("liten_grav"):
		for k in 5:
			_ellipse(Vector2(615, 540) + Vector2(cos(k * 1.3), sin(k * 1.3)) * 10, 8, 6, C_STEIN)
	if flagg.has("runestein"):
		var p := Vector2(720, 615)
		_skygge(p + Vector2(6, 22), 16, 6)
		_ellipse(p, 13, 26, Color("a19d92"))
		for k in 4:
			var y := p.y - 15 + k * 9
			draw_line(Vector2(p.x - 5, y), Vector2(p.x + 5, y + 4), Color("a33b26"), 2.0)


func _tegn_tingsted() -> void:
	var c := Vector2(1425, 765)
	for i in 10:
		var a := TAU * i / 10.0
		var p := c + Vector2(cos(a) * 75, sin(a) * 48)
		_skygge(p + Vector2(3, 6), 10, 5)
		_ellipse(p, 9, 12, C_STEIN)
		_ellipse(p + Vector2(-2, -3), 5, 6, C_STEIN.lightened(0.2))
	_skygge(c + Vector2(4, 10), 16, 6)
	_ellipse(c, 14, 18, C_STEIN.darkened(0.1))


func _tegn_offerlund() -> void:
	if not _har("offerlunden"):
		return
	var stein := Vector2(395, 205)
	_skygge(stein + Vector2(4, 8), 24, 9)
	_ellipse(stein, 24, 15, C_STEIN)
	_ellipse(stein + Vector2(-4, -4), 14, 8, C_STEIN.lightened(0.18))
	if int(stats.get("gudene", 50)) >= 65:
		var b := Vector2(395, 245)
		_ellipse(b + Vector2(0, 4), 16, 7, Color("3a2a1e"))
		for k in 3:
			var flamme := b + Vector2(sin(tid * 9.0 + k) * 3.0, -k * 6.0 - absf(sin(tid * 7.0 + k)) * 4.0)
			var farge: Color = [Color(0.95, 0.45, 0.1, 0.9), Color(1.0, 0.7, 0.2, 0.85), Color(1.0, 0.92, 0.6, 0.8)][k]
			draw_circle(flamme, 10.0 - k * 2.5, farge)


## Torvtak sett ovenfra med vegg langs nedre kant. `bue` gir langhuset den buede formen.
func _hus(r: Rect2, tak: Color, vegg: Color, bue := 0.0, dor := true) -> void:
	var vegg_h := r.size.y * 0.26
	var tak_h := r.size.y - vegg_h
	_skygge(r.get_center() + Vector2(12, r.size.y * 0.3), r.size.x * 0.56, r.size.y * 0.5)
	var n := 16
	var topp := PackedVector2Array()
	var bunn := PackedVector2Array()
	for i in n + 1:
		var t := float(i) / n
		var x := r.position.x + r.size.x * t
		var b := bue * sin(PI * t)
		topp.append(Vector2(x, r.position.y + bue - b))
		bunn.append(Vector2(x, r.position.y + tak_h - bue + b))
	var veggpoly := PackedVector2Array(bunn)
	for i in range(n, -1, -1):
		veggpoly.append(bunn[i] + Vector2(0, vegg_h))
	draw_colored_polygon(veggpoly, vegg)
	for i in range(1, n, 2):
		draw_line(bunn[i], bunn[i] + Vector2(0, vegg_h), vegg.darkened(0.25), 1.5)
	var mone := PackedVector2Array()
	for i in n + 1:
		mone.append((topp[i] + bunn[i]) / 2.0)
	var bak := PackedVector2Array(topp)
	for i in range(n, -1, -1):
		bak.append(mone[i])
	draw_colored_polygon(bak, tak.lightened(0.06))
	var fram := PackedVector2Array(mone)
	for i in range(n, -1, -1):
		fram.append(bunn[i])
	draw_colored_polygon(fram, tak.darkened(0.1))
	draw_polyline(mone, tak.darkened(0.35), 3.0)
	draw_polyline(bunn, tak.darkened(0.45), 2.0)
	if dor:
		var midt := bunn[n / 2]
		draw_rect(Rect2(midt.x - 9, midt.y + vegg_h * 0.2, 18, vegg_h * 0.8), Color("2a1c12"))


func _naust(r: Rect2) -> void:
	_skygge(r.get_center() + Vector2(10, 10), r.size.x * 0.6, r.size.y * 0.5)
	var tak := Rect2(r.position, Vector2(r.size.x, r.size.y - 18))
	draw_rect(Rect2(tak.position, Vector2(tak.size.x / 2, tak.size.y)), C_TORV.lightened(0.05))
	draw_rect(Rect2(tak.position + Vector2(tak.size.x / 2, 0), Vector2(tak.size.x / 2, tak.size.y)), C_TORV.darkened(0.12))
	draw_line(tak.position + Vector2(tak.size.x / 2, 0), tak.position + Vector2(tak.size.x / 2, tak.size.y), C_TORV.darkened(0.35), 3.0)
	draw_rect(Rect2(r.position.x, r.end.y - 18, r.size.x, 18), C_VEGG)
	draw_rect(Rect2(r.position.x + 18, r.end.y - 16, r.size.x - 36, 16), Color("2a1c12"))


func _tegn_bygninger() -> void:
	if _har("smia"):
		_hus(STEDER["smia"], Color("4b4038"), C_VEGG.darkened(0.2), 4.0)
		draw_rect(Rect2(607, 281, 16, 13), Color(1.0, 0.55, 0.15, 0.55 + 0.3 * sin(tid * 6.0)))
	_hus(STEDER["langhuset"], C_TORV, C_VEGG, 16.0)
	if _har("buret"):
		_hus(STEDER["buret"], C_TORV.darkened(0.08), C_VEGG.lightened(0.1), 2.0)
	if _har("fjoset"):
		_hus(STEDER["fjoset"], C_TORV.lightened(0.04), C_VEGG.darkened(0.1), 8.0)
	_hus(STEDER["trellehuset"], Color("8f7c50"), C_VEGG.darkened(0.3), 3.0)
	_hus(Rect2(985, 770, 90, 58), Color("8f7c50"), C_VEGG.darkened(0.2), 3.0)
	if _har("naustet"):
		_naust(STEDER["naustet"])
	for sted in tomt_tekst:
		if not bygget.has(sted) and STEDER.has(sted):
			_tomt(STEDER[sted])
	if flagg.has("kors"):
		var p := Vector2(1045, 400)
		_skygge(p + Vector2(4, 24), 8, 3)
		draw_line(p, p + Vector2(0, 26), C_TRE, 4.0)
		draw_line(p + Vector2(-9, 8), p + Vector2(9, 8), C_TRE, 4.0)


## Oppmerket byggetomt med plugger i hjørnene og et pluss-merke.
func _tomt(r: Rect2) -> void:
	draw_rect(r, Color(0.45, 0.38, 0.25, 0.22))
	var hj := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	for i in 4:
		draw_dashed_line(hj[i], hj[(i + 1) % 4], Color(0.95, 0.9, 0.75, 0.75), 2.0, 10.0)
	for p in hj:
		draw_rect(Rect2(p - Vector2(3, 3), Vector2(6, 6)), C_TRE)
	var c := r.get_center()
	var puls := 1.0 + sin(tid * 2.5) * 0.06
	draw_circle(c, 18.0 * puls, Color("c4923a"))
	draw_arc(c, 18.0 * puls, 0, TAU, 24, C_LYS, 2.0)
	draw_line(c - Vector2(8, 0), c + Vector2(8, 0), C_LYS, 4.0)
	draw_line(c - Vector2(0, 8), c + Vector2(0, 8), C_LYS, 4.0)


func _tegn_folk() -> void:
	for f in folk:
		var p: Vector2 = f.pos
		var hopp := absf(sin(tid * 8.0 + p.x)) * 2.0 if f.pause <= 0.0 else 0.0
		_skygge(p + Vector2(0, 7), 7, 3)
		draw_circle(p - Vector2(0, 3 + hopp), 6.5, f.farge)
		draw_circle(p - Vector2(0, 11 + hopp), 4.2, Color("e2b892"))


func _tegn_skip() -> void:
	if flagg.has("skip_tapt") or not _har("naustet"):
		return
	var c := Vector2(430, 805) + Vector2(0, sin(tid * 1.2) * 2.0)
	var lengde := 190.0
	var bredde := 34.0
	_ellipse(c + Vector2(6, 10), lengde / 2, bredde / 2, Color(0, 0, 0, 0.15))
	for lag in 2:
		var l := lengde - lag * 24.0
		var b := bredde - lag * 12.0
		var skrog := PackedVector2Array()
		for i in 21:
			var t := i / 20.0
			skrog.append(c + Vector2(-l / 2 + l * t, -b / 2 * sin(PI * t)))
		for i in range(20, -1, -1):
			var t := i / 20.0
			skrog.append(c + Vector2(-l / 2 + l * t, b / 2 * sin(PI * t)))
		draw_colored_polygon(skrog, Color("6b4a2b") if lag == 0 else Color("8f6a3e"))
	for k in 7:
		var x := -60.0 + k * 20.0
		draw_line(c + Vector2(x, -9), c + Vector2(x, 9), Color("6b4a2b"), 2.0)
	draw_arc(c + Vector2(lengde / 2 + 2, -6), 7, -PI / 2, PI, 10, Color("6b4a2b"), 3.0)
	draw_arc(c + Vector2(-lengde / 2 - 2, -6), 7, 0, PI * 1.5, 10, Color("6b4a2b"), 3.0)
	draw_line(c + Vector2(0, -bredde * 0.75), c + Vector2(0, bredde * 0.75), Color("4a3019"), 4.0)
	draw_circle(c, 5, Color("3a2614"))
	if flagg.has("skip_bytte"):
		for k in 8:
			var t := 0.18 + k * 0.09
			var x := -lengde / 2 + lengde * t
			var dy := bredde / 2 * sin(PI * t)
			for side in [-1.0, 1.0]:
				var farge := Color("d9a531") if k % 2 == 0 else C_RODT
				draw_circle(c + Vector2(x, dy * side), 5.5, farge)
				draw_arc(c + Vector2(x, dy * side), 5.5, 0, TAU, 12, Color("3a2614"), 1.2)
		draw_rect(Rect2(c.x + 30, c.y - 6, 16, 12), Color("b8862f"))


func _navnelapp(p: Vector2, tekst: String, storrelse := 19) -> void:
	var f: Font = font_fet if font_fet else get_theme_default_font()
	var w := f.get_string_size(tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, storrelse).x
	draw_rect(Rect2(p.x - w / 2 - 9, p.y - storrelse, w + 18, storrelse * 1.45), Color(0.12, 0.09, 0.07, 0.88))
	draw_string(f, Vector2(p.x - w / 2, p.y), tekst, HORIZONTAL_ALIGNMENT_LEFT, -1, storrelse, C_LYS)


func _tegn_hover() -> void:
	if hover == "" or not STEDER.has(hover):
		return
	var r: Rect2 = STEDER[hover]
	draw_rect(r.grow(6), Color(1, 0.95, 0.8, 0.55), false, 3.0)
	var tekst: String = stedsnavn.get(hover, hover) if _har(hover) else tomt_tekst[hover]
	_navnelapp(Vector2(r.get_center().x, minf(r.end.y + 30, VERDEN.y - 10)), tekst)


func _tegn_merker() -> void:
	var f: Font = font_fet if font_fet else get_theme_default_font()
	for m in _merker():
		var base: Vector2 = m[0]
		var p := base + Vector2(0, sin(tid * 3.0 + base.x) * 5.0)
		var puls := fmod(tid * 0.9, 1.0)
		draw_arc(p, 22.0 + puls * 22.0, 0, TAU, 32, Color(0.56, 0.2, 0.13, 0.6 * (1.0 - puls)), 3.0)
		_skygge(base + Vector2(0, 28), 14, 5)
		draw_circle(p, 22, C_RODT)
		draw_arc(p, 22, 0, TAU, 32, C_LYS, 3.0)
		draw_string(f, p + Vector2(-20, 11), "!", HORIZONTAL_ALIGNMENT_CENTER, 40, 30, C_LYS)
		_navnelapp(p + Vector2(0, -36), m[1].get("person", ""), 17)
