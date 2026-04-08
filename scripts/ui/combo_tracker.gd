class_name ComboTracker
extends CanvasLayer

## 족보 진행 현황 패널 — 우측 사이드, 플레이어 상태 한눈에 보기

const PANEL_X    := 22.0
const PANEL_Y    := 118.0
const PANEL_W    := 290.0
const ROW_H      := 44.0
const NAME_W     := 100.0
const DOT_X      := 108.0
const DOT_W      := 118.0
const SCORE_X    := 232.0
const SCORE_W    := 50.0

var _rows: Array = []
var _panel_bg: ColorRect
var _title: Label
var _prev_achieved: Dictionary = {}


func _ready() -> void:
	layer = 3
	_build_panel()
	_build_rows()


func _build_panel() -> void:
	var row_count := 10
	var h := ROW_H * row_count + 52.0

	# 테두리
	var border := ColorRect.new()
	border.position = Vector2(PANEL_X - 2, PANEL_Y - 2)
	border.size = Vector2(PANEL_W + 4, h + 4)
	border.color = Color(0.35, 0.30, 0.15, 0.7)
	add_child(border)

	_panel_bg = ColorRect.new()
	_panel_bg.position = Vector2(PANEL_X, PANEL_Y)
	_panel_bg.size = Vector2(PANEL_W, h)
	_panel_bg.color = Color(0.05, 0.05, 0.13, 0.93)
	add_child(_panel_bg)

	_title = Label.new()
	_title.position = Vector2(PANEL_X + 10, PANEL_Y + 8)
	_title.size = Vector2(PANEL_W - 20, 34)
	_title.text = "내 패 현황"
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))
	UITheme.apply_serif(_title, 22, true)
	add_child(_title)

	var sep := ColorRect.new()
	sep.position = Vector2(PANEL_X + 8, PANEL_Y + 46)
	sep.size = Vector2(PANEL_W - 16, 2)
	sep.color = Color(0.6, 0.5, 0.2, 0.4)
	add_child(sep)


func _build_rows() -> void:
	var defs: Array = [
		["gwang5",    "오광",    5,  30, Color(0.97, 0.84, 0.20)],
		["gwang4",    "사광",    4,  20, Color(0.97, 0.84, 0.20)],
		["gwang3",    "삼광",    3,  15, Color(0.97, 0.84, 0.20)],
		["godori",    "고도리",  3,  15, Color(0.35, 0.75, 0.98)],
		["hongdan",   "홍단",    3,  10, Color(0.92, 0.28, 0.28)],
		["cheongdan", "청단",    3,  10, Color(0.25, 0.50, 0.90)],
		["chodan",    "초단",    3,  10, Color(0.28, 0.72, 0.40)],
		["ribbon5",   "띠 5장",  5,   5, Color(0.78, 0.55, 0.90)],
		["animal5",   "열끗 5장",5,   5, Color(0.35, 0.75, 0.98)],
		["pi10",      "피 10점", 10,  5, Color(0.62, 0.62, 0.65)],
	]

	for i in defs.size():
		var d: Array = defs[i]
		var y: float = PANEL_Y + 50.0 + i * ROW_H

		var name_lbl := Label.new()
		name_lbl.position = Vector2(PANEL_X + 10, y + 6)
		name_lbl.size = Vector2(NAME_W, ROW_H - 8)
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		UITheme.apply_pretendard(name_lbl, 20)
		add_child(name_lbl)

		var dot_lbl := Label.new()
		dot_lbl.position = Vector2(PANEL_X + DOT_X, y + 6)
		dot_lbl.size = Vector2(DOT_W, ROW_H - 8)
		dot_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot_lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		UITheme.apply_pretendard(dot_lbl, 18)
		add_child(dot_lbl)

		var score_lbl := Label.new()
		score_lbl.position = Vector2(PANEL_X + SCORE_X, y + 6)
		score_lbl.size = Vector2(SCORE_W, ROW_H - 8)
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		score_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.48))
		UITheme.apply_pretendard(score_lbl, 18)
		add_child(score_lbl)

		_rows.append({
			"id":        d[0] as String,
			"max":       d[2] as int,
			"score":     d[3] as int,
			"color":     d[4] as Color,
			"name_lbl":  name_lbl,
			"dot_lbl":   dot_lbl,
			"score_lbl": score_lbl,
			"achieved":  false,
		})
		_prev_achieved[d[0] as String] = false


func update(collected: Dictionary) -> void:
	var gwang: Array  = collected.get("gwang", [])
	var ribbon: Array = collected.get("ribbon", [])
	var animal: Array = collected.get("animal", [])
	var pi_arr: Array = collected.get("pi", [])

	var gwang_count := gwang.size()
	var _has_rain := gwang.any(func(c) -> bool: return c.month == 12)

	var ribbon_months: Array = ribbon.map(func(c) -> int: return c.month)
	var animal_months: Array = animal.map(func(c) -> int: return c.month)

	var pi_points := 0
	for c in pi_arr:
		pi_points += 2 if c.type == CardData.Type.DOUBLE_PI else 1

	var progress: Dictionary = {
		"gwang5":     [gwang_count, 5,  gwang_count >= 5],
		"gwang4":     [gwang_count, 4,  gwang_count == 4],
		"gwang3":     [gwang_count, 3,  gwang_count >= 3],
		"godori":     [_count_months(animal_months, [2,4,8]),  3, _has_months(animal_months, [2,4,8])],
		"hongdan":    [_count_months(ribbon_months, [1,2,3]),  3, _has_months(ribbon_months, [1,2,3])],
		"cheongdan":  [_count_months(ribbon_months, [6,9,10]), 3, _has_months(ribbon_months, [6,9,10])],
		"chodan":     [_count_months(ribbon_months, [4,5,7]),  3, _has_months(ribbon_months, [4,5,7])],
		"ribbon5":    [ribbon.size(), 5,  ribbon.size() >= 5],
		"animal5":    [animal.size(), 5,  animal.size() >= 5],
		"pi10":       [pi_points,    10, pi_points >= 10],
	}

	for row in _rows:
		var id: String      = row["id"]       as String
		var p: Array        = progress[id]    as Array
		var cur: int        = p[0]            as int
		var max_v: int      = row["max"]      as int
		var achieved: bool  = p[2]            as bool
		var color: Color    = row["color"]    as Color
		var name_lbl: Label  = row["name_lbl"]  as Label
		var dot_lbl: Label   = row["dot_lbl"]   as Label
		var score_lbl: Label = row["score_lbl"] as Label

		var dot_str := ""
		for di in max_v:
			dot_str += "●" if di < cur else "○"
		dot_lbl.text = dot_str

		if achieved:
			name_lbl.add_theme_color_override("font_color", color)
			dot_lbl.add_theme_color_override("font_color", color)
			score_lbl.text = "+%d점" % (row["score"] as int)
			score_lbl.add_theme_color_override("font_color", Color(0.97, 0.88, 0.30))
		else:
			name_lbl.add_theme_color_override("font_color",
				Color(0.85, 0.85, 0.85) if cur > 0 else Color(0.50, 0.50, 0.50))
			var dim := Color(color.r * 0.6, color.g * 0.6, color.b * 0.6)
			dot_lbl.add_theme_color_override("font_color", dim)
			if cur > 0:
				score_lbl.text = "%d/%d" % [cur, max_v]
				score_lbl.add_theme_color_override("font_color", Color(0.70, 0.68, 0.45))
			else:
				score_lbl.text = ""

		if achieved and not _prev_achieved.get(id, false):
			_flash_achieved(row)

		row["achieved"] = achieved
		_prev_achieved[id] = achieved


func _flash_achieved(row: Dictionary) -> void:
	var name_lbl: Label = row["name_lbl"] as Label
	var color: Color    = row["color"]    as Color
	var tween := create_tween()
	tween.tween_property(name_lbl, "modulate", Color(2.5, 2.5, 0.5, 1.0), 0.0)
	tween.tween_property(name_lbl, "modulate", Color.WHITE, 0.7)
	tween.tween_callback(func() -> void:
		name_lbl.add_theme_color_override("font_color", color)
	)


func _count_months(months: Array, targets: Array) -> int:
	var n := 0
	for t in targets:
		if t in months:
			n += 1
	return n


func _has_months(months: Array, targets: Array) -> bool:
	for t in targets:
		if t not in months:
			return false
	return true
