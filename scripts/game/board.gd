class_name Board
extends Node2D

## 게임 보드 — 손패 / 바닥 / 산패 / 수집 영역 배치 및 카드 노드 관리

const CARD_W := CardNode.CARD_W
const CARD_H := CardNode.CARD_H
const CARD_GAP := 12.0

# 레이아웃 기준점 (1920×1080 기준)
const HAND_Y      := 930.0   # 손패 중심 Y
const FLOOR_Y     := 370.0   # 바닥 패 중심 Y
const MOUNTAIN_X  := 1780.0  # 산패 더미 X
const MOUNTAIN_Y  := 280.0
const COLLECTED_X := 1680.0  # 수집 영역 X 시작
const COLLECTED_Y := 460.0

signal hand_card_clicked(card_node: CardNode)
signal hand_card_preview(card: CardData.Card, match_count: int)
signal hand_card_preview_ended()

# 카드 노드 그룹
var _hand_nodes: Array[CardNode] = []
var _floor_nodes: Array[CardNode] = []
var _mountain_label: Label
var _collected_labels: Dictionary

var _selected_hand_node: CardNode = null


func _ready() -> void:
	_build_zone_panels()
	_build_static_ui()


func _build_zone_panels() -> void:
	# 손패 영역 패널
	var hand_panel := ColorRect.new()
	hand_panel.size = Vector2(1400, CARD_H + 40)
	hand_panel.position = Vector2(260, HAND_Y - CARD_H * 0.5 - 20)
	hand_panel.color = Color(0.06, 0.06, 0.14, 0.70)
	hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_panel)

	# 바닥 패 영역 패널
	var floor_panel := ColorRect.new()
	floor_panel.size = Vector2(1200, CARD_H * 2 + CARD_GAP + 40)
	floor_panel.position = Vector2(190, FLOOR_Y - CARD_H - CARD_GAP * 0.5 - 20)
	floor_panel.color = Color(0.08, 0.10, 0.06, 0.60)
	floor_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_panel)

	# 영역 라벨
	_add_zone_label("바닥", Vector2(200, FLOOR_Y - CARD_H - CARD_GAP * 0.5 - 18))
	_add_zone_label("손패", Vector2(270, HAND_Y - CARD_H * 0.5 - 18))


func _add_zone_label(text: String, pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.modulate = Color(1, 1, 1, 0.35)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(lbl, 15)
	add_child(lbl)


func _build_static_ui() -> void:
	# 산패 더미 배경
	var mountain_bg := ColorRect.new()
	mountain_bg.size = Vector2(CARD_W + 6, CARD_H + 6)
	mountain_bg.position = Vector2(MOUNTAIN_X - (CARD_W + 6) * 0.5, MOUNTAIN_Y - (CARD_H + 6) * 0.5)
	mountain_bg.color = Color(0.15, 0.15, 0.25)
	mountain_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mountain_bg)

	_mountain_label = Label.new()
	_mountain_label.position = Vector2(MOUNTAIN_X - 46, MOUNTAIN_Y - 28)
	_mountain_label.size = Vector2(92, 56)
	_mountain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mountain_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mountain_label.text = "산패\n30"
	_mountain_label.add_theme_color_override("font_color", Color(0.85, 0.85, 1.0))
	_mountain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(_mountain_label, 22)
	add_child(_mountain_label)

	# 수집 영역 라벨 — 크고 명확하게
	var types  := ["gwang", "ribbon", "animal", "pi"]
	var label_texts := ["光 광", "帶 띠", "動 열끗", "皮 피"]
	var label_colors := [
		Color(0.97, 0.84, 0.20),   # 광 — 금색
		Color(0.92, 0.35, 0.35),   # 띠 — 붉은
		Color(0.35, 0.75, 0.98),   # 열끗 — 청색
		Color(0.72, 0.72, 0.75),   # 피 — 회색
	]
	_collected_labels = {}
	for i in types.size():
		var lbl := Label.new()
		lbl.position = Vector2(COLLECTED_X - 10, COLLECTED_Y + i * 48)
		lbl.size = Vector2(160, 44)
		lbl.add_theme_color_override("font_color", label_colors[i])
		lbl.text = "%s: 0" % label_texts[i]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UITheme.apply_pretendard(lbl, 24)
		add_child(lbl)
		_collected_labels[types[i]] = lbl


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
		node.card_hovered.connect(_on_hand_card_hovered)
		node.card_unhovered.connect(_on_hand_card_unhovered)
		add_child(node)
		_hand_nodes.append(node)


## 바닥 패 배치 (최대 2행)
func _place_floor(floor_cards: Array) -> void:
	for node in _floor_nodes:
		node.queue_free()
	_floor_nodes.clear()

	var count: int = floor_cards.size()
	if count == 0:
		return
	var cols: int = mini(count, 8)
	var rows: int = ceili(float(count) / float(cols))
	var total_w: float = cols * CARD_W + (cols - 1) * CARD_GAP
	var start_x: float = 790.0 - total_w * 0.5 + CARD_W * 0.5

	for i in count:
		var col: int = i % cols
		var row: int = i / cols
		var node := _make_card_node(floor_cards[i])
		node.position = Vector2(
			start_x + col * (CARD_W + CARD_GAP),
			FLOOR_Y + row * (CARD_H + CARD_GAP) - (rows - 1) * (CARD_H + CARD_GAP) * 0.5
		)
		node.is_interactive = false
		add_child(node)
		_floor_nodes.append(node)


## 산패 뒤집기 애니메이션
func animate_mountain_flip(card: CardData.Card, matched: bool) -> void:
	var node := _make_card_node(card)
	node.position = Vector2(MOUNTAIN_X, MOUNTAIN_Y)
	node.is_interactive = false
	add_child(node)

	var target_y := FLOOR_Y if not matched else FLOOR_Y - 90.0
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


## 바닥 패 갱신
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
		_hand_nodes[i]._base_y = HAND_Y


## 매칭 가능한 바닥 카드 하이라이트
func highlight_matching_floor(month: int) -> void:
	for node in _floor_nodes:
		node.set_highlight(node.card_data != null and node.card_data.month == month)


## 하이라이트 전체 해제
func clear_highlights() -> void:
	for node in _floor_nodes:
		node.set_highlight(false)


## 수집 패 카운터 업데이트 (변경된 항목 반짝임)
func update_collected(collected: Dictionary) -> void:
	var label_map := {"gwang": "光 광", "ribbon": "帶 띠", "animal": "動 열끗", "pi": "皮 피"}
	for key in _collected_labels:
		var arr: Array = collected.get(key, [])
		var lbl: Label = _collected_labels[key]
		var new_text := "%s: %d" % [label_map[key], arr.size()]
		if new_text != lbl.text and arr.size() > 0:
			_flash_label(lbl)
		lbl.text = new_text


func _flash_label(lbl: Label) -> void:
	var tween := create_tween()
	tween.tween_property(lbl, "modulate", Color(2.0, 1.8, 0.4, 1.0), 0.0)
	tween.tween_property(lbl, "modulate", Color.WHITE, 0.5)


## 산패 남은 수 업데이트
func update_mountain_count(count: int) -> void:
	_mountain_label.text = "산패\n%d" % count


func _on_hand_card_hovered(node: CardNode) -> void:
	if _selected_hand_node == null and node.card_data != null:
		highlight_matching_floor(node.card_data.month)
		var count := _count_floor_matches(node.card_data.month)
		hand_card_preview.emit(node.card_data, count)


func _on_hand_card_unhovered(_node: CardNode) -> void:
	if _selected_hand_node == null:
		clear_highlights()
		hand_card_preview_ended.emit()


func _count_floor_matches(month: int) -> int:
	var count := 0
	for n in _floor_nodes:
		if n.card_data != null and n.card_data.month == month:
			count += 1
	return count


func _on_hand_card_clicked(node: CardNode) -> void:
	if _selected_hand_node == node:
		node.set_selected(false)
		_selected_hand_node = null
		clear_highlights()
		return

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
	clear_highlights()


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
