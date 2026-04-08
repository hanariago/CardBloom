class_name CardNode
extends Node2D

## 화투 카드 1장의 Placeholder 비주얼
## 텍스처 교체 시 이 스크립트 수정 없이 @export 경로만 변경

const CARD_W := 80.0
const CARD_H := 120.0

# 카드 데이터
var card_data: CardData.Card = null

# 상태
var is_selected: bool = false
var is_interactive: bool = true  # 클릭 가능 여부

# 신호
signal card_clicked(node: CardNode)

# 내부 노드
var _bg: ColorRect
var _label: Label
var _type_indicator: ColorRect  # 유형 표시 띠
var _select_indicator: ColorRect  # 선택 표시

# 호버 애니메이션용
var _base_y: float = 0.0
var _hover_tween: Tween


func _ready() -> void:
	# _build_visual은 setup()에서 먼저 호출됨.
	# _setup_input은 Area2D가 씬 트리에 있어야 하므로 _ready에서 실행.
	_setup_input()


## 카드 데이터 설정 (add_child 전에 호출 가능)
func setup(data: CardData.Card) -> void:
	card_data = data
	_build_visual()
	_update_visual()


## 선택 상태 토글
func set_selected(value: bool) -> void:
	is_selected = value
	_select_indicator.visible = value
	_animate_lift(value)


func _build_visual() -> void:
	# 배경
	_bg = ColorRect.new()
	_bg.size = Vector2(CARD_W, CARD_H)
	_bg.position = Vector2(-CARD_W * 0.5, -CARD_H * 0.5)
	add_child(_bg)

	# 유형 표시 띠 (상단 10px)
	_type_indicator = ColorRect.new()
	_type_indicator.size = Vector2(CARD_W, 10)
	_type_indicator.position = Vector2(-CARD_W * 0.5, -CARD_H * 0.5)
	add_child(_type_indicator)

	# 카드 텍스트 라벨
	_label = Label.new()
	_label.size = Vector2(CARD_W - 8, CARD_H - 16)
	_label.position = Vector2(-CARD_W * 0.5 + 4, -CARD_H * 0.5 + 14)
	_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(_label)

	# 선택 표시 (테두리 효과 — 흰색 반투명 오버레이)
	_select_indicator = ColorRect.new()
	_select_indicator.size = Vector2(CARD_W, CARD_H)
	_select_indicator.position = Vector2(-CARD_W * 0.5, -CARD_H * 0.5)
	_select_indicator.color = Color(1, 1, 1, 0.3)
	_select_indicator.visible = false
	add_child(_select_indicator)


func _update_visual() -> void:
	if card_data == null:
		return

	# 배경 색 (월별 색상)
	_bg.color = card_data.color_hint

	# 유형 표시 색
	match card_data.type:
		CardData.Type.GWANG:
			_type_indicator.color = Color(0.79, 0.66, 0.30)  # 금색
		CardData.Type.RIBBON:
			match card_data.ribbon_color:
				CardData.RibbonColor.RED:
					_type_indicator.color = Color(0.78, 0.24, 0.23)
				CardData.RibbonColor.BLUE:
					_type_indicator.color = Color(0.18, 0.37, 0.54)
				CardData.RibbonColor.GREEN:
					_type_indicator.color = Color(0.23, 0.49, 0.37)
				_:
					_type_indicator.color = Color(0.6, 0.6, 0.6)
		CardData.Type.ANIMAL:
			_type_indicator.color = Color(0.25, 0.55, 0.80)
		CardData.Type.PI, CardData.Type.DOUBLE_PI:
			_type_indicator.color = Color(0.45, 0.45, 0.45)

	# 텍스트
	_label.text = card_data.label


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


func _on_hover_exit() -> void:
	if not is_selected:
		_animate_lift(false)


func _animate_lift(up: bool) -> void:
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	var target_y := _base_y - 15.0 if up else _base_y
	_hover_tween.tween_property(self, "position:y", target_y, 0.15)
