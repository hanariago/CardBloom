class_name TutorialHint
extends CanvasLayer

## 첫 판 시작 시 핵심 규칙 설명 오버레이
## 탭/클릭 또는 3초 후 자동 닫힘

signal closed()

var _bg: ColorRect
var _panel: ColorRect
var _auto_tween: Tween


func _ready() -> void:
	layer = 20
	visible = false


## 오버레이 표시
func show_tutorial() -> void:
	visible = true
	_build_ui()
	# 배경 페이드인
	_bg.modulate.a = 0.0
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_bg, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.25)


func _build_ui() -> void:
	# 반투명 전체 배경
	_bg = ColorRect.new()
	_bg.size = Vector2(1920, 1080)
	_bg.color = Color(0, 0, 0, 0.72)
	_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_bg)

	# 중앙 패널
	_panel = ColorRect.new()
	_panel.size = Vector2(820, 460)
	_panel.position = Vector2(550, 310)
	_panel.color = Color(0.07, 0.07, 0.15, 0.97)
	add_child(_panel)

	# 패널 테두리
	var border := ColorRect.new()
	border.size = Vector2(822, 462)
	border.position = Vector2(549, 309)
	border.color = Color(0.65, 0.55, 0.25, 0.8)
	add_child(border)
	remove_child(border)
	add_child(border)
	# border를 panel 뒤에 배치
	move_child(border, get_child_count() - 3)

	# 제목
	var title := Label.new()
	title.text = "꽃판 하는 법"
	title.position = Vector2(550 + 320 - 100, 325)
	title.size = Vector2(200, 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40))
	UITheme.apply_serif(title, 30, true)
	add_child(title)

	# 규칙 1: 핵심 메커니즘
	_add_rule_block(
		Vector2(570, 395),
		"① 같은 월(숫자)끼리 짝지으면 수집!",
		"손패에서 패를 선택하면, 바닥에 같은 월의 패가\n있을 경우 함께 수집됩니다.",
		Color(0.95, 0.80, 0.25)
	)
	_add_mini_match_demo(Vector2(860, 390))

	# 규칙 2: 족보
	_add_rule_block(
		Vector2(570, 510),
		"② 패를 모아 족보를 완성하면 점수 획득!",
		"光 광 3장 → 삼광(15점)   帶 홍단띠 3장 → 홍단(10점)\n動 열끗 3장(2·4·8월) → 고도리(15점)",
		Color(0.70, 0.85, 0.55)
	)

	# 규칙 3: 고/스톱
	_add_rule_block(
		Vector2(570, 625),
		"③ 목표 점수 달성 시 스톱 또는 고!",
		"스톱: 점수 확정.   고: 계속 플레이, 목표 달성 시 배율 ×2 ↑\n(고 후 목표 미달 시 실패 패널티 주의!)",
		Color(0.70, 0.75, 0.95)
	)

	# 닫기 버튼
	var btn_bg := ColorRect.new()
	btn_bg.size = Vector2(200, 50)
	btn_bg.position = Vector2(860, 712)
	btn_bg.color = Color(0.65, 0.55, 0.25, 0.9)
	btn_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	btn_bg.gui_input.connect(_on_btn_input)
	add_child(btn_bg)

	var btn_lbl := Label.new()
	btn_lbl.text = "시작!"
	btn_lbl.size = Vector2(200, 50)
	btn_lbl.position = Vector2(860, 712)
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.add_theme_color_override("font_color", Color(0.05, 0.05, 0.10))
	btn_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(btn_lbl, 24)
	add_child(btn_lbl)


func _add_rule_block(pos: Vector2, heading: String, body: String, color: Color) -> void:
	var h := Label.new()
	h.text = heading
	h.position = pos
	h.size = Vector2(680, 32)
	h.add_theme_color_override("font_color", color)
	UITheme.apply_pretendard(h, 18)
	add_child(h)

	var b := Label.new()
	b.text = body
	b.position = pos + Vector2(0, 30)
	b.size = Vector2(680, 60)
	b.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	b.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	UITheme.apply_pretendard(b, 15)
	add_child(b)


func _add_mini_match_demo(pos: Vector2) -> void:
	# 손패 예시 카드
	var card_a := ColorRect.new()
	card_a.size = Vector2(52, 74)
	card_a.position = pos
	card_a.color = Color(0.78, 0.24, 0.23)
	add_child(card_a)
	var lbl_a := Label.new()
	lbl_a.text = "3월\n光"
	lbl_a.position = pos + Vector2(6, 8)
	lbl_a.size = Vector2(40, 58)
	lbl_a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_a.add_theme_color_override("font_color", Color.WHITE)
	lbl_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(lbl_a, 13)
	add_child(lbl_a)

	# 화살표
	var arrow := Label.new()
	arrow.text = "+"
	arrow.position = pos + Vector2(58, 22)
	arrow.add_theme_color_override("font_color", Color(0.95, 0.85, 0.40))
	UITheme.apply_pretendard(arrow, 26)
	add_child(arrow)

	# 바닥 예시 카드
	var card_b := ColorRect.new()
	card_b.size = Vector2(52, 74)
	card_b.position = pos + Vector2(80, 0)
	card_b.color = Color(0.78, 0.24, 0.23)
	add_child(card_b)
	var lbl_b := Label.new()
	lbl_b.text = "3월\n皮"
	lbl_b.position = pos + Vector2(86, 8)
	lbl_b.size = Vector2(40, 58)
	lbl_b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_b.add_theme_color_override("font_color", Color.WHITE)
	lbl_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(lbl_b, 13)
	add_child(lbl_b)

	# = 수집!
	var result := Label.new()
	result.text = "→ 수집!"
	result.position = pos + Vector2(138, 22)
	result.add_theme_color_override("font_color", Color(0.55, 0.90, 0.45))
	UITheme.apply_pretendard(result, 17)
	add_child(result)


func _on_btn_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(_bg, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		visible = false
		closed.emit()
	)
