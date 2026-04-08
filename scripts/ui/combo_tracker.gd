class_name ComboTracker
extends CanvasLayer

## 족보 진행 현황 패널 (좌측 사이드)
## collected 딕셔너리로 실시간 업데이트

const PANEL_X    := 20.0
const PANEL_Y    := 120.0
const PANEL_W    := 200.0
const ROW_H      := 30.0
const ICON_SIZE  := 14.0

# 족보 정의: [이름, 완성점수, 체크함수_key]
# _rows[i] = { label_left, label_right, bar, achieved }
var _rows: Array = []
var _panel_bg: ColorRect
var _title: Label

# 내부 상태 (flash 용)
var _prev_achieved: Dictionary = {}


func _ready() -> void:
	layer = 3

	_build_panel()
	_build_rows()


func _build_panel() -> void:
	var row_count := 10
	var h := ROW_H * row_count + 44

	_panel_bg = ColorRect.new()
	_panel_bg.position = Vector2(PANEL_X, PANEL_Y)
	_panel_bg.size = Vector2(PANEL_W, h)
	_panel_bg.color = Color(0.04, 0.04, 0.10, 0.82)
	add_child(_panel_bg)

	_title = Label.new()
	_title.position = Vector2(PANEL_X + 8, PANEL_Y + 6)
	_title.text = "족보 현황"
	_title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.55))
	UITheme.apply_serif(_title, 17, true)
	add_child(_title)

	# 구분선
	var sep := ColorRect.new()
	sep.position = Vector2(PANEL_X + 6, PANEL_Y + 32)
	sep.size = Vector2(PANEL_W - 12, 1)
	sep.color = Color(1, 1, 1, 0.15)
	add_child(sep)


func _build_rows() -> void:
	# [id, 표시명, 최대 진행수, 완성 점수, 색상]
	var defs := [
		["gwang5",   "오광",   5, 30,  Color(0.95, 0.80, 0.20)],
		["gwang4",   "사광",   4, 20,  Color(0.95, 0.80, 0.20)],
		["gwang3",   "삼광",   3, 15,  Color(0.95, 0.80, 0.20)],
		["godori",   "고도리", 3, 15,  Color(0.30, 0.70, 0.95)],
		["hongdan",  "홍단",   3, 10,  Color(0.85, 0.25, 0.25)],
		["cheongdan","청단",   3, 10,  Color(0.20, 0.45, 0.80)],
		["chodan",   "초단",   3, 10,  Color(0.25, 0.65, 0.35)],
		["ribbon5",  "띠 5장", 5, 5,   Color(0.70, 0.50, 0.80)],
		["animal5",  "열끗 5장",5, 5,  Color(0.30, 0.70, 0.95)],
		["pi10",     "피 10점",10, 5,  Color(0.55, 0.55, 0.58)],
	]

	for i in defs.size():
		var d: Array = defs[i]
		var y: float = PANEL_Y + 38.0 + i * ROW_H

		# 족보명
		var lbl := Label.new()
		lbl.position = Vector2(PANEL_X + 8, y + 4)
		lbl.text = d[1] as String
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		UITheme.apply_pretendard(lbl, 14)
		add_child(lbl)

		# 진행 도트
		var dot_lbl := Label.new()
		dot_lbl.position = Vector2(PANEL_X + 72, y + 4)
		dot_lbl.size = Vector2(80, 22)
		dot_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		UITheme.apply_pretendard(dot_lbl, 13)
		add_child(dot_lbl)

		# 점수
		var score_lbl := Label.new()
		score_lbl.position = Vector2(PANEL_X + 155, y + 4)
		score_lbl.size = Vector2(40, 22)
		score_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		UITheme.apply_pretendard(score_lbl, 13)
		add_child(score_lbl)

		_rows.append({
			"id": d[0],
			"max": d[2] as int,
			"score": d[3] as int,
			"color": d[4] as Color,
			"name_lbl": lbl,
			"dot_lbl": dot_lbl,
			"score_lbl": score_lbl,
			"achieved": false,
		})
		_prev_achieved[d[0] as String] = false


## collected 딕셔너리로 전체 갱신
func update(collected: Dictionary) -> void:
	var gwang: Array  = collected.get("gwang", [])
	var ribbon: Array = collected.get("ribbon", [])
	var animal: Array = collected.get("animal", [])
	var pi_arr: Array = collected.get("pi", [])

	var gwang_count := gwang.size()
	var _has_rain := gwang.any(func(c) -> bool: return c.month == 12)

	var ribbon_months := ribbon.map(func(c) -> int: return c.month)
	var animal_months := animal.map(func(c) -> int: return c.month)

	var pi_points := 0
	for c in pi_arr:
		pi_points += 2 if c.type == CardData.Type.DOUBLE_PI else 1

	# 각 족보 진행 계산
	var progress := {
		"gwang5":    [gwang_count, 5, gwang_count >= 5],
		"gwang4":    [gwang_count, 4, gwang_count == 4],
		"gwang3":    [gwang_count, 3, gwang_count == 3],
		"godori":    [_count_months(animal_months, [2,4,8]), 3,
					  _has_months(animal_months, [2,4,8])],
		"hongdan":   [_count_months(ribbon_months, [1,2,3]), 3,
					  _has_months(ribbon_months, [1,2,3])],
		"cheongdan": [_count_months(ribbon_months, [6,9,10]), 3,
					  _has_months(ribbon_months, [6,9,10])],
		"chodan":    [_count_months(ribbon_months, [4,5,7]), 3,
					  _has_months(ribbon_months, [4,5,7])],
		"ribbon5":   [ribbon.size(), 5, ribbon.size() >= 5],
		"animal5":   [animal.size(), 5, animal.size() >= 5],
		"pi10":      [pi_points, 10, pi_points >= 10],
	}

	for row in _rows:
		var id: String    = row["id"]   as String
		var p: Array      = progress[id] as Array
		var cur: int      = p[0]        as int
		var max_v: int    = row["max"]  as int
		var achieved: bool = p[2]       as bool
		var color: Color  = row["color"] as Color
		var name_lbl: Label  = row["name_lbl"]  as Label
		var dot_lbl: Label   = row["dot_lbl"]   as Label
		var score_lbl: Label = row["score_lbl"] as Label

		# 도트 표시 (● = 달성, ○ = 미달성)
		var dot_str := ""
		for di in max_v:
			dot_str += "●" if di < cur else "○"
		dot_lbl.text = dot_str

		# 달성 여부에 따른 색
		if achieved:
			name_lbl.add_theme_color_override("font_color", color)
			dot_lbl.add_theme_color_override("font_color", color)
			score_lbl.text = "+%d" % (row["score"] as int)
			score_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.30))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.70, 0.70, 0.70))
			var partial_color := Color(color.r * 0.65, color.g * 0.65, color.b * 0.65)
			dot_lbl.add_theme_color_override("font_color", partial_color)
			if cur > 0:
				score_lbl.text = "%d/%d" % [cur, max_v]
			else:
				score_lbl.text = ""
			score_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.45))

		# 새로 달성된 족보 → 이름 라벨 반짝임
		if achieved and not _prev_achieved.get(id, false):
			_flash_row(row)

		row["achieved"] = achieved
		_prev_achieved[id] = achieved


func _flash_row(row: Dictionary) -> void:
	var lbl: Label     = row["name_lbl"] as Label
	var orig_color: Color = row["color"] as Color
	var tween := create_tween()
	tween.tween_property(lbl, "modulate", Color(2.0, 2.0, 0.5, 1.0), 0.0)
	tween.tween_property(lbl, "modulate", Color.WHITE, 0.6)
	tween.tween_callback(func() -> void:
		lbl.add_theme_color_override("font_color", orig_color)
	)


func _count_months(months: Array, targets: Array) -> int:
	var count := 0
	for t in targets:
		if t in months:
			count += 1
	return count


func _has_months(months: Array, targets: Array) -> bool:
	for t in targets:
		if t not in months:
			return false
	return true
