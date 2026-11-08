extends Control
## Høvdingen – et læringsspill om vikingsamfunnet (historie Vg2).
## Alt innhold ligger i data/:
##   hendelser.json – sakene folk kommer med      steder.json   – gården og byggetomtene
##   ressurser.json – infoboksene om ressursene   treller.json  – trellene og historiene deres
##   handel.json    – handelssteder og toktmål     tinget.json   – tingsaker og forslag

const Verden := preload("res://scripts/verden.gd")
const Kart := preload("res://scripts/kart.gd")

const DATA_PATH := "res://data/hendelser.json"
const STEDER_PATH := "res://data/steder.json"
const RESSURSER_PATH := "res://data/ressurser.json"
const TRELLER_PATH := "res://data/treller.json"
const HANDEL_PATH := "res://data/handel.json"
const TING_PATH := "res://data/tinget.json"
const SAGA_PATH := "res://data/saga.json"
const SAMLING_PATH := "user://samling.cfg"
const ANTALL_VINTRE := 8
const SAKER_PER_VINTER := 2

## Støtte som ikke får gå til null – da er spillet tapt.
const STOTTE := ["aere", "gudene", "aetten", "bondene"]
const RESSURSER := ["solv", "aere", "gudene", "aetten", "bondene"]
const NAVN := {
	"solv": "Sølv",
	"aere": "Ære",
	"gudene": "Gudenes gunst",
	"aetten": "Ætten",
	"bondene": "Bøndene",
}
## Slik skrives ressursene når de er en pris.
const KOST_NAVN := {
	"solv": "sølv",
	"aere": "ære",
	"gudene": "gudenes gunst",
	"aetten": "støtte fra ætten",
	"bondene": "støtte fra bøndene",
}
const TAP_TEKST := {
	"aere": "Ingen har lenger respekt for deg. På vårtinget velger bøndene en annen høvding, og du må leve resten av livet i skam. For en viking var tapt ære nesten verre enn døden.",
	"gudene": "Tre uår på rad. Bøndene mener gudene har vendt seg bort fra deg. Snorre forteller at svearne ofret sin egen konge, Domalde, etter flere uår. Du flykter før det samme skjer med deg.",
	"aetten": "Slekta di vender deg ryggen. Uten ætten har du ingen som vil hevne deg eller stå sammen med deg på tinget. I vikingtiden var den som sto alene, nesten forsvarsløs.",
	"bondene": "Bøndene har fått nok. På tinget går de sammen mot deg og velger en ny høvding. En høvding var helt avhengig av støtte fra de frie bøndene.",
}

## Yngre futhark (16 runer). Flere lyder deler samme rune.
const RUNER := {
	"f": "ᚠ", "u": "ᚢ", "o": "ᚢ", "v": "ᚢ", "w": "ᚢ", "y": "ᚢ", "ø": "ᚢ",
	"þ": "ᚦ", "a": "ᛅ", "æ": "ᛅ", "å": "ᚬ", "r": "ᚱ",
	"k": "ᚴ", "g": "ᚴ", "c": "ᚴ", "q": "ᚴ", "h": "ᚼ", "n": "ᚾ",
	"i": "ᛁ", "e": "ᛁ", "j": "ᛁ", "s": "ᛋ", "z": "ᛋ", "x": "ᚴᛋ",
	"t": "ᛏ", "d": "ᛏ", "b": "ᛒ", "p": "ᛒ", "m": "ᛘ", "l": "ᛚ",
}

const C_BG := Color("1d1915")
const C_TOPP := Color("2b241e")
const C_PANEL := Color("ece2c9")
const C_FAKTA := Color("ddd0ad")
const C_INK := Color("2a2019")
const C_LYS := Color("ece2c9")
const C_ACCENT := Color("8e3420")
const C_MUTED := Color("6f6250")
const C_GULL := Color("c4923a")
const C_PLUSS := Color("2f6b33")
const C_STEIN := Color("8d8c84")

var hendelser: Array = []
var steder := {}
var ressurser := {}
var trelldata := {}
var handeldata := {}
var tingdata := {}
var sagadata := {}
var samling := {}
## Det som skjedde i løpet av spillet, slik at sagaen kan fortelle om det til slutt.
var logg := {}

var stats := {}
var flagg := {}
var bygget := {}
var treller: Array = []
## Faste handelsforbindelser: mål-id -> sølv per vinter.
var kontakter := {}
## Hvor mange som vil hevne seg etter tokt. Gir fare for hevntokt.
var fiender := 0
var skip_seilt := false
var skip_borte_til := 0
var ting_brukt := false
var hovding_navn := ""
var vinter := 1
var ko: Array = []
var aktive: Array = []
var skjerm := ""

# Tinget som er satt akkurat nå
var ting_sak: Dictionary = {}
var ting_valg: Dictionary = {}
var ting_h = null
var ting_bonus := 0
var ting_brukte := {}
## Gudene krever nye offer: Gunsten synker litt hver vinter.
const GUDER_FORFALL := 6
const GUDER_FORFALL_MED_OFFERLUND := 3
const GUDER_FORFALL_KRISTEN := 3
## Hvor mye gudenes gunst kan endre sjansen for å lykkes (ved gunst 0 eller 100).
const GUDER_MAKS_BONUS := 0.2

## Tinget er usikkert: Stemningen kan svinge, og en rival kan tale mot deg i siste liten.
const TING_SVING := 12
const TING_RIVAL_SJANSE := 0.3
const TING_RIVAL_MOTSTAND := 10

var valgt_mal := ""
var mal_detaljer: VBoxContainer

var font_tekst: Font
var font_fet: Font
var font_kursiv: Font
var font_runer: Font

var topplinje: PanelContainer
var vinter_etikett: Label
var solv_etikett: Label
var hint: Label
var neste_knapp: Button
var trell_knapp: Button
var skip_knapp: Button
var ting_knapp: Button
var stat_barer := {}
var verden: Control
var overlegg: Control
var innhold: VBoxContainer
var rulle: ScrollContainer


func _ready() -> void:
	_last_data()
	_last_samling()
	_bygg_ramme()
	_vis_start()
	if "--autotest" in OS.get_cmdline_user_args():
		_autotest()


# ---------------------------------------------------------------- data

func _les_json(sti: String):
	var res = load(sti)
	var data = res.data if res is JSON else JSON.parse_string(FileAccess.get_file_as_string(sti))
	if data == null:
		push_error("Kunne ikke lese " + sti + " – sjekk at JSON-filen er gyldig.")
	return data


func _last_data() -> void:
	var data = _les_json(DATA_PATH)
	if data is Array:
		hendelser = data
	for par in [["steder", STEDER_PATH], ["ressurser", RESSURSER_PATH], ["trelldata", TRELLER_PATH], ["handeldata", HANDEL_PATH], ["tingdata", TING_PATH], ["sagadata", SAGA_PATH]]:
		var d = _les_json(par[1])
		if d is Dictionary:
			set(par[0], d)


func _last_samling() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAMLING_PATH) == OK:
		for id in cfg.get_value("kort", "funnet", []):
			samling[id] = true


func _lagre_samling() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("kort", "funnet", samling.keys())
	cfg.save(SAMLING_PATH)


## Alle kunnskapskortene i spillet, i den rekkefølgen de vises i samlingen.
func _alle_kort() -> Array:
	var ut := []
	for h in hendelser:
		ut.append({"id": h["id"], "fakta": h["fakta"]})
	ut.append({"id": "treller", "fakta": trelldata["fakta"]})
	ut.append({"id": "trell_rettigheter", "fakta": trelldata["fakta_rettigheter"]})
	for m in handeldata["mal"]:
		ut.append({"id": "handel_" + m["id"], "fakta": m["fakta"]})
	ut.append({"id": "plyndring", "fakta": handeldata["fakta_plyndring"]})
	ut.append({"id": "ting_makt", "fakta": tingdata["fakta"]})
	for s in tingdata["faste"]:
		ut.append({"id": "ting_" + s["id"], "fakta": s["fakta"]})
	for s in tingdata["forslag"]:
		if s.has("fakta"):
			ut.append({"id": "ting_" + s["id"], "fakta": s["fakta"]})
	ut.append({"id": "sagaer", "fakta": sagadata["fakta"]})
	return ut


func _logg(hva: String, antall := 1) -> void:
	logg[hva] = int(logg.get(hva, 0)) + antall


func _finn_kort(id: String) -> void:
	samling[id] = true
	_lagre_samling()


# ---------------------------------------------------------------- priser og ressurser

## En pris kan være et tall (sølv) eller flere ressurser, for eksempel {"solv": 20, "bondene": 10}.
func _kost(v) -> Dictionary:
	if v is Dictionary:
		return v
	if v == null:
		return {}
	return {"solv": int(v)}


## Sølv kan brukes helt opp. Støtte (ære, ætten, bøndene, gudene) kan ikke brukes ned til null.
func _har_rad(kost: Dictionary) -> bool:
	for k in kost:
		var n := int(kost[k])
		if k == "solv":
			if int(stats["solv"]) < n:
				return false
		elif int(stats.get(k, 0)) <= n:
			return false
	return true


func _betal(kost: Dictionary) -> void:
	var minus := {}
	for k in kost:
		minus[k] = -int(kost[k])
	_endre(minus)


func _endre(effekter: Dictionary) -> void:
	for k in effekter:
		if not stats.has(k):
			continue
		var ny := int(stats[k]) + int(effekter[k])
		stats[k] = maxi(ny, 0) if k == "solv" else clampi(ny, 0, 100)
	_oppdater_topplinje()


func _kost_tekst(kost: Dictionary) -> String:
	var deler := []
	for k in RESSURSER:
		if kost.has(k) and int(kost[k]) > 0:
			deler.append("%d %s" % [int(kost[k]), KOST_NAVN[k]])
	return " og ".join(deler)


func _effekt_tekst(effekter: Dictionary) -> String:
	var deler := []
	for nokkel in RESSURSER:
		if not effekter.has(nokkel):
			continue
		var v := int(effekter[nokkel])
		if v == 0:
			continue
		var farge := C_PLUSS if v > 0 else C_ACCENT
		var tegn := "+" if v > 0 else "−"
		deler.append("[color=#%s][b]%s%d %s[/b][/color]" % [farge.to_html(false), tegn, abs(v), NAVN[nokkel]])
	return "     ".join(deler)


## Folk trodde gudene avgjorde om en ferd eller en kamp gikk godt.
## Gunst 50 gir ingen endring, 100 gir +20 prosentpoeng og 0 gir −20.
func _gudebonus() -> float:
	return clampf((float(stats["gudene"]) - 50.0) / 50.0 * GUDER_MAKS_BONUS, -GUDER_MAKS_BONUS, GUDER_MAKS_BONUS)


func _sjanse(grunnsjanse: float) -> float:
	return clampf(grunnsjanse + _gudebonus(), 0.05, 0.95)


func _tapt() -> String:
	for nokkel in STOTTE:
		if int(stats[nokkel]) <= 0:
			return nokkel
	return ""


# ---------------------------------------------------------------- utseende

func _systemfont(navn: PackedStringArray, vekt := 400, kursiv := false) -> SystemFont:
	var f := SystemFont.new()
	f.font_names = navn
	f.font_weight = vekt
	f.font_italic = kursiv
	return f


func _boks(farge: Color, kant := Color(0, 0, 0, 0), radius := 6, pad := 14.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = farge
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.75
	s.content_margin_bottom = pad * 0.75
	if kant.a > 0.0:
		s.set_border_width_all(2)
		s.border_color = kant
	return s


func _lag_tema() -> Theme:
	var serif := PackedStringArray(["Georgia", "Cambria", "serif"])
	font_tekst = _systemfont(serif)
	font_fet = _systemfont(serif, 700)
	font_kursiv = _systemfont(serif, 400, true)
	font_runer = _systemfont(PackedStringArray(["Segoe UI Historic", "Noto Sans Runic", "Segoe UI Symbol"]))

	var t := Theme.new()
	t.default_font = font_tekst
	t.default_font_size = 21
	t.set_color("font_color", "Label", C_INK)

	t.set_stylebox("normal", "Button", _boks(Color("f6efdc"), C_MUTED))
	t.set_stylebox("hover", "Button", _boks(Color("fffaf0"), C_ACCENT))
	t.set_stylebox("pressed", "Button", _boks(C_ACCENT, C_ACCENT))
	t.set_stylebox("disabled", "Button", _boks(Color("d9cfb8"), Color("b8ab90")))
	var fokus := _boks(Color(0, 0, 0, 0), C_ACCENT)
	fokus.draw_center = false
	t.set_stylebox("focus", "Button", fokus)
	t.set_color("font_color", "Button", C_INK)
	t.set_color("font_hover_color", "Button", C_ACCENT)
	t.set_color("font_pressed_color", "Button", C_LYS)
	t.set_color("font_focus_color", "Button", C_INK)
	t.set_color("font_disabled_color", "Button", C_MUTED)

	t.set_stylebox("normal", "LineEdit", _boks(Color("fffaf0"), C_MUTED))
	t.set_stylebox("focus", "LineEdit", _boks(Color("fffaf0"), C_ACCENT))
	t.set_color("font_color", "LineEdit", C_INK)
	t.set_color("font_placeholder_color", "LineEdit", C_MUTED)
	t.set_color("caret_color", "LineEdit", C_ACCENT)

	t.set_font("bold_font", "RichTextLabel", font_fet)
	t.set_font("italics_font", "RichTextLabel", font_kursiv)
	t.set_color("default_color", "RichTextLabel", C_INK)

	t.set_stylebox("panel", "PanelContainer", _boks(C_PANEL, Color(0, 0, 0, 0), 10, 30.0))
	return t


func _bygg_ramme() -> void:
	theme = _lag_tema()
	var bg := ColorRect.new()
	bg.color = C_BG
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var marg := MarginContainer.new()
	marg.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		marg.add_theme_constant_override("margin_" + side, 10)
	add_child(marg)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	marg.add_child(v)

	topplinje = _bygg_topplinje()
	v.add_child(topplinje)

	verden = Verden.new()
	verden.size_flags_vertical = SIZE_EXPAND_FILL
	verden.font_fet = font_fet
	verden.stedsnavn = {}
	for id in steder:
		verden.stedsnavn[id] = steder[id]["navn"]
		if _kan_bygges(id):
			verden.tomt_tekst[id] = "Byggetomt: %s (%s)" % [steder[id]["navn"], _kost_tekst(_kost(steder[id]["pris"]))]
	verden.sted_klikket.connect(_sted_klikket)
	v.add_child(verden)

	# Vinduet som legger seg over gården når en sak, et kart eller et kort vises.
	overlegg = Control.new()
	overlegg.set_anchors_preset(PRESET_FULL_RECT)
	overlegg.mouse_filter = MOUSE_FILTER_STOP
	add_child(overlegg)
	var dim := ColorRect.new()
	dim.color = Color(0.07, 0.05, 0.04, 0.55)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	overlegg.add_child(dim)
	var senter := CenterContainer.new()
	senter.set_anchors_preset(PRESET_FULL_RECT)
	overlegg.add_child(senter)
	var kort := PanelContainer.new()
	senter.add_child(kort)
	rulle = ScrollContainer.new()
	rulle.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rulle.custom_minimum_size = Vector2(820, 100)
	kort.add_child(rulle)
	innhold = VBoxContainer.new()
	innhold.size_flags_horizontal = SIZE_EXPAND_FILL
	innhold.add_theme_constant_override("separation", 18)
	innhold.minimum_size_changed.connect(_tilpass_hoyde)
	rulle.add_child(innhold)


func _tilpass_hoyde() -> void:
	var maks := maxf(size.y - 90.0, 200.0)
	rulle.custom_minimum_size.y = clampf(innhold.get_combined_minimum_size().y, 60.0, maks)


func _bygg_topplinje() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(C_TOPP, Color(0, 0, 0, 0), 8, 12.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	p.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(h)

	var venstre := VBoxContainer.new()
	vinter_etikett = _etikett("", 20, C_GULL, font_fet)
	venstre.add_child(vinter_etikett)
	solv_etikett = _etikett("", 19, C_LYS)
	venstre.add_child(_klikkbar(solv_etikett, "solv"))
	h.add_child(venstre)

	for nokkel in STOTTE:
		var boks := VBoxContainer.new()
		boks.mouse_filter = MOUSE_FILTER_IGNORE
		boks.add_child(_etikett(NAVN[nokkel] + "  (?)", 17, C_LYS))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.mouse_filter = MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2(140, 16)
		bar.max_value = 100
		bar.add_theme_stylebox_override("background", _boks(Color("4a3f35"), Color(0, 0, 0, 0), 4, 0.0))
		boks.add_child(bar)
		h.add_child(_klikkbar(boks, nokkel))
		stat_barer[nokkel] = bar

	neste_knapp = _knapp("Neste vinter  ›", _neste_vinter, true)
	neste_knapp.custom_minimum_size = Vector2(180, 46)
	neste_knapp.disabled = true
	neste_knapp.add_theme_stylebox_override("disabled", _boks(Color("4a4038"), Color("5a4f45")))
	neste_knapp.add_theme_color_override("font_disabled_color", Color("8a7d6c"))
	h.add_child(neste_knapp)

	var rad := HBoxContainer.new()
	rad.add_theme_constant_override("separation", 10)
	v.add_child(rad)
	trell_knapp = _liten_knapp("Trellene", _vis_treller)
	skip_knapp = _liten_knapp("Skipet: handel og tokt", _vis_skip)
	ting_knapp = _liten_knapp("Kall inn tinget", _vis_tinget)
	for b in [trell_knapp, skip_knapp, ting_knapp]:
		rad.add_child(b)
	hint = _etikett("", 17, C_GULL, font_kursiv)
	hint.size_flags_horizontal = SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rad.add_child(hint)
	p.visible = false
	return p


## Gjør en del av topplinjen klikkbar, slik at den åpner infoboksen om ressursen.
func _klikkbar(node: Control, nokkel: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(Color(1, 1, 1, 0), Color(0, 0, 0, 0), 6, 6.0))
	p.mouse_filter = MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	p.tooltip_text = "Klikk for å lese om " + NAVN[nokkel].to_lower()
	p.add_child(node)
	p.gui_input.connect(_ressurs_klikk.bind(nokkel))
	p.mouse_entered.connect(func(): p.add_theme_stylebox_override("panel", _boks(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 6, 6.0)))
	p.mouse_exited.connect(func(): p.add_theme_stylebox_override("panel", _boks(Color(1, 1, 1, 0), Color(0, 0, 0, 0), 6, 6.0)))
	return p


func _ressurs_klikk(e: InputEvent, nokkel: String) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and skjerm == "verden":
		_vis_ressurs(nokkel)


func _liten_knapp(txt: String, handling: Callable) -> Button:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", 17)
	b.custom_minimum_size.y = 38
	b.pressed.connect(_topp_handling.bind(handling))
	return b


## Knappene i topplinjen virker bare når ingen vinduer er åpne over gården.
func _topp_handling(handling: Callable) -> void:
	if skjerm == "verden":
		handling.call()


func _oppdater_topplinje() -> void:
	vinter_etikett.text = "Vinter %d av %d" % [min(vinter, ANTALL_VINTRE), ANTALL_VINTRE]
	solv_etikett.text = "Sølv: %d  (?)" % stats["solv"]
	for nokkel in STOTTE:
		var bar: ProgressBar = stat_barer[nokkel]
		var verdi: int = stats[nokkel]
		var farge := C_ACCENT if verdi < 25 else C_GULL
		bar.add_theme_stylebox_override("fill", _boks(farge, Color(0, 0, 0, 0), 4, 0.0))
		create_tween().tween_property(bar, "value", verdi, 0.4)
	trell_knapp.text = "Trellene (%d)" % treller.size()
	skip_knapp.disabled = not bygget.has("naustet")
	skip_knapp.tooltip_text = "Bygg naustet for å få et skip." if skip_knapp.disabled else ""
	ting_knapp.text = "Tinget (brukt i år)" if ting_brukt else "Kall inn tinget"


func _oppdater_hint(forst := "") -> void:
	var tekst := ""
	if aktive.is_empty():
		neste_knapp.disabled = false
		tekst = "Ingen flere saker. Bygg (+), bruk skipet eller tinget – eller trykk «Neste vinter»."
	else:
		var hvem := "To personer venter" if aktive.size() == 2 else "Én person venter"
		if aktive.size() > 2:
			hvem = "%d personer venter" % aktive.size()
		tekst = hvem + " på deg (!). Klikk på ressursene øverst for å lese om dem."
	hint.text = forst + tekst


# ---------------------------------------------------------------- byggeklosser

func _etikett(txt: String, storrelse := 21, farge := C_INK, font: Font = null) -> Label:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", storrelse)
	l.add_theme_color_override("font_color", farge)
	if font:
		l.add_theme_font_override("font", font)
	return l


func _avsnitt(txt: String, storrelse := 21, farge := C_INK, font: Font = null) -> Label:
	var l := _etikett(txt, storrelse, farge, font)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _rik(bb: String, storrelse := 21) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.size_flags_horizontal = SIZE_EXPAND_FILL
	for navn in ["normal_font_size", "bold_font_size", "italics_font_size"]:
		r.add_theme_font_size_override(navn, storrelse)
	r.text = bb
	return r


func _knapp(txt: String, handling: Callable, sentrert := false) -> Button:
	var b := Button.new()
	b.text = txt
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER if sentrert else HORIZONTAL_ALIGNMENT_LEFT
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size.y = 52
	b.pressed.connect(handling)
	return b


## Knapp som er grå fordi spilleren ikke har råd, med forklaring i teksten.
func _deaktiver(b: Button, grunn: String) -> void:
	b.disabled = true
	b.text = grunn


func _overskrift(liten: String, stor: String) -> void:
	if liten != "":
		innhold.add_child(_etikett(liten, 18, C_MUTED, font_fet))
	innhold.add_child(_etikett(stor, 34, C_ACCENT, font_fet))


func _tilbake_knapp(tekst := "Tilbake til gården") -> Button:
	var b := _knapp(tekst, _tilbake_til_garden, true)
	innhold.add_child(b)
	return b


## Tømmer vinduet over gården og viser det.
func _tom_innhold(navn: String) -> void:
	skjerm = navn
	overlegg.visible = true
	for c in innhold.get_children():
		innhold.remove_child(c)
		c.queue_free()
	rulle.scroll_vertical = 0
	overlegg.modulate.a = 0.0
	create_tween().tween_property(overlegg, "modulate:a", 1.0, 0.2)
	_tilpass_hoyde.call_deferred()


func _lukk_vindu() -> void:
	overlegg.visible = false
	skjerm = "verden"


func _tilbake_til_garden() -> void:
	var tapt := _tapt()
	if tapt != "":
		_vis_slutt(tapt)
		return
	_lukk_vindu()
	_oppdater_hint()


func _faktakort(fakta: Dictionary, ny: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(C_FAKTA, C_GULL, 8, 22.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(_etikett("KUNNSKAPSKORT · NYTT!" if ny else "KUNNSKAPSKORT", 16, C_ACCENT, font_fet))
	v.add_child(_etikett(fakta["tittel"], 25, C_INK, font_fet))
	v.add_child(_avsnitt(fakta["tekst"], 20))
	v.add_child(_avsnitt("Kilde: " + fakta["kilde"], 17, C_MUTED, font_kursiv))
	if fakta.has("lenker"):
		v.add_child(_lenker(fakta["lenker"]))
	return p


## Viser kortet og legger det i samlingen.
func _vis_kort(id: String, fakta: Dictionary) -> void:
	var ny := not samling.has(id)
	_finn_kort(id)
	innhold.add_child(_faktakort(fakta, ny))


## Klikkbare lenker som åpnes i nettleseren, slik at kildene kan sjekkes.
func _lenker(lenker: Array) -> RichTextLabel:
	var linjer := ["[b]Les mer og sjekk kilden:[/b]"]
	for l in lenker:
		linjer.append("[url=%s][color=#%s]› %s[/color][/url]" % [l["url"], C_ACCENT.to_html(false), l["tekst"]])
	var r := _rik("\n".join(linjer), 17)
	r.meta_clicked.connect(func(url): OS.shell_open(str(url)))
	r.mouse_default_cursor_shape = CURSOR_POINTING_HAND
	return r


func _til_runer(tekst: String) -> String:
	var t := tekst.to_lower().replace("th", "þ")
	var ut := ""
	for tegn in t:
		if RUNER.has(tegn):
			ut += RUNER[tegn]
		elif tegn == " " or tegn == "-":
			ut += "᛫"
	return ut


# ---------------------------------------------------------------- start og vintre

func _vis_start() -> void:
	topplinje.visible = false
	aktive = []
	verden.saker = aktive
	_tom_innhold("start")
	innhold.add_child(_etikett(_til_runer("høvdingen"), 30, C_MUTED, font_runer))
	innhold.add_child(_etikett("HØVDINGEN", 52, C_ACCENT, font_fet))
	innhold.add_child(_avsnitt("Vestlandet, år 980. Den gamle høvdingen er død, og nå er det du som skal lede gården og bygda.", 23, C_INK, font_kursiv))
	innhold.add_child(_rik(
		"I [b]%d vintre[/b] skal du ta de avgjørelsene en vikinghøvding måtte ta. Folk kommer til gården med saker om treller, ekteskap, hevn, gudene og ære. Du ser dem som [b]røde merker[/b] ved bygningene.\n\n" % ANTALL_VINTRE
		+ "Bygg ut gården, send skipet på handel eller tokt, og vinn støtte på [b]tinget[/b]. Hold [b]ætten[/b], [b]bøndene[/b] og [b]gudene[/b] fornøyde, og vinn [b]ære[/b]. Faller én av dem til null, er det slutt.\n\n"
		+ "Underveis får du [b]kunnskapskort[/b] om hvordan det faktisk var i vikingtiden. Klarer du å samle alle %d?" % _alle_kort().size()))

	var navnefelt := LineEdit.new()
	navnefelt.placeholder_text = "Skriv navnet ditt"
	navnefelt.max_length = 20
	navnefelt.custom_minimum_size.y = 52
	innhold.add_child(navnefelt)

	var start := _knapp("Bli høvding", func(): _start_spill(navnefelt.text), true)
	start.disabled = true
	navnefelt.text_changed.connect(func(t: String): start.disabled = t.strip_edges().is_empty())
	navnefelt.text_submitted.connect(_navn_sendt)
	innhold.add_child(start)
	innhold.add_child(_knapp("Se kunnskapskortene dine (%d av %d)" % [_antall_funnet(), _alle_kort().size()], _vis_samling, true))
	navnefelt.grab_focus.call_deferred()


func _antall_funnet() -> int:
	var n := 0
	for k in _alle_kort():
		if samling.has(k["id"]):
			n += 1
	return n


func _navn_sendt(navn: String) -> void:
	if not navn.strip_edges().is_empty():
		_start_spill(navn)


func _start_spill(navn: String) -> void:
	hovding_navn = navn.strip_edges().capitalize()
	stats = {"solv": 25, "aere": 50, "gudene": 50, "aetten": 50, "bondene": 50}
	flagg = {}
	bygget = {}
	kontakter = {}
	fiender = 0
	skip_borte_til = 0
	logg = {}
	treller = []
	for t in trelldata["start"]:
		treller.append(t.duplicate())
	verden.stats = stats
	verden.flagg = flagg
	verden.bygget = bygget
	ko = hendelser.duplicate()
	ko.shuffle()
	vinter = 1
	topplinje.visible = true
	_start_vinter()


func _kan_bygges(sted: String) -> bool:
	return steder.get(sted, {}).has("pris")


## Er stedet på gården? Saker på steder som ikke er bygd, dukker ikke opp.
func _finnes(sted: String) -> bool:
	return not _kan_bygges(sted) or bygget.has(sted)


func _har_trell(id: String) -> bool:
	for t in treller:
		if t["id"] == id:
			return true
	return false


func _mulig_sak(h: Dictionary) -> bool:
	if not _finnes(h.get("sted", "langhuset")):
		return false
	if h.has("krever_trell") and not _har_trell(h["krever_trell"]):
		return false
	return true


func _start_vinter() -> void:
	skip_seilt = false
	ting_brukt = false
	for t in treller:
		t["ny"] = false

	# Velg vinterens saker blant dem som passer med gården slik den er nå.
	aktive = []
	for h in ko.duplicate():
		if aktive.size() < SAKER_PER_VINTER and _mulig_sak(h):
			aktive.append(h)
			ko.erase(h)
	for sak in tingdata["faste"]:
		if int(sak["vinter"]) == vinter:
			aktive.append({"tingsak": sak, "sted": "tingstedet", "person": "Tinget: " + sak["tittel"], "tittel": sak["tittel"]})
	# En trell kan ha rømt i løpet av året. Da må høvdingen bestemme seg.
	var rommling := {}
	if vinter > 1:
		for t in treller.duplicate():
			if randf() < float(t.get("flukt", trelldata["flukt"])):
				rommling = t
				treller.erase(t)
				aktive.append({"rommling": t, "sted": "skogen", "person": t["navn"] + " har rømt", "tittel": t["navn"] + " har rømt"})
				_logg("romt")
				break
	verden.saker = aktive
	neste_knapp.disabled = true

	# Inntekt: åkrene påvirkes av året (gudenes gunst), resten gir fast inntekt.
	var aaret := "Avlingen var middels god, og bøndene betalte skatten sin."
	var per_aaker := 5
	if stats["gudene"] >= 65:
		per_aaker = 8
		aaret = "Et rikt år! Kornet sto høyt, og fisket var godt. Bøndene sier gudene er med deg."
	elif stats["gudene"] < 30:
		per_aaker = 2 if bygget.has("buret") else 0
		aaret = "Uår. Kornet råtnet på åkeren. Folk hvisker at gudene er vrede."
		if bygget.has("buret"):
			aaret += " Heldigvis hadde du lagret korn i buret."
	var deler := []
	var aakre := 2 if bygget.has("nyaakeren") else 1
	deler.append(["Åkrene" if aakre > 1 else "Åkeren", per_aaker * aakre])
	for id in steder:
		if bygget.has(id) and steder[id].has("inntekt"):
			deler.append([steder[id]["navn"], int(steder[id]["inntekt"])])
	if not treller.is_empty():
		deler.append(["Trellenes arbeid (%d treller)" % treller.size(), _trellearbeid()])
	for id in kontakter:
		deler.append(["Handel med " + _mal(id)["navn"], int(kontakter[id])])
	if flagg.has("marked"):
		deler.append(["Markedet i bygda", 3])

	var hevn := false
	if vinter == 1:
		deler = []
		aaret = "Du har overtatt gården og høysetet etter den gamle høvdingen. Gården er liten, men det finnes byggetomter (+) der du kan bygge den ut."
	elif fiender > 0 and randf() < minf(0.15 * fiender, 0.7):
		hevn = true
	var sum := 0
	for d in deler:
		sum += d[1]
	stats["solv"] += sum
	# Gudene glemmer fort: Uten nye offer synker gunsten.
	var forfall := 0
	if vinter > 1:
		forfall = GUDER_FORFALL_MED_OFFERLUND if bygget.has("offerlunden") else GUDER_FORFALL
		if flagg.has("kors"):
			forfall += GUDER_FORFALL_KRISTEN
		_endre({"gudene": -forfall})
	var hevn_tap := {"solv": -10, "bondene": -10, "aetten": -5}
	if hevn:
		_endre(hevn_tap)
		fiender = maxi(fiender - 2, 0)
		_logg("hevntokt")
	_oppdater_topplinje()

	_tom_innhold("vinter")
	_overskrift("VINTER %d AV %d" % [vinter, ANTALL_VINTRE], "Et nytt år går mot slutten")
	innhold.add_child(_avsnitt(aaret))
	if not deler.is_empty():
		var linjer := []
		for d in deler:
			linjer.append("%s: [b]+%d sølv[/b]" % d)
		innhold.add_child(_rik("\n".join(linjer) + "\n[color=#%s][b]Til sammen: +%d sølv[/b][/color]" % [C_PLUSS.to_html(false), sum]))
	if forfall > 0:
		var hvorfor := "Gudene krever nye offer hvert år."
		if bygget.has("offerlunden"):
			hvorfor += " Offerlunden hjelper, for der blir det ofret jevnlig."
		else:
			hvorfor += " Med en offerlund ville gunsten sunket langsommere."
		if flagg.has("kors"):
			hvorfor += " Mange tror gudene er sinte fordi du har sluppet inn den kristne troen."
		innhold.add_child(_rik(hvorfor + "  " + _effekt_tekst({"gudene": -forfall}), 19))
	if hevn:
		innhold.add_child(_etikett("Hevntokt!", 26, C_ACCENT, font_fet))
		innhold.add_child(_avsnitt("En natt kom fremmede skip inn fjorden. De brente et naust, drepte to menn og tok med seg sølv og dyr. Fiendene du har skaffet deg på tokt, glemmer ikke.", 21))
		innhold.add_child(_rik(_effekt_tekst(hevn_tap)))
	if not rommling.is_empty():
		innhold.add_child(_etikett(rommling["navn"] + " er borte!", 26, C_ACCENT, font_fet))
		innhold.add_child(_avsnitt("En morgen var plassen til %s i trellehuset tom. Noen så spor mot skogen." % rommling["navn"], 21))
	var venter := "Nå venter det folk på gården som vil snakke med deg." if not aktive.is_empty() else "Ingen kommer med saker denne vinteren. Kanskje gården må bygges ut før nye folk kommer hit?"
	innhold.add_child(_avsnitt(venter, 21, C_MUTED, font_kursiv))
	innhold.add_child(_knapp("Gå ut på gården", _tilbake_til_garden, true))


func _neste_vinter() -> void:
	if not aktive.is_empty() or skjerm != "verden":
		return
	vinter += 1
	if vinter > ANTALL_VINTRE:
		_vis_slutt("")
	else:
		_start_vinter()


# ---------------------------------------------------------------- gården

func _sted_klikket(sted: String) -> void:
	if skjerm != "verden":
		return
	for h in aktive:
		if h.get("sted", "langhuset") == sted:
			if h.has("tingsak"):
				_vis_tingsak(h)
			elif h.has("rommling"):
				_vis_flukt(h)
			else:
				_vis_sak(h)
			return
	if not _finnes(sted):
		_vis_byggetomt(sted)
	elif sted == "trellehuset":
		_vis_treller()
	elif sted == "naustet":
		_vis_skip()
	elif sted == "tingstedet":
		_vis_tinget()
	else:
		_vis_sted(sted)


func _vis_sted(sted: String) -> void:
	if not steder.has(sted):
		return
	_tom_innhold("sted")
	_overskrift("PÅ GÅRDEN", steder[sted]["navn"])
	innhold.add_child(_avsnitt(steder[sted]["tekst"], 21))
	if steder[sted].has("lenker"):
		innhold.add_child(_lenker(steder[sted]["lenker"]))
	_tilbake_knapp()


func _vis_byggetomt(sted: String) -> void:
	var s: Dictionary = steder[sted]
	var pris := _kost(s["pris"])
	_tom_innhold("bygg")
	_overskrift("BYGGETOMT", "Bygg: " + s["navn"])
	innhold.add_child(_avsnitt(s["tekst"], 21))
	innhold.add_child(_rik("[b]Dette får du:[/b] " + s.get("bygg_effekt", ""), 21))
	if s.has("lenker"):
		innhold.add_child(_lenker(s["lenker"]))
	var bygg := _knapp("Bygg – koster " + _kost_tekst(pris), _bygg.bind(sted), true)
	if not _har_rad(pris):
		_deaktiver(bygg, "Du har ikke råd – det koster " + _kost_tekst(pris))
	innhold.add_child(bygg)
	_tilbake_knapp("Ikke nå – tilbake til gården").set_meta("ikke_auto", true)


func _bygg(sted: String) -> void:
	var s: Dictionary = steder[sted]
	_betal(_kost(s["pris"]))
	bygget[sted] = true
	_endre(s.get("effekter", {}))
	verden.puff(sted)
	_lukk_vindu()
	_oppdater_hint("Du har bygd %s! " % s["navn"].to_lower())


func _vis_ressurs(nokkel: String) -> void:
	var r: Dictionary = ressurser.get(nokkel, {})
	if r.is_empty():
		return
	_tom_innhold("ressurs")
	_overskrift("RESSURS · DU HAR NÅ %d" % int(stats[nokkel]), r["navn"])
	innhold.add_child(_etikett("I vikingtiden", 23, C_INK, font_fet))
	innhold.add_child(_avsnitt(r["historisk"], 21))
	innhold.add_child(_etikett("I spillet", 23, C_INK, font_fet))
	innhold.add_child(_avsnitt(r["spill"], 21))
	innhold.add_child(_lenker(r["lenker"]))
	_tilbake_knapp()


# ---------------------------------------------------------------- saker

func _vis_sak(h: Dictionary) -> void:
	_tom_innhold("sak")
	_overskrift("VINTER %d · %s" % [vinter, steder.get(h.get("sted", ""), {}).get("navn", "").to_upper()], h["tittel"])
	innhold.add_child(_etikett(h["person"], 19, C_MUTED, font_kursiv))
	innhold.add_child(_avsnitt(h["tekst"], 22))
	innhold.add_child(_etikett("Hva gjør du?", 20, C_INK, font_fet))

	for valg in h["valg"]:
		var kost := _kostnad(valg)
		var tekst: String = valg["tekst"]
		if not kost.is_empty():
			tekst += "   (koster " + _kost_tekst(kost) + ")"
		var b := _knapp(tekst, _velg.bind(h, valg))
		if not _har_rad(kost):
			_deaktiver(b, valg["tekst"] + "   (du har ikke råd – koster " + _kost_tekst(kost) + ")")
		innhold.add_child(b)
	_tilbake_knapp("Tenk på det – tilbake til gården").set_meta("ikke_auto", true)


func _kostnad(valg: Dictionary) -> Dictionary:
	if valg.has("kostnad"):
		return _kost(valg["kostnad"])
	var solv := int(valg.get("effekter", {}).get("solv", 0))
	return {"solv": -solv} if solv < 0 else {}


func _velg(h: Dictionary, valg: Dictionary) -> void:
	var utfall: Dictionary = valg
	var terning := ""
	if valg.has("sjanse"):
		if randf() < _sjanse(float(valg["sjanse"])):
			utfall = valg["suksess"]
			terning = "Lykken var med deg."
		else:
			utfall = valg["fiasko"]
			terning = "Lykken var ikke med deg."

	var effekter: Dictionary = utfall.get("effekter", {})
	_endre(effekter)
	if utfall.has("flagg"):
		flagg[utfall["flagg"]] = true
	if valg.has("frigi_trell"):
		for t in treller.duplicate():
			if t["id"] == valg["frigi_trell"]:
				treller.erase(t)
	aktive.erase(h)
	_oppdater_topplinje()

	_tom_innhold("resultat")
	innhold.add_child(_etikett(h["tittel"], 30, C_ACCENT, font_fet))
	innhold.add_child(_avsnitt("Du valgte: " + valg["tekst"], 20, C_MUTED, font_kursiv))
	if terning != "":
		innhold.add_child(_etikett(terning, 20, C_INK, font_fet))
	innhold.add_child(_avsnitt(utfall["resultat"], 22))
	var eff := _effekt_tekst(effekter)
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	_vis_kort(h["id"], h["fakta"])
	_tilbake_knapp()


# ---------------------------------------------------------------- treller

func _vis_treller() -> void:
	_tom_innhold("treller")
	_overskrift("TRELLEHUSET", "Trellene på gården")
	if treller.is_empty():
		innhold.add_child(_avsnitt("Du eier ingen treller nå.", 21))
	else:
		innhold.add_child(_avsnitt("Du eier %d mennesker. Arbeidet deres gir gården %d sølv hver vinter. Selger du noen, får du sølv med en gang, men mister arbeidet for resten av livet ditt som høvding." % [treller.size(), _trellearbeid()], 21))
	for t in treller:
		innhold.add_child(_trellkort(t))
	_vis_kort("treller", trelldata["fakta"])
	_vis_kort("trell_rettigheter", trelldata["fakta_rettigheter"])
	innhold.add_child(_knapp("Les om trellehuset", _vis_sted.bind("trellehuset"), true))
	_tilbake_knapp()


func _trellkort(t: Dictionary) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(Color("e3d8bd"), Color("b8ab90"), 8, 20.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var navn: String = t["navn"] + ("   · NY PÅ GÅRDEN" if t.get("ny", false) else "")
	v.add_child(_etikett(navn, 24, C_INK, font_fet))
	v.add_child(_etikett("%d år · %s" % [int(t["alder"]), t["opphav"]], 18, C_MUTED, font_kursiv))
	v.add_child(_avsnitt(t["historie"], 20))
	v.add_child(_rik("Arbeid: [b]+%d sølv[/b] hver vinter     Salgsverdi: [b]%d sølv[/b]" % [_arbeid(t), int(t["verdi"])], 17))
	var rad := HBoxContainer.new()
	rad.add_theme_constant_override("separation", 10)
	var selg := _knapp("Selg for %d sølv" % int(t["verdi"]), _selg_trell.bind(t), true)
	var fri := _knapp("Gi %s friheten" % t["navn"], _frigi_trell.bind(t), true)
	for b in [selg, fri]:
		b.size_flags_horizontal = SIZE_EXPAND_FILL
		b.custom_minimum_size.y = 44
		rad.add_child(b)
	v.add_child(rad)
	return p


func _arbeid(t: Dictionary) -> int:
	return int(t.get("arbeid", trelldata["arbeid"]))


func _trellearbeid() -> int:
	var sum := 0
	for t in treller:
		sum += _arbeid(t)
	return sum


func _vis_flukt(h: Dictionary) -> void:
	var t: Dictionary = h["rommling"]
	_tom_innhold("flukt")
	_overskrift("VINTER %d · SKOGEN" % vinter, t["navn"] + " har rømt")
	innhold.add_child(_avsnitt(t["historie"], 20, C_MUTED, font_kursiv))
	innhold.add_child(_avsnitt("Sporene går inn i skogen og videre mot fjellet. Bøndene venter på hva du gjør: Lar du en trell slippe unna, kan flere få lyst til å prøve. Men det er langt å jakte, og ingen vet hva som venter.", 21))
	innhold.add_child(_etikett("Hva gjør du?", 20, C_INK, font_fet))
	var jakt_kost := {"bondene": 5}
	var jakt := _knapp("Send menn etter %s (koster %s – omtrent 60 %% sjanse)" % [t["navn"], _kost_tekst(jakt_kost)], _flukt_valg.bind(h, "jakt"))
	if not _har_rad(jakt_kost):
		_deaktiver(jakt, "Send menn etter %s (du har ikke råd – koster %s)" % [t["navn"], _kost_tekst(jakt_kost)])
	innhold.add_child(jakt)
	innhold.add_child(_knapp("La %s gå" % t["navn"], _flukt_valg.bind(h, "slipp")))
	innhold.add_child(_knapp("Kunngjør på tinget at %s er fri – ingen skal jakte" % t["navn"], _flukt_valg.bind(h, "fri")))


func _flukt_valg(h: Dictionary, valg: String) -> void:
	var t: Dictionary = h["rommling"]
	aktive.erase(h)
	var tekst := ""
	var effekter := {}
	match valg:
		"jakt":
			_betal({"bondene": 5})
			if randf() < 0.6:
				t["ny"] = false
				treller.append(t)
				_logg("fanget_igjen")
				tekst = "Etter tre dager fant mennene %s i en hule ved fjellet, sulten og forfrosset. %s ble ført tilbake til gården med hendene bundet. De andre trellene så det." % [t["navn"], t["navn"]]
			else:
				tekst = "Mennene lette i fem dager, men fant bare et brent bål ved fjellet. %s er borte. Noen sier %s kom seg til en handelsplass og om bord på et skip." % [t["navn"], t["navn"]]
				effekter = {"aere": -5}
		"slipp":
			tekst = "Du sender ingen etter %s. Gården mister arbeidskraften, og noen bønder mumler om at en høvding som ikke holder på eiendommen sin, er svak." % t["navn"]
			effekter = {"bondene": -5}
		"fri":
			_logg("frigitt")
			tekst = "Du kunngjør på tinget at %s er en fri løysing, og at ingen skal jakte. Noen kaller deg gavmild, andre mener du gir de andre trellene farlige ideer." % t["navn"]
			effekter = {"aere": 5, "bondene": -5}
	_endre(effekter)
	_tom_innhold("flukt_resultat")
	_overskrift("SKOGEN", t["navn"])
	innhold.add_child(_avsnitt(tekst, 21))
	var eff := _effekt_tekst(effekter)
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	_vis_kort("trell_rettigheter", trelldata["fakta_rettigheter"])
	_tilbake_knapp()


func _selg_trell(t: Dictionary) -> void:
	treller.erase(t)
	_logg("solgt")
	_endre({"solv": int(t["verdi"])})
	_tom_innhold("trell_solgt")
	_overskrift("SOLGT", t["navn"])
	innhold.add_child(_avsnitt("Du selger %s til en handelsmann for %d sølv. Samme kveld blir %s ført om bord på en knarr som skal sørover, til markedene i Hedeby og videre. Du ser aldri %s igjen." % [t["navn"], int(t["verdi"]), t["navn"], t["navn"]], 21))
	innhold.add_child(_avsnitt("Bak hvert salg på trellemarkedene sto et menneske med et navn og en historie, som %s." % t["navn"], 20, C_MUTED, font_kursiv))
	innhold.add_child(_rik(_effekt_tekst({"solv": int(t["verdi"])})))
	innhold.add_child(_knapp("Tilbake til trellene", _vis_treller, true))
	_tilbake_knapp()


func _frigi_trell(t: Dictionary) -> void:
	treller.erase(t)
	_logg("frigitt")
	_endre({"aere": 5})
	_tom_innhold("trell_fri")
	_overskrift("FRIGITT", t["navn"])
	innhold.add_child(_avsnitt("Du holder et gilde og gir %s friheten foran vitner. Nå er %s en løysing, en frigitt. Men en løysing hadde fortsatt lavere status enn de frie bøndene, og gården mister arbeidskraften." % [t["navn"], t["navn"]], 21))
	innhold.add_child(_rik(_effekt_tekst({"aere": 5}) + "     [color=#%s]Du mister %d sølv i inntekt hver vinter.[/color]" % [C_MUTED.to_html(false), _arbeid(t)]))
	innhold.add_child(_knapp("Tilbake til trellene", _vis_treller, true))
	_tilbake_knapp()


## Henter en fange fra et tokt eller markedet. Hver person finnes bare én gang på gården.
func _ny_trell(opphav: String) -> Dictionary:
	var mulige := []
	for t in trelldata["fanger"].get(opphav, []):
		if not _har_trell(t["id"]):
			mulige.append(t)
	if mulige.is_empty():
		return {}
	var ny: Dictionary = mulige.pick_random().duplicate()
	ny["ny"] = true
	return ny


# ---------------------------------------------------------------- skipet: handel og tokt

func _mal(id: String) -> Dictionary:
	for m in handeldata["mal"]:
		if m["id"] == id:
			return m
	return {}


func _skip_hindring() -> String:
	if not bygget.has("naustet"):
		return "Du har ikke skip ennå. Bygg naustet først."
	if flagg.has("skip_tapt"):
		return "Skipet ditt gikk tapt. Bygg et nytt før du kan seile igjen."
	if skip_borte_til >= vinter:
		return "Skipet er fortsatt på den lange reisen østover, og kommer hjem neste vinter."
	if skip_seilt:
		return "Skipet har allerede vært ute denne vinteren. Neste vinter kan det seile igjen."
	return ""


func _mal_kost(m: Dictionary) -> Dictionary:
	var kost := _kost(m["kost"]).duplicate()
	if m["type"] == "tokt" and flagg.has("felles_tokt"):
		kost.erase("bondene")
	return kost


func _vis_skip() -> void:
	if not bygget.has("naustet"):
		return
	_tom_innhold("skip")
	_overskrift("NAUSTET", "Handel og tokt")
	innhold.add_child(_avsnitt("Velg et mål på kartet. Handel gir mindre sølv, men tryggere reiser og fast inntekt hver vinter etterpå. Tokt gir rask rikdom, ære og fanger, men skaper fiender som kan komme for å hevne seg.", 20))
	var status := []
	if not kontakter.is_empty():
		var navn := []
		for id in kontakter:
			navn.append("%s (+%d)" % [_mal(id)["navn"], int(kontakter[id])])
		status.append("[b]Faste handelsforbindelser:[/b] " + ", ".join(navn))
	if fiender > 0:
		status.append("[color=#%s][b]Fiender: %d[/b] – det er fare for hevntokt mot gården.[/color]" % [C_ACCENT.to_html(false), fiender])
	if flagg.has("felles_tokt"):
		status.append("[b]Tinget har vedtatt felles tokt:[/b] Neste tokt får mannskap fra nabobygdene.")
	if not status.is_empty():
		innhold.add_child(_rik("\n".join(status), 19))
	var hindring := _skip_hindring()
	if hindring != "":
		innhold.add_child(_avsnitt(hindring, 20, C_ACCENT, font_fet))
	if flagg.has("skip_tapt"):
		var kost := {"solv": 15, "bondene": 5}
		var b := _knapp("Bygg nytt skip – koster " + _kost_tekst(kost), _nytt_skip.bind(kost), true)
		if not _har_rad(kost):
			_deaktiver(b, "Du har ikke råd til nytt skip – det koster " + _kost_tekst(kost))
		innhold.add_child(b)

	var kart := Kart.new()
	kart.mal = handeldata["mal"]
	kart.hjem = handeldata["hjem"]
	kart.kontakter = kontakter
	kart.font = font_tekst
	kart.font_fet = font_fet
	kart.valgt = valgt_mal
	kart.mal_valgt.connect(_velg_mal)
	innhold.add_child(kart)
	mal_detaljer = VBoxContainer.new()
	mal_detaljer.add_theme_constant_override("separation", 12)
	innhold.add_child(mal_detaljer)
	_vis_maldetaljer()
	_tilbake_knapp().set_meta("ikke_auto", true)


func _gudetekst() -> String:
	var prosent := int(round(_gudebonus() * 100.0))
	if prosent > 0:
		return "gudene er med deg: +%d %%" % prosent
	if prosent < 0:
		return "gudene er imot deg: %d %%" % prosent
	return "gudene er verken for eller imot deg"


func _nytt_skip(kost: Dictionary) -> void:
	_betal(kost)
	flagg.erase("skip_tapt")
	_vis_skip()


func _velg_mal(id: String) -> void:
	valgt_mal = id
	_vis_maldetaljer()


func _vis_maldetaljer() -> void:
	for c in mal_detaljer.get_children():
		mal_detaljer.remove_child(c)
		c.queue_free()
	var m := _mal(valgt_mal)
	if m.is_empty():
		mal_detaljer.add_child(_avsnitt("Klikk på et mål på kartet for å se mer.", 20, C_MUTED, font_kursiv))
		return
	var tokt: bool = m["type"] == "tokt"
	mal_detaljer.add_child(_etikett("TOKT" if tokt else "HANDELSFERD", 17, C_ACCENT if tokt else C_GULL, font_fet))
	mal_detaljer.add_child(_etikett(m["navn"], 28, C_INK, font_fet))
	mal_detaljer.add_child(_avsnitt(m["tekst"], 20))
	var kost := _mal_kost(m)
	var linjer := [
		"[b]Pris:[/b] " + (_kost_tekst(kost) if not kost.is_empty() else "ingenting"),
		"[b]Sjanse for å lykkes:[/b] %d %%  [color=#%s](%s)[/color]" % [int(round(_sjanse(float(m["sjanse"])) * 100.0)), C_MUTED.to_html(false), _gudetekst()],
		"[b]Gevinst hvis det går bra:[/b] " + _effekt_tekst(m["gevinst"]),
	]
	if m.has("kontakt"):
		linjer.append("[b]Fast handel:[/b] +%d sølv hver vinter etterpå" % int(m["kontakt"]))
	if m.get("trellmarked", false):
		linjer.append("[b]Trellemarked:[/b] Her selges også mennesker.")
	if tokt:
		linjer.append("[b]Fanger:[/b] Du tar med deg mennesker hjem som treller.")
		linjer.append("[color=#%s][b]Fiender: +%d[/b] – de kan komme for å hevne seg.[/color]" % [C_ACCENT.to_html(false), int(m.get("fiender", 0))])
		linjer.append("[color=#%s][b]Hvis det går galt:[/b] %s, og %d %% fare for å miste skipet.[/color]" % [C_ACCENT.to_html(false), _effekt_tekst(m.get("fiasko_effekter", {})).replace("     ", ", "), int(round(float(m.get("skip_tap", 0.0)) * 100.0))])
		if flagg.has("felles_tokt"):
			linjer.append("[i]Nabobygdene stiller mannskap, så toktet koster ikke støtte fra bøndene.[/i]")
	if m["id"] == "bulgar":
		linjer.append("[i]Reisen tar så lang tid at skipet er borte også neste vinter.[/i]")
	mal_detaljer.add_child(_rik("\n".join(linjer), 19))
	var b := _knapp("Seil til " + m["navn"], _seil.bind(m["id"]), true)
	var hindring := _skip_hindring()
	if hindring != "":
		_deaktiver(b, hindring)
	elif not _har_rad(kost):
		_deaktiver(b, "Du har ikke råd – reisen koster " + _kost_tekst(kost))
	mal_detaljer.add_child(b)


func _seil(id: String) -> void:
	var m := _mal(id)
	var kost := _mal_kost(m)
	var tokt: bool = m["type"] == "tokt"
	_betal(kost)
	if tokt and flagg.has("felles_tokt"):
		flagg.erase("felles_tokt")
	skip_seilt = true
	if id == "bulgar":
		skip_borte_til = vinter + 1

	var lykkes := randf() < _sjanse(float(m["sjanse"]))
	var effekter: Dictionary = m["gevinst"] if lykkes else m.get("fiasko_effekter", {})
	_endre(effekter)
	var fange := {}
	var skip_mistet := false
	if lykkes:
		if m.has("kontakt"):
			kontakter[id] = maxi(int(kontakter.get(id, 0)), int(m["kontakt"]))
		if m.has("fanger"):
			fange = _ny_trell(m["fanger"])
			if not fange.is_empty():
				treller.append(fange)
				_logg("fanget")
		fiender += int(m.get("fiender", 0))
	else:
		if tokt:
			fiender += 1
		if randf() < float(m.get("skip_tap", 0.0)):
			skip_mistet = true
			flagg["skip_tapt"] = true
	if tokt:
		_logg("tokt_ok" if lykkes else "tokt_feil")
		if lykkes:
			_logg("tokt_" + id)
	else:
		_logg("handel")
		if lykkes:
			_logg("handel_" + id)
	_oppdater_topplinje()

	_tom_innhold("reise")
	_overskrift("HJEMKOMST", m["navn"])
	innhold.add_child(_etikett("Reisen lyktes." if lykkes else "Reisen gikk galt.", 22, C_PLUSS if lykkes else C_ACCENT, font_fet))
	innhold.add_child(_avsnitt(m["suksess"] if lykkes else m["fiasko"], 21))
	var eff := _effekt_tekst(effekter)
	if not kost.is_empty():
		innhold.add_child(_rik("[color=#%s]Reisen kostet " % C_MUTED.to_html(false) + _kost_tekst(kost) + ".[/color]", 18))
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	if skip_mistet:
		innhold.add_child(_avsnitt("Skipet gikk tapt. De som overlevde, kom seg hjem med andre skip. Du må bygge et nytt skip før du kan seile igjen.", 21, C_ACCENT, font_fet))
	if lykkes and m.has("kontakt"):
		innhold.add_child(_rik("[b]Ny fast handelsforbindelse:[/b] +%d sølv hver vinter." % int(m["kontakt"]), 19))
	if not fange.is_empty():
		innhold.add_child(_etikett("Fange tatt med hjem", 22, C_ACCENT, font_fet))
		innhold.add_child(_trellkort(fange))
	if tokt:
		innhold.add_child(_rik("[color=#%s][b]Fiender nå: %d[/b][/color]" % [C_ACCENT.to_html(false), fiender], 19))
	if lykkes and m.get("trellmarked", false):
		var paa_marked := _ny_trell("marked")
		if not paa_marked.is_empty():
			var pris := int(paa_marked["verdi"]) + 4
			innhold.add_child(_etikett("På trellemarkedet", 22, C_INK, font_fet))
			innhold.add_child(_avsnitt("Mellom tønner og skinn står det mennesker til salgs. En av dem er %s." % paa_marked["navn"], 20))
			innhold.add_child(_trellkort_uten_knapper(paa_marked))
			var kjop := _knapp("Kjøp %s for %d sølv" % [paa_marked["navn"], pris], _kjop_trell.bind(paa_marked, pris), true)
			if int(stats["solv"]) < pris:
				_deaktiver(kjop, "Du har ikke råd til å kjøpe (%d sølv)" % pris)
			innhold.add_child(kjop)
	_vis_kort("handel_" + id, m["fakta"])
	if tokt:
		_vis_kort("plyndring", handeldata["fakta_plyndring"])
	_tilbake_knapp()


func _trellkort_uten_knapper(t: Dictionary) -> PanelContainer:
	var p := _trellkort(t)
	var v: VBoxContainer = p.get_child(0)
	var rad := v.get_child(v.get_child_count() - 1)
	v.remove_child(rad)
	rad.queue_free()
	return p


func _kjop_trell(t: Dictionary, pris: int) -> void:
	_endre({"solv": -pris})
	treller.append(t)
	_logg("kjopt")
	_oppdater_topplinje()
	_tom_innhold("trell_kjopt")
	_overskrift("KJØPT", t["navn"])
	innhold.add_child(_avsnitt("Du betaler %d sølv, og %s blir ført om bord på skipet ditt. Nå arbeider %s på gården din." % [pris, t["navn"], t["navn"]], 21))
	innhold.add_child(_knapp("Se trellene dine", _vis_treller, true))
	_tilbake_knapp()


# ---------------------------------------------------------------- tinget

func _fakta_for_tingsak(sak: Dictionary) -> Array:
	if sak.has("fakta"):
		return ["ting_" + sak["id"], sak["fakta"]]
	# Viser til et annet kort, f.eks. en annen tingsak («leidang») eller en vanlig sak («primsigning»).
	var ref: String = sak.get("fakta_ref", "")
	for k in _alle_kort():
		if k["id"] == "ting_" + ref or k["id"] == ref:
			return [k["id"], k["fakta"]]
	return []


func _vis_tinget() -> void:
	_tom_innhold("ting")
	_overskrift("TINGSTEDET", "Kall inn tinget")
	innhold.add_child(_avsnitt("På tinget møtes de frie mennene i bygda. Her kan du legge fram forslag, men du kan ikke bestemme alene. Du må ha flertallet med deg.", 21))
	innhold.add_child(_rik("Din støtte på tinget er lik støtten fra bøndene: [b]%d[/b]. Du kan øke den ved å bruke [b]ætten[/b], [b]sølv[/b] og [b]æren[/b] din som politisk valuta." % int(stats["bondene"]), 21))
	if ting_brukt:
		innhold.add_child(_avsnitt("Du har allerede kalt inn tinget denne vinteren. Neste vinter kan du prøve igjen.", 20, C_ACCENT, font_fet))
	else:
		innhold.add_child(_etikett("Hvilken sak vil du legge fram?", 21, C_INK, font_fet))
		for f in tingdata["forslag"]:
			var valg: Dictionary = f["valg"][0]
			var b := _knapp("%s   (motstand: %d)" % [f["tittel"], int(valg["motstand"])], _start_ting.bind(f, valg, null))
			innhold.add_child(b)
	_vis_kort("ting_makt", tingdata["fakta"])
	innhold.add_child(_knapp("Les om tingstedet", _vis_sted.bind("tingstedet"), true))
	_tilbake_knapp().set_meta("ikke_auto", true)


func _vis_tingsak(h: Dictionary) -> void:
	var sak: Dictionary = h["tingsak"]
	_tom_innhold("tingsak")
	_overskrift("VINTER %d · TINGET ER KALT INN" % vinter, sak["tittel"])
	innhold.add_child(_etikett(sak["person"], 19, C_MUTED, font_kursiv))
	innhold.add_child(_avsnitt(sak["tekst"], 22))
	innhold.add_child(_rik("Tinget skal stemme. Din støtte er støtten fra bøndene: [b]%d[/b]. Hvilket syn vil du kjempe for?" % int(stats["bondene"]), 20))
	for valg in sak["valg"]:
		innhold.add_child(_knapp("%s   (motstand: %d)" % [valg["tekst"], int(valg["motstand"])], _start_ting.bind(sak, valg, h)))
	_tilbake_knapp("Tenk på det – tilbake til gården").set_meta("ikke_auto", true)


func _start_ting(sak: Dictionary, valg: Dictionary, h) -> void:
	ting_sak = sak
	ting_valg = valg
	ting_h = h
	ting_bonus = 0
	ting_brukte = {}
	_vis_avstemning()


func _ting_stotte() -> int:
	return int(stats["bondene"]) + ting_bonus


func _vis_avstemning() -> void:
	_tom_innhold("avstemning")
	_overskrift("TINGET ER SATT", ting_sak["tittel"])
	# Egne forslag har bare ett valg; da er saksteksten mer forklarende enn knappeteksten.
	var sak_tekst: String = ting_sak["tekst"] if ting_sak["valg"].size() == 1 else "Du kjemper for: " + ting_valg["tekst"]
	innhold.add_child(_avsnitt(sak_tekst, 21, C_INK, font_kursiv))
	var stotte := _ting_stotte()
	var motstand := int(ting_valg["motstand"])
	var vinner := stotte >= motstand
	innhold.add_child(_stemmebar(stotte, motstand))
	var sjanse := _ting_sjanse(stotte, motstand)
	var farge := C_PLUSS if vinner else C_ACCENT
	var dom := "Omtrent [color=#%s][b]%d %% sjanse[/b][/color] for at du vinner." % [farge.to_html(false), sjanse]
	innhold.add_child(_rik("Din støtte: [b]%d[/b]  (bøndene %d + det du har vunnet %d)     Motstand: [b]%d[/b]\n%s Men tinget er uforutsigbart: Folk kan ombestemme seg underveis, og en rival kan reise seg og tale mot deg." % [stotte, int(stats["bondene"]), ting_bonus, motstand, dom], 19))
	innhold.add_child(_etikett("Skaff mer støtte før avstemningen:", 20, C_INK, font_fet))
	for p in tingdata["paavirkning"]:
		var kost := _kost(p["kost"])
		var b := _knapp("%s  (+%d støtte, koster %s)" % [p["tekst"], int(p["stotte"]), _kost_tekst(kost)], _paavirk.bind(p))
		if ting_brukte.has(p["id"]):
			_deaktiver(b, p["tekst"] + "  (gjort)")
		elif not _har_rad(kost):
			_deaktiver(b, p["tekst"] + "  (du har ikke råd – koster " + _kost_tekst(kost) + ")")
		innhold.add_child(b)
	innhold.add_child(_knapp("La tinget stemme", _ting_stem, true))


## Liten søyle som viser støtten din mot motstanden.
func _stemmebar(stotte: int, motstand: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, 34)
	c.draw.connect(_tegn_stemmebar.bind(c, stotte, motstand))
	return c


func _tegn_stemmebar(c: Control, stotte: int, motstand: int) -> void:
	var maks := maxf(float(maxi(stotte, motstand)) * 1.15, 1.0)
	var w := c.size.x
	c.draw_rect(Rect2(0, 6, w, 22), Color("cfc4a8"))
	c.draw_rect(Rect2(0, 6, w * stotte / maks, 22), C_PLUSS if stotte >= motstand else C_ACCENT)
	var x := w * motstand / maks
	c.draw_line(Vector2(x, 0), Vector2(x, 34), C_INK, 3.0)


## Sjansen for å vinne når stemningen kan svinge ±TING_SVING og en rival kan dukke opp.
func _ting_sjanse(stotte: int, motstand: int) -> int:
	var uten_rival := clampf(float(TING_SVING + 1 + stotte - motstand) / (2 * TING_SVING + 1), 0.0, 1.0)
	var med_rival := clampf(float(TING_SVING + 1 + stotte - motstand - TING_RIVAL_MOTSTAND) / (2 * TING_SVING + 1), 0.0, 1.0)
	return int(round(100.0 * ((1.0 - TING_RIVAL_SJANSE) * uten_rival + TING_RIVAL_SJANSE * med_rival)))


func _paavirk(p: Dictionary) -> void:
	_betal(_kost(p["kost"]))
	ting_bonus += int(p["stotte"])
	ting_brukte[p["id"]] = true
	_vis_avstemning()


func _ting_stem() -> void:
	var sving := randi_range(-TING_SVING, TING_SVING)
	var rival := randf() < TING_RIVAL_SJANSE
	var motstand := int(ting_valg["motstand"]) + (TING_RIVAL_MOTSTAND if rival else 0)
	var vant := _ting_stotte() + sving >= motstand
	_logg("ting_vunnet" if vant else "ting_tapt")
	if ting_h == null:
		ting_brukt = true
	else:
		aktive.erase(ting_h)
	var effekter: Dictionary = ting_valg.get("effekter", {}) if vant else {"aere": -5}
	_endre(effekter)
	if vant:
		fiender = maxi(fiender + int(ting_valg.get("fiender", 0)), 0)
		if ting_valg.has("kontakt"):
			kontakter["hedeby"] = maxi(int(kontakter.get("hedeby", 0)), int(ting_valg["kontakt"]))
		if ting_valg.has("flagg"):
			flagg[ting_valg["flagg"]] = true
	_oppdater_topplinje()

	_tom_innhold("tingresultat")
	_overskrift("TINGET HAR STEMT", "Vedtatt!" if vant else "Tinget stemte deg ned")
	var forlop := []
	if rival:
		forlop.append("Rett før avstemningen reiste storbonden Ottar seg og talte mot deg. Flere bønder nikket (+%d motstand)." % TING_RIVAL_MOTSTAND)
	if sving >= 5:
		forlop.append("Talen din gjorde inntrykk, og flere enn ventet stemte med deg (+%d støtte)." % sving)
	elif sving <= -5:
		forlop.append("Noen av dem som hadde lovet deg støtte, ombestemte seg da det gjaldt (%d støtte)." % sving)
	else:
		forlop.append("Stemningen på tinget var omtrent som ventet.")
	innhold.add_child(_avsnitt(" ".join(forlop), 20, C_MUTED, font_kursiv))
	if vant:
		innhold.add_child(_avsnitt(ting_valg["resultat"], 22))
	else:
		innhold.add_child(_avsnitt("Flertallet gikk imot deg. En høvding som taper på tinget, mister ansikt. Makten din hviler på at folk vil følge deg, og i dag ville de ikke det.", 22))
	var eff := _effekt_tekst(effekter)
	if eff != "":
		innhold.add_child(_rik(eff, 20))
	if vant and int(ting_valg.get("fiender", 0)) != 0:
		innhold.add_child(_rik("[b]Fiender: %+d[/b]  (nå %d)" % [int(ting_valg["fiender"]), fiender], 19))
	var kort := _fakta_for_tingsak(ting_sak)
	if not kort.is_empty():
		_vis_kort(kort[0], kort[1])
	_tilbake_knapp()


# ---------------------------------------------------------------- slutten

func _tilnavn(sum: int) -> String:
	if sum >= 300:
		return "den store"
	if sum >= 240:
		return "den vise"
	if sum >= 180:
		return "den gode"
	return "den seige"


func _vis_slutt(tapt: String) -> void:
	_tom_innhold("slutt")
	neste_knapp.disabled = true
	hint.text = ""
	var sum := 0
	for nokkel in STOTTE:
		sum += int(stats[nokkel])
	var innskrift := ""
	if tapt == "":
		var tilnavn := _tilnavn(sum)
		innhold.add_child(_etikett("Du klarte %d vintre!" % ANTALL_VINTRE, 36, C_ACCENT, font_fet))
		innhold.add_child(_avsnitt("Du styrte bygda gjennom gode og harde år. Folk vil huske deg som %s %s." % [hovding_navn, tilnavn], 22))
		innskrift = "Bøndene reiste denne steinen etter %s %s, som var høvding i %d vintre." % [hovding_navn, tilnavn, ANTALL_VINTRE]
	else:
		var vintre_styrt := vinter - 1
		innhold.add_child(_etikett("Tiden din som høvding er over", 34, C_ACCENT, font_fet))
		innhold.add_child(_avsnitt(TAP_TEKST[tapt], 22))
		innskrift = "%s var høvding i %d vintre." % [hovding_navn, vintre_styrt] if vintre_styrt != 1 else "%s var høvding i én vinter." % hovding_navn

	innhold.add_child(_sagakort(tapt))
	innhold.add_child(_etikett("Tenk over", 23, C_INK, font_fet))
	var sporsmal := []
	for q in sagadata["refleksjon"]:
		sporsmal.append("•  " + q)
	innhold.add_child(_avsnitt("\n".join(sporsmal), 20))
	_vis_kort("sagaer", sagadata["fakta"])
	innhold.add_child(_runestein(innskrift))
	innhold.add_child(_rik("Sølv: [b]%d[/b]     Ære: [b]%d[/b]     Gudenes gunst: [b]%d[/b]     Ætten: [b]%d[/b]     Bøndene: [b]%d[/b]\nTreller: [b]%d[/b]     Handelsforbindelser: [b]%d[/b]     Fiender: [b]%d[/b]" % [stats["solv"], stats["aere"], stats["gudene"], stats["aetten"], stats["bondene"], treller.size(), kontakter.size(), fiender], 19))
	innhold.add_child(_avsnitt("Du har samlet %d av %d kunnskapskort. Spill igjen for å møte nye saker!" % [_antall_funnet(), _alle_kort().size()], 21, C_INK, font_fet))
	innhold.add_child(_knapp("Spill igjen", _vis_start, true))
	var kort_knapp := _knapp("Se kunnskapskortene", _vis_samling, true)
	kort_knapp.set_meta("ikke_auto", true)
	innhold.add_child(kort_knapp)


## «Sagaen om deg»: skrevet som om en kristen islending satte den sammen rundt 1280,
## ut fra det spilleren faktisk gjorde – og farget av hvem som vant og fortalte den videre.
func _sagakort(tapt: String) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _boks(Color("f3e9cf"), Color("a8916a"), 4, 34.0))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	var tittel := "Sagaen om " + hovding_navn
	if tapt == "":
		tittel += " " + _tilnavn(_stottesum())
	var t := _etikett(tittel, 32, C_ACCENT, font_fet)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var under := _avsnitt("Skrevet ned på Island rundt år 1280 – nesten 300 år etter at du levde.", 17, C_MUTED, font_kursiv)
	under.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(under)
	for avsnitt in _lag_saga(tapt):
		v.add_child(_avsnitt(avsnitt, 20))
	return p


func _stottesum() -> int:
	var sum := 0
	for nokkel in STOTTE:
		sum += int(stats[nokkel])
	return sum


func _lag_saga(tapt: String) -> Array:
	var n := hovding_navn
	var s := []
	s.append("Det var en høvding som het %s. %s rådde for en gård og en bygd på Vestlandet i de dager da Håkon jarl styrte Norge, og landet ennå var hedensk." % [n, n])

	# Troen, sett med kristne øyne
	if flagg.has("kors"):
		s.append("%s lot prester fra England tegne korsets tegn over seg. Mange mener at Guds nåde allerede da begynte å virke i høvdingens hjerte, lenge før kongene førte kristendommen til landet." % n)
	elif flagg.has("stort_blot") or int(stats["gudene"]) >= 70:
		s.append("%s var en stor blotmann og holdt fast ved de hedenske gudene, slik folk gjorde i den mørke tiden før lyset fra Kristus nådde Norge. Det sies at blodet fra offerhestene rant over steinen i offerlunden." % n)
	elif flagg.has("droppet_blot"):
		s.append("Det fortelles at %s en vinter nektet å blote til de falske gudene. Bøndene ble harme, men vi som kjenner den sanne Gud, regner det til høvdingens ære." % n)
	else:
		s.append("%s blotet til de gamle gudene, slik alle gjorde i den tiden, for ingen hadde ennå hørt om Kristus." % n)

	# Tokt
	var land := []
	if int(logg.get("tokt_england", 0)) > 0:
		land.append("England")
	if int(logg.get("tokt_irland", 0)) > 0:
		land.append("Irland")
	if not land.is_empty():
		s.append("%s herjet i vesterled og ranet Guds hus i %s. Hellige menn ble drept eller ført bort som treller. Det var en tung synd, og om det vil vi ikke si mer." % [n, " og ".join(land)])
	if int(logg.get("tokt_frankerriket", 0)) > 0:
		s.append("Skipene til %s seilte også opp elva Seinen i Frankland og kom hjem med mye gods. Skaldene kvad om det, men frankerne ba til Gud om å bli fridd fra nordmennenes raseri." % n)
	if int(logg.get("tokt_feil", 0)) > 0:
		s.append("Ikke alle ferdene gikk vel. Mange gode menn fra bygda ligger i fremmed jord, og kvinnene gråt i langhusene den høsten.")
	if int(logg.get("hevntokt", 0)) > 0:
		s.append("Fiendene høvdingen hadde skaffet seg, kom tilbake over havet og brente nausta. Slik straffet Gud ranet, sier noen.")
	if int(logg.get("tokt_ok", 0)) + int(logg.get("tokt_feil", 0)) == 0:
		s.append("%s fór aldri i viking, men satt fredelig på gården sin." % n)

	# Handel
	if int(logg.get("handel_bulgar", 0)) > 0:
		s.append("Det sies at skipet til %s seilte den lange østerveien gjennom Gardarike, og kom hjem med sølv fra Serkland. På myntene sto tegn som ingen her kunne lese." % n)
	elif int(logg.get("handel", 0)) > 0 or not kontakter.is_empty():
		s.append("%s var en klok kjøpmann og hadde venner i mange handelsbyer. Derfor ble bygda rik." % n)

	# Trellene
	if int(logg.get("frigitt", 0)) > 0:
		s.append("%s ga treller friheten. Det var en god gjerning, for alle mennesker er like for Gud – og det var mer enn mange hedninger gjorde." % n)
	var handlet := []
	if int(logg.get("kjopt", 0)) > 0:
		handlet.append("kjøpte")
	if int(logg.get("solgt", 0)) > 0:
		handlet.append("solgte")
	if not handlet.is_empty():
		s.append("Men %s %s også mennesker som fe på markedet, slik hedningene gjorde i den tiden." % [n, " og ".join(handlet)])
	if int(logg.get("fanget_igjen", 0)) > 0:
		s.append("En trell som rømte fra gården, ble jaget opp mot fjellet og ført tilbake i bånd.")
	if not treller.is_empty() and int(logg.get("frigitt", 0)) == 0:
		s.append("Trellene på gården er ikke nevnt med navn i noen gammel fortelling. Ingen husket dem.")

	# Det folk husket
	if flagg.has("vant_holmgang"):
		s.append("%s felte berserken Ljot på holmgang, og det ble regnet for en stor bedrift." % n)
	if flagg.has("gjestfri"):
		s.append("%s var gjestmild. En kald vinterkveld tok høvdingen imot tre fremmede, og en av dem var en gammel enøyd mann som var borte om morgenen. Hedningene trodde det var Odin selv." % n)
	if flagg.has("reddet_barn"):
		s.append("Det fortelles også at %s ga korn til en fattig kvinne, slik at barnet hennes fikk leve. Det regnes for en kristelig gjerning, selv om høvdingen ikke var døpt." % n)
	if flagg.has("aettefeide"):
		s.append("Etter et drap i et gilde ble det ufred mellom ættene i bygda, og den feiden varte lenge.")
	if flagg.has("kvad"):
		s.append("Skalden Torleiv diktet et kvad om %s. Noen vers av det er ennå kjent, og på dem bygger mye av denne fortellingen." % n)

	# Tinget
	var vunnet := int(logg.get("ting_vunnet", 0))
	var tapte := int(logg.get("ting_tapt", 0))
	if vunnet > tapte:
		s.append("%s var vellidt på tinget og klok i råd, og bøndene fulgte ofte høvdingen." % n)
	elif tapte > vunnet:
		s.append("Bøndene var ofte uenige med %s på tinget, og høvdingen tapte mange saker der." % n)

	# Slutten – og hvem som fortalte historien videre
	match tapt:
		"":
			s.append("%s styrte bygda i åtte vintre og ble kalt %s %s. Ætten etter høvdingen ble stor og mektig, og det er fra dem vi har denne fortellingen. Derfor blir det mest sagt godt om høvdingen her." % [n, n, _tilnavn(_stottesum())])
		"bondene":
			s.append("Til slutt vendte bøndene seg mot %s, og tinget valgte en annen til høvding. Denne fortellingen har vi fra ætten som tok makten etterpå, og de hadde liten grunn til å tale vel om den som kom før dem." % n)
		"aetten":
			s.append("Til slutt vendte frendene seg bort, og %s sto alene. Ingen ætt tok vare på minnet, og derfor er mye av denne sagaen glemt." % n)
		"aere":
			s.append("%s mistet all ære og døde fattig og glemt. Fortellingen har vi fra rivalene, og de husket best det som gikk galt." % n)
		"gudene":
			s.append("Etter flere uår mente bøndene at gudene hadde vendt seg bort fra %s, og høvdingen måtte flykte fra bygda. Hedningene trodde uår var straff fra gudene. Vi vet at alt skjer etter Guds vilje." % n)
	s.append("Og her slutter sagaen om %s." % n)
	return s


func _runestein(innskrift: String) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _boks(C_STEIN, Color("6b6a63"), 60, 30.0)
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	p.add_theme_stylebox_override("panel", s)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	var runer := _avsnitt(_til_runer(hovding_navn), 46, Color("3a2a22"), font_runer)
	runer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(runer)
	var tekst := _avsnitt(innskrift, 20, Color("1f1a17"), font_kursiv)
	tekst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(tekst)
	var forklaring := _avsnitt("Navnet ditt skrevet med den yngre futharken, runene som ble brukt i vikingtiden.", 16, Color("2f2a25"))
	forklaring.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(forklaring)
	return p


func _vis_samling() -> void:
	topplinje.visible = false
	_tom_innhold("samling")
	var alle := _alle_kort()
	_overskrift("", "Kunnskapskortene dine")
	innhold.add_child(_avsnitt("Du har funnet %d av %d kort. Kortene dukker opp når du løser saker, seiler, bruker tinget og ser til trellene." % [_antall_funnet(), alle.size()], 21))
	innhold.add_child(_knapp("Tilbake", _vis_start, true))
	for k in alle:
		if samling.has(k["id"]):
			innhold.add_child(_faktakort(k["fakta"], false))
		else:
			var p := PanelContainer.new()
			p.add_theme_stylebox_override("panel", _boks(Color("cfc4a8"), Color(0, 0, 0, 0), 8, 18.0))
			p.add_child(_etikett("᛫ ᛫ ᛫   Ikke funnet ennå", 19, C_MUTED, font_kursiv))
			innhold.add_child(p)
	innhold.add_child(_knapp("Tilbake", _vis_start, true))


# ---------------------------------------------------------------- test

## Kjør med: godot --path . -- --autotest [--skjermbilde]
## Spiller noen runder med tilfeldige valg, prøver alle delene av spillet og avslutter.
func _autotest() -> void:
	var bilder := "--skjermbilde" in OS.get_cmdline_user_args()
	if "--kart" in OS.get_cmdline_user_args():
		_start_spill("Ragnvald")
		bygget["naustet"] = true
		kontakter["kaupang"] = 2
		_lukk_vindu()
		_vis_skip()
		_velg_mal("bulgar")
		await get_tree().create_timer(1.5).timeout
		get_viewport().get_texture().get_image().save_png("user://skjerm_kart.png")
		rulle.scroll_vertical = 2000
		await get_tree().create_timer(0.5).timeout
		get_viewport().get_texture().get_image().save_png("user://skjerm_kart2.png")
		get_tree().quit()
		return
	if "--saga" in OS.get_cmdline_user_args():
		_start_spill("Ragnvald")
		flagg["stort_blot"] = true
		flagg["gjestfri"] = true
		flagg["kvad"] = true
		logg = {"tokt_irland": 1, "tokt_ok": 1, "hevntokt": 1, "solgt": 1, "handel_bulgar": 1, "handel": 1, "ting_vunnet": 2}
		var rommling: Dictionary = treller[1]
		treller.erase(rommling)
		var h := {"rommling": rommling, "sted": "skogen", "person": "", "tittel": ""}
		aktive.append(h)
		_vis_flukt(h)
		await get_tree().create_timer(1.0).timeout
		get_viewport().get_texture().get_image().save_png("user://skjerm_flukt.png")
		vinter = ANTALL_VINTRE + 1
		_vis_slutt("")
		await get_tree().create_timer(1.0).timeout
		for i in 3:
			rulle.scroll_vertical = 330 + i * 560
			await get_tree().create_timer(0.4).timeout
			get_viewport().get_texture().get_image().save_png("user://skjerm_saga%d.png" % i)
		get_tree().quit()
		return
	var tatt := {}
	var runder := 0
	for steg in 3000:
		await get_tree().create_timer(0.7 if bilder else 0.01).timeout
		if bilder and not tatt.has(skjerm):
			tatt[skjerm] = true
			var fil := "user://skjerm_%s.png" % skjerm
			get_viewport().get_texture().get_image().save_png(fil)
			print("Skjermbilde: ", ProjectSettings.globalize_path(fil))
		match skjerm:
			"start":
				if runder >= (1 if bilder else 3):
					break
				runder += 1
				_start_spill("Ragnvald")
				continue
			"verden":
				_autotest_paa_garden(tatt)
				continue
			"skip":
				if valgt_mal == "" or randf() < 0.3:
					_velg_mal(handeldata["mal"].pick_random()["id"])
			"slutt":
				print("Runde %d ferdig: %s  treller: %d  kontakter: %s  fiender: %d  bygd: %s" % [runder, stats, treller.size(), kontakter.keys(), fiender, bygget.keys()])
		var knapper := []
		for c in _alle_knapper(innhold):
			if not c.disabled and not c.has_meta("ikke_auto"):
				knapper.append(c)
		if knapper.is_empty():
			# Bare «tilbake»-knapper igjen (f.eks. når spilleren ikke har råd til noe): gå tilbake.
			if _alle_knapper(innhold).is_empty():
				push_error("Ingen knapper på skjermen: " + skjerm)
				break
			_tilbake_til_garden()
			continue
		knapper.pick_random().pressed.emit()
	var mangler := []
	for k in _alle_kort():
		if not samling.has(k["id"]):
			mangler.append(k["id"])
	print("Autotest ferdig. Kort samlet: %d/%d. Ikke funnet: %s" % [_antall_funnet(), _alle_kort().size(), mangler])
	get_tree().quit()


func _alle_knapper(node: Node) -> Array:
	var ut := []
	for c in node.get_children():
		if c is Button:
			ut.append(c)
		else:
			ut.append_array(_alle_knapper(c))
	return ut


func _autotest_paa_garden(tatt: Dictionary) -> void:
	var tomter := []
	for id in steder:
		if _kan_bygges(id) and not bygget.has(id) and _har_rad(_kost(steder[id]["pris"])):
			tomter.append(id)
	var r := randf()
	if not tatt.has("ressurs_testet"):
		tatt["ressurs_testet"] = true
		_vis_ressurs(RESSURSER.pick_random())
	elif not tomter.is_empty() and r < 0.15:
		_sted_klikket(tomter.pick_random())
	elif bygget.has("naustet") and _skip_hindring() == "" and r < 0.3:
		_vis_skip()
	elif not ting_brukt and r < 0.4:
		_vis_tinget()
	elif not treller.is_empty() and r < 0.47:
		_vis_treller()
	elif not aktive.is_empty():
		var h: Dictionary = aktive[0]
		_sted_klikket(h.get("sted", "langhuset"))
	else:
		_neste_vinter()
