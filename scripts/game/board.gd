class_name Board
extends Node2D

## 게임 보드 — 손패 / 바닥 / 산패 / 수집 영역 배치 및 카드 노드 관리

# 카드 씬 경로 (Placeholder CardNode를 동적 생성)
const CARD_W := CardNode.CARD_W
const CARD_H := CardNode.CARD_H
const CARD_GAP := 10.0

# 레이아웃 기준점 (1920×1080 기준)
const HAND_Y      := 940.0   # 손패 중심 Y
const FLOOR_Y     := 520.0   # 바닥 패 중심 Y
const MOUNTAIN_X  := 1750.0  # 산패 더미 X
const MOUNTAIN_Y  := 200.0
const COLLECTED_X := 1750.0  # 수집 영역 X 시작
const COLLECTED_Y := 340.0

signal hand_card_clicked(card_node: CardNode)

# 카드 노드 그룹
var _hand_nodes: Array[CardNode] = []
var _floor_nodes: Array[CardNode] = []
var _mountain_label: Label         # 산패 남은 수 표시
var _collected_labels: Dictionary  # 유형별 수집 수 라벨

var _selected_hand_node: CardNode = null


func _ready() -> void:
	_build_static_ui()


func _build_static_ui() -> void:
	# 산패 더미 더미 표시
	var mountain_bg := ColorRect.new()
	mountain_bg.size = Vector2(CARD_W, CARD_H)
	mountain_bg.position = Vector2(MOUNTAIN_X - CARD_W * 0.5, MOUNTAIN_Y - CARD_H * 0.5)
	mountain_bg.color = Color(0.2, 0.2, 0.3)
	add_child(mountain_bg)

	_mountain_label = Label.new()
	_mountain_label.position = Vector2(MOUNTAIN_X - 30, MOUNTAIN_Y - 20)
	_mountain_label.add_theme_font_size_override("font_size", 20)
	_mountain_label.text = "산패\n30"
	_mountain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_mountain_label)

	# 수집 영역 라벨 (4가지 유형)
	var types := ["gwang", "ribbon", "animal", "pi"]
	var labels := ["광", "띠", "열끗", "피"]
	_collected_labels = {}
	for i in types.size():
		var lbl := Label.new()
		lbl.position = Vector2(COLLECTED_X - 30, COLLECTED_Y + i * 40)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.text = "%s: 0" % labels[i]
		lbl.add_theme_color_override("font_color", Color.WHITE)
		add_child(lbl)
		_collected_labels[types[i]] = lbl

	# 영역 구분선
	_draw_area_labels()


func _draw_area_labels() -> void:
	var floor_label := Label.new()
	floor_label.text = "— 바닥 —"
	floor_label.position = Vector2(900, FLOOR_Y - CARD_H * 0.5 - 30)
	floor_label.add_theme_font_size_override("font_size", 16)
	floor_label.modulate = Color(1, 1, 1, 0.5)
	add_child(floor_label)

	var hand_label := Label.new()
	hand_label.text = "— 손패 —"
	hand_label.position = Vector2(900, HAND_Y - CARD_H * 0.5 - 30)
	hand_label.add_theme_font_size_override("font_size", 16)
	hand_label.modulate = Color(1, 1, 1, 0.5)
	add_child(hand_label)


## 딜링 완료 후 초기 배치
func setup_initial(hand: Array, floor: Array, mountain_count: int) -> void:
	_clear_cards()
	_place_hand(hand)
	_place_floor(floor)
	update_mountain_count(mountain_count)


## 손패 배치
func _place_hand(hand: Array) -> void:
	var count := hand.size()
	var total_w := count * CARD_W + (count - 1) * CARD_GAP
	var start_x := 960.0 - total_w * 0.5 + CARD_W * 0.5
	for i in count:
		var node := _make_card_node(hand[i])
		node.position = Vector2(start_x + i * (CARD_W + CARD_GAP), HAND_Y)
		node._base_y = HAND_Y
		node.is_interactive = true
		node.card_clicked.connect(_on_hand_card_clicked)
		add_child(node)
		_hand_nodes.append(node)


## 바닥 패 배치 (최대 10장 기준 2행)
func _place_floor(floor_cards: Array) -> void:
	for node in _floor_nodes:
		node.queue_free()
	_floor_nodes.clear()

	var count := floor_cards.size()
	var cols := min(count, 8)
	var rows := ceili(float(count) / cols)
	var total_w := cols * CARD_W + (cols - 1) * CARD_GAP
	var start_x := 800.0 - total_w * 0.5 + CARD_W * 0.5

	for i in count:
		var col := i % cols
		var row := i / cols
		var node := _make_card_node(floor_cards[i])
		node.position = Vector2(
			start_x + col * (CARD_W + CARD_GAP),
			FLOOR_Y + row * (CARD_H + CARD_GAP) - (rows - 1) * (CARD_H + CARD_GAP) * 0.5
		)
		node.is_interactive = false
		add_child(node)
		_floor_nodes.append(node)


## 산패 뒤집기 애니메이션 (더미에서 바닥으로 이동)
func animate_mountain_flip(card: CardData.Card, matched: bool) -> void:
	var node := _make_card_node(card)
	node.position = Vector2(MOUNTAIN_X, MOUNTAIN_Y)
	node.is_interactive = false
	add_child(node)

	var target_y := FLOOR_Y if not matched else FLOOR_Y - 80.0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "position:y", target_y, 0.35)

	if matched:
		tween.tween_callback(func() -> void:
			node.modulate.a = 0.0
			node.queue_free()
		)
	else:
		tween.tween_callback(func() -> void:
			_floor_nodes.append(node)
		)


## 바닥 패 갱신 (턴 처리 후 호출)
func refresh_floor(floor_cards: Array) -> void:
	_place_floor(floor_cards)


## 손패에서 카드 제거
func remove_from_hand(card_node: CardNode) -> void:
	_hand_nodes.erase(card_node)
	card_node.queue_free()
	_reposition_hand()


## 손패 재정렬
func _reposition_hand() -> void:
	var count := _hand_nodes.size()
	if count == 0:
		return
	var total_w := count * CARD_W + (count - 1) * CARD_GAP
	var start_x := 960.0 - total_w * 0.5 + CARD_W * 0.5
	for i in count:
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_hand_nodes[i], "position:x",
			start_x + i * (CARD_W + CARD_GAP), 0.2)


## 수집 패 카운터 업데이트
func update_collected(collected: Dictionary) -> void:
	for key in _collected_labels:
		var arr: Array = collected.get(key, [])
		var labels_map := {"gwang": "광", "ribbon": "띠", "animal": "열끗", "pi": "피"}
		_collected_labels[key].text = "%s: %d" % [labels_map[key], arr.size()]


## 산패 남은 수 업데이트
func update_mountain_count(count: int) -> void:
	_mountain_label.text = "산패\n%d" % count


func _on_hand_card_clicked(node: CardNode) -> void:
	# 이미 선택된 카드면 선택 해제
	if _selected_hand_node == node:
		node.set_selected(false)
		_selected_hand_node = null
		return

	# 이전 선택 해제
	if _selected_hand_node != null:
		_selected_hand_node.set_selected(false)

	_selected_hand_node = node
	node.set_selected(true)
	hand_card_clicked.emit(node)


## 선택 초기화
func clear_selection() -> void:
	if _selected_hand_node != null:
		_selected_hand_node.set_selected(false)
		_selected_hand_node = null


func _clear_cards() -> void:
	for node in _hand_nodes:
		node.queue_free()
	_hand_nodes.clear()
	for node in _floor_nodes:
		node.queue_free()
	_floor_nodes.clear()


func _make_card_node(data: CardData.Card) -> CardNode:
	var node := CardNode.new()
	node.setup(data)
	return node
