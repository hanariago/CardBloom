class_name Board
extends Node2D

## 게임 보드 — 손패 / 바닥 / 산패 / 수집 영역 배치 및 카드 노드 관리
##
## 레이아웃 원칙 (리서치 기반):
##   - 산패는 손패 바로 옆 하단 → "내 패 낸 후 여기서 나온다" 시각적 흐름
##   - 바닥은 중앙 상단 → 항상 시야 중심
##   - 수집 현황은 우상단 → HUD 아래 항상 노출

const CARD_W := CardNode.CARD_W   # 100
const CARD_H := CardNode.CARD_H   # 150
const CARD_GAP := 12.0

# ── 레이아웃 기준점 (1920×1080) ─────────────────────────
const HAND_Y      := 870.0    # 손패 중심 Y  (하단에서 여유)
const FLOOR_Y     := 400.0    # 바닥 패 중심 Y
const FLOOR_CX    := 855.0    # 바닥 패 수평 중심 (좌측 ComboTracker 감안)

const MOUNTAIN_X  := 1810.0   # 산패 — 우하단, 손패 옆
const MOUNTAIN_Y  := 910.0

const COLLECTED_X := 1628.0   # 수집 현황 — 우상단
const COLLECTED_Y := 145.0    # HUD + StatusBanner 아래

signal hand_card_clicked(card_node: CardNode)
signal hand_card_preview(card: CardData.Card, match_count: int)
signal hand_card_preview_ended()

var _hand_nodes: Array[CardNode] = []
var _floor_nodes: Array[CardNode] = []
var _mountain_label: Label
var _mountain_count_label: Label
var _collected_labels: Dictionary
var _selected_hand_node: CardNode = null


func _ready() -> void:
	_build_zone_panels()
	_build_static_ui()


# ── 배경 패널 ────────────────────────────────────────────

func _build_zone_panels() -> void:
	# 바닥 패 영역 패널
	var floor_w := 1280.0
	var floor_panel := ColorRect.new()
	floor_panel.size = Vector2(floor_w, CARD_H * 2 + CARD_GAP + 44)
	floor_panel.position = Vector2(
		FLOOR_CX - floor_w * 0.5,
		FLOOR_Y - CARD_H - CARD_GAP * 0.5 - 22
	)
	floor_panel.color = Color(0.07, 0.09, 0.06, 0.62)
	floor_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_panel)

	# 손패 영역 패널 (좌측 ComboTracker 공간 제외)
	var hand_panel := ColorRect.new()
	hand_panel.size = Vector2(1400, CARD_H + 36)
	hand_panel.position = Vector2(310, HAND_Y - CARD_H * 0.5 - 18)
	hand_panel.color = Color(0.06, 0.06, 0.14, 0.72)
	hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_panel)

	# 산패 영역 패널 (우하단)
	var mt_panel := ColorRect.new()
	mt_panel.size = Vector2(168, 210)
	mt_panel.position = Vector2(MOUNTAIN_X - 84, MOUNTAIN_Y - 140)
	mt_panel.color = Color(0.10, 0.10, 0.22, 0.88)
	mt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mt_panel)

	# 산패 패널 테두리
	var mt_border := ColorRect.new()
	mt_border.size = Vector2(170, 212)
	mt_border.position = Vector2(MOUNTAIN_X - 85, MOUNTAIN_Y - 141)
	mt_border.color = Color(0.30, 0.28, 0.45, 0.6)
	mt_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mt_border)
	move_child(mt_border, get_child_count() - 3)

	# 구역 라벨
	_add_zone_label("바닥", Vector2(FLOOR_CX - floor_w * 0.5 + 10, FLOOR_Y - CARD_H - CARD_GAP * 0.5 - 20))
	_add_zone_label("손패", Vector2(320, HAND_Y - CARD_H * 0.5 - 18))


func _add_zone_label(text: String, pos: Vector2) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.modulate = Color(1, 1, 1, 0.30)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(lbl, 15)
	add_child(lbl)


# ── 정적 UI (산패 / 수집 현황) ───────────────────────────

func _build_static_ui() -> void:
	# 산패 카드 더미 그래픽 (3장 겹쳐서 깊이감)
	for i in 3:
		var shadow := ColorRect.new()
		shadow.size = Vector2(CARD_W - 4, CARD_H - 4)
		shadow.position = Vector2(MOUNTAIN_X - (CARD_W - 4) * 0.5 + (2 - i) * 3,
								  MOUNTAIN_Y - CARD_H * 0.5 - 30 + (2 - i) * 3)
		shadow.color = Color(0.18, 0.18, 0.32)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow)

	# 산패 레이블
	_mountain_label = Label.new()
	_mountain_label.text = "산패"
	_mountain_label.position = Vector2(MOUNTAIN_X - 50, MOUNTAIN_Y - CARD_H * 0.5 - 55)
	_mountain_label.size = Vector2(100, 28)
	_mountain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mountain_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.95))
	_mountain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(_mountain_label, 17)
	add_child(_mountain_label)

	# 산패 수 — 크고 명확하게
	_mountain_count_label = Label.new()
	_mountain_count_label.text = "30"
	_mountain_count_label.position = Vector2(MOUNTAIN_X - 50, MOUNTAIN_Y - CARD_H * 0.5 - 24)
	_mountain_count_label.size = Vector2(100, 50)
	_mountain_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mountain_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mountain_count_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.65))
	_mountain_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(_mountain_count_label, 36)
	add_child(_mountain_count_label)

	# 수집 현황 레이블 — 우상단, 항상 노출
	var types        := ["gwang", "ribbon", "animal", "pi"]
	var label_texts  := ["光 광", "帶 띠", "動 열끗", "皮 피"]
	var label_colors := [
		Color(0.97, 0.84, 0.20),
		Color(0.92, 0.35, 0.35),
		Color(0.35, 0.75, 0.98),
		Color(0.72, 0.72, 0.75),
	]
	_collected_labels = {}
	for i in types.size():
		var lbl := Label.new()
		lbl.position = Vector2(COLLECTED_X, COLLECTED_Y + i * 54)
		lbl.size = Vector2(270, 48)
		lbl.add_theme_color_override("font_color", label_colors[i])
		lbl.text = "%s: 0" % label_texts[i]
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UITheme.apply_pretendard(lbl, 26)
		add_child(lbl)
		_collected_labels[types[i]] = lbl


# ── 카드 배치 ────────────────────────────────────────────

func setup_initial(hand: Array, floor: Array, mountain_count: int) -> void:
	_clear_cards()
	_place_hand(hand)
	_place_floor(floor)
	update_mountain_count(mountain_count)


func _place_hand(hand: Array) -> void:
	var count := hand.size()
	# 손패는 ComboTracker(x=22~312) 오른쪽부터 시작, 화면 중앙보다 약간 좌
	var total_w := count * CARD_W + (count - 1) * CARD_GAP
	var center_x := 870.0   # 산패 공간 고려해 약간 왼쪽
	var start_x := center_x - total_w * 0.5 + CARD_W * 0.5
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
	var start_x: float = FLOOR_CX - total_w * 0.5 + CARD_W * 0.5

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


# ── 산패 애니메이션 (하단 → 바닥 대각선 이동) ────────────

func animate_mountain_flip(card: CardData.Card, matched: bool) -> void:
	var node := _make_card_node(card)
	node.position = Vector2(MOUNTAIN_X, MOUNTAIN_Y - CARD_H * 0.5)
	node.is_interactive = false
	add_child(node)

	# 목적지: 바닥 중앙 or 매칭 시 살짝 위
	var target_x := FLOOR_CX
	var target_y := FLOOR_Y if not matched else FLOOR_Y - 80.0

	# 대각선 호 이동 (우하 → 좌상) — 흐름이 눈에 보임
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "position", Vector2(target_x, target_y), 0.45)

	if matched:
		tween.tween_callback(func() -> void:
			node.flash_glow()
		)
		tween.tween_interval(0.25)
		tween.tween_callback(func() -> void:
			node.modulate.a = 0.0
			node.queue_free()
		)
	else:
		tween.tween_callback(func() -> void:
			_floor_nodes.append(node)
		)


# ── 갱신 메서드 ──────────────────────────────────────────

func refresh_floor(floor_cards: Array) -> void:
	_place_floor(floor_cards)


func remove_from_hand(card_node: CardNode) -> void:
	_hand_nodes.erase(card_node)
	card_node.queue_free()
	_reposition_hand()


func _reposition_hand() -> void:
	var count := _hand_nodes.size()
	if count == 0:
		return
	var total_w := count * CARD_W + (count - 1) * CARD_GAP
	var center_x := 870.0
	var start_x := center_x - total_w * 0.5 + CARD_W * 0.5
	for i in count:
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(_hand_nodes[i], "position:x",
			start_x + i * (CARD_W + CARD_GAP), 0.2)
		_hand_nodes[i]._base_y = HAND_Y


func highlight_matching_floor(month: int) -> void:
	for node in _floor_nodes:
		node.set_highlight(node.card_data != null and node.card_data.month == month)


func clear_highlights() -> void:
	for node in _floor_nodes:
		node.set_highlight(false)


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


func update_mountain_count(count: int) -> void:
	_mountain_count_label.text = str(count)
	# 카운트 바운스 애니메이션
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(_mountain_count_label, "scale", Vector2(1.3, 1.3), 0.0)
	tween.tween_property(_mountain_count_label, "scale", Vector2.ONE, 0.3)


# ── 입력 핸들러 ──────────────────────────────────────────

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
