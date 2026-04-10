class_name CardNode
extends Node2D

## 화투 카드 1장 비주얼
## 100×150 크림 배경, 유형색 테두리, 월 숫자(Pretendard) + 한자(본명조)

const CARD_W := 100.0
const CARD_H := 150.0

const TYPE_KANJI: Dictionary = {
	CardData.Type.GWANG:      "光",
	CardData.Type.RIBBON:     "帶",
	CardData.Type.ANIMAL:     "動",
	CardData.Type.PI:         "皮",
	CardData.Type.DOUBLE_PI:  "皮皮"
}

# 카드 데이터
var card_data: CardData.Card = null

# 상태
var is_selected: bool = false
var is_interactive: bool = true

# 신호
signal card_clicked(node: CardNode)
signal card_hovered(node: CardNode)
signal card_unhovered(node: CardNode)

# 내부 노드
var _border: ColorRect
var _bg: ColorRect
var _strip: ColorRect         # 상단 색상 띠
var _month_label: Label       # 월 숫자 (Pretendard, 큰 글자)
var _kanji_label: Label       # 유형 한자 (본명조)
var _name_label: Label        # 카드명 소자 (Pretendard)
var _highlight: ColorRect     # 매칭 하이라이트 오버레이
var _select_indicator: ColorRect

# 호버 애니메이션용
var _base_y: float = 0.0
var _hover_tween: Tween


func _ready() -> void:
	_setup_input()


## 카드 데이터 설정 (add_child 전에 호출 가능)
func setup(data: CardData.Card) -> void:
	card_data = data
	_build_visual()
	_update_visual()


## 선택 상태 설정
func set_selected(value: bool) -> void:
	is_selected = value
	_select_indicator.visible = value
	_animate_lift(value)


## 매칭 하이라이트 (바닥 카드에 사용)
func set_highlight(on: bool) -> void:
	_highlight.visible = on


## 수집/매칭 시 짧은 글로우 플래시
func flash_glow() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(2.0, 1.9, 0.5, 1.0), 0.0)
	tween.tween_property(self, "modulate", Color.WHITE, 0.35)


## 카드 유형에 맞는 대표 색상 반환
func _type_color() -> Color:
	if card_data == null:
		return Color.GRAY
	match card_data.type:
		CardData.Type.GWANG:
			return Color(0.79, 0.66, 0.30)   # 금색
		CardData.Type.RIBBON:
			match card_data.ribbon_color:
				CardData.RibbonColor.RED:
					return Color(0.78, 0.24, 0.23)
				CardData.RibbonColor.BLUE:
					return Color(0.18, 0.37, 0.54)
				CardData.RibbonColor.GREEN:
					return Color(0.23, 0.49, 0.37)
				_:
					return Color(0.6, 0.4, 0.6)
		CardData.Type.ANIMAL:
			return Color(0.25, 0.55, 0.80)
		_:   # PI / DOUBLE_PI
			return Color(0.40, 0.40, 0.42)


func _build_visual() -> void:
	var BORDER := 3.0
	var STRIP_H := 14.0

	# 테두리 (유형 색상)
	_border = ColorRect.new()
	_border.size = Vector2(CARD_W, CARD_H)
	_border.position = Vector2(-CARD_W * 0.5, -CARD_H * 0.5)
	_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_border)

	# 크림 배경
	_bg = ColorRect.new()
	_bg.size = Vector2(CARD_W - BORDER * 2, CARD_H - BORDER * 2)
	_bg.position = Vector2(-CARD_W * 0.5 + BORDER, -CARD_H * 0.5 + BORDER)
	_bg.color = Color(0.95, 0.92, 0.88)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	# 상단 색상 띠
	_strip = ColorRect.new()
	_strip.size = Vector2(CARD_W - BORDER * 2, STRIP_H)
	_strip.position = Vector2(-CARD_W * 0.5 + BORDER, -CARD_H * 0.5 + BORDER)
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_strip)

	# 월 숫자 (Pretendard, 큰 글자)
	_month_label = Label.new()
	_month_label.size = Vector2(CARD_W - BORDER * 2, 44)
	_month_label.position = Vector2(-CARD_W * 0.5 + BORDER, -CARD_H * 0.5 + BORDER + STRIP_H + 2)
	_month_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_month_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_month_label.add_theme_color_override("font_color", Color(0.15, 0.10, 0.08))
	_month_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_month_label)

	# 유형 한자 (본명조)
	_kanji_label = Label.new()
	_kanji_label.size = Vector2(CARD_W - BORDER * 2, 54)
	_kanji_label.position = Vector2(-CARD_W * 0.5 + BORDER, -10.0)
	_kanji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kanji_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_kanji_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_kanji_label)

	# 카드명 소자 (Pretendard, 하단)
	_name_label = Label.new()
	_name_label.size = Vector2(CARD_W - BORDER * 2, 26)
	_name_label.position = Vector2(-CARD_W * 0.5 + BORDER, CARD_H * 0.5 - BORDER - 28)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_color_override("font_color", Color(0.35, 0.30, 0.28))
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	# 하이라이트 오버레이 (매칭 대상 강조)
	_highlight = ColorRect.new()
	_highlight.size = Vector2(CARD_W, CARD_H)
	_highlight.position = Vector2(-CARD_W * 0.5, -CARD_H * 0.5)
	_highlight.color = Color(1.0, 0.95, 0.2, 0.28)
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight.visible = false
	add_child(_highlight)

	# 선택 오버레이 (손패 선택)
	_select_indicator = ColorRect.new()
	_select_indicator.size = Vector2(CARD_W, CARD_H)
	_select_indicator.position = Vector2(-CARD_W * 0.5, -CARD_H * 0.5)
	_select_indicator.color = Color(1, 1, 1, 0.22)
	_select_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_indicator.visible = false
	add_child(_select_indicator)


func _update_visual() -> void:
	if card_data == null:
		return

	var tc := _type_color()

	_border.color = tc
	_strip.color = Color(tc.r, tc.g, tc.b, 0.85)

	# 월 숫자
	UITheme.apply_pretendard(_month_label, 38)
	_month_label.text = "%d월" % card_data.month

	# 유형 한자
	UITheme.apply_serif(_kanji_label, 40)
	_kanji_label.add_theme_color_override("font_color", Color(tc.r * 0.7, tc.g * 0.7, tc.b * 0.7))
	_kanji_label.text = TYPE_KANJI.get(card_data.type, "?")

	# 카드명 (쌍피면 "쌍피", 나머지는 label에서 유형 부분)
	UITheme.apply_pretendard(_name_label, 13)
	_name_label.text = _short_name()


func _short_name() -> String:
	match card_data.type:
		CardData.Type.GWANG:      return "광"
		CardData.Type.RIBBON:
			match card_data.ribbon_color:
				CardData.RibbonColor.RED:   return "홍단"
				CardData.RibbonColor.BLUE:  return "청단"
				CardData.RibbonColor.GREEN: return "초단"
				_:                          return "띠"
		CardData.Type.ANIMAL:     return "열끗"
		CardData.Type.PI:         return "피"
		CardData.Type.DOUBLE_PI:  return "쌍피"
	return ""


func _setup_input() -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CARD_W, CARD_H)
	shape.shape = rect
	area.add_child(shape)
	add_child(area)

	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_hover_enter)
	area.mouse_exited.connect(_on_hover_exit)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_clicked.emit(self)


func _on_hover_enter() -> void:
	if not is_interactive:
		return
	_animate_lift(true)
	card_hovered.emit(self)


func _on_hover_exit() -> void:
	if not is_interactive:
		return   # 날아가는 중엔 hover 해제 무시 (tween 충돌 방지)
	if not is_selected:
		_animate_lift(false)
	card_unhovered.emit(self)


func _animate_lift(up: bool) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var target_y := _base_y - 18.0 if up else _base_y
	_hover_tween.tween_property(self, "position:y", target_y, 0.15)
