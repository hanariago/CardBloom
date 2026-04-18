class_name Board
extends Node2D

## 게임 보드 — 손패 / 바닥 / 산패 / 수집 영역 배치 및 카드 노드 관리
##
## 레이아웃 (1920×1080):
##   HUD (y=0-60) + StatusBanner (y=62-116)
##   ComboTracker (x=0-312, y=118+)
##   Floor  (x=335-1615, y=285-815)   ← 중앙 무대
##   Right panel (x=1640-1920):
##     Mountain deck  (y=132-342)
##     Collected info (y=370-600)
##   Hand (y=830-1080)                ← 파란 구분선으로 명확히 분리

const CARD_W := CardNode.CARD_W   # 100
const CARD_H := CardNode.CARD_H   # 150
const CARD_GAP := 12.0

## 바닥 카드는 손패보다 작게 — 구역 구분 + 상대적 원근감
const FLOOR_CARD_SCALE := 0.80

# ── 레이아웃 기준점 ─────────────────────────────────────
const HAND_Y      := 940.0
const FLOOR_Y     := 540.0
const FLOOR_CX    := 975.0

const MOUNTAIN_X  := 1780.0
const MOUNTAIN_Y  := 240.0

const COLLECTED_X := 1640.0
const COLLECTED_Y := 370.0

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
	var floor_w     := 1280.0
	var floor_top_y := 285.0
	var floor_h     := 530.0   # 3행 여유

	# 바닥 테두리
	var floor_border := ColorRect.new()
	floor_border.size = Vector2(floor_w + 4, floor_h + 4)
	floor_border.position = Vector2(FLOOR_CX - floor_w * 0.5 - 2, floor_top_y - 2)
	floor_border.color = Color(0.20, 0.45, 0.25, 0.45)
	floor_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_border)

	# 바닥 패널
	var floor_panel := ColorRect.new()
	floor_panel.size = Vector2(floor_w, floor_h)
	floor_panel.position = Vector2(FLOOR_CX - floor_w * 0.5, floor_top_y)
	floor_panel.color = Color(0.05, 0.12, 0.07, 0.65)
	floor_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floor_panel)

	# 손패 구분선
	var sep := ColorRect.new()
	sep.size = Vector2(1920, 4)
	sep.position = Vector2(0, 828)
	sep.color = Color(0.32, 0.38, 0.80, 0.55)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sep)

	# 손패 배경 (남색 — 플레이어 영역)
	var hand_panel := ColorRect.new()
	hand_panel.size = Vector2(1920, 252)
	hand_panel.position = Vector2(0, 832)
	hand_panel.color = Color(0.04, 0.05, 0.18, 0.88)
	hand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_panel)

	# 산패 패널 테두리
	var mt_border := ColorRect.new()
	mt_border.size = Vector2(204, 216)
	mt_border.position = Vector2(MOUNTAIN_X - 102, MOUNTAIN_Y - 110)
	mt_border.color = Color(0.32, 0.28, 0.58, 0.65)
	mt_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mt_border)

	# 산패 패널
	var mt_panel := ColorRect.new()
	mt_panel.size = Vector2(200, 212)
	mt_panel.position = Vector2(MOUNTAIN_X - 100, MOUNTAIN_Y - 108)
	mt_panel.color = Color(0.08, 0.08, 0.22, 0.92)
	mt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mt_panel)

	# 구역 라벨
	_add_zone_label("바닥", Vector2(FLOOR_CX - floor_w * 0.5 + 14, floor_top_y + 7))
	_add_zone_label("내 패", Vector2(20, 836))


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
	# 산패 카드 더미 그래픽
	var sh_w := 76.0
	var sh_h := 108.0
	var stack_cy := MOUNTAIN_Y - 12.0
	for i in 3:
		var shadow := ColorRect.new()
		shadow.size = Vector2(sh_w, sh_h)
		shadow.position = Vector2(MOUNTAIN_X - sh_w * 0.5 + (2 - i) * 3,
								   stack_cy - sh_h * 0.5 + (2 - i) * 3)
		shadow.color = Color(0.18, 0.18, 0.32)
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shadow)

	_mountain_label = Label.new()
	_mountain_label.text = "산패"
	_mountain_label.position = Vector2(MOUNTAIN_X - 50, MOUNTAIN_Y - 105)
	_mountain_label.size = Vector2(100, 28)
	_mountain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mountain_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.95))
	_mountain_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(_mountain_label, 17)
	add_child(_mountain_label)

	_mountain_count_label = Label.new()
	_mountain_count_label.text = "30"
	_mountain_count_label.position = Vector2(MOUNTAIN_X - 50, MOUNTAIN_Y + 60)
	_mountain_count_label.size = Vector2(100, 50)
	_mountain_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mountain_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mountain_count_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.65))
	_mountain_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_pretendard(_mountain_count_label, 36)
	add_child(_mountain_count_label)

	# 수집 현황 레이블
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
	var total_w := count * CARD_W + (count - 1) * CARD_GAP
	var start_x := FLOOR_CX - total_w * 0.5 + CARD_W * 0.5
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
		node.scale = Vector2(FLOOR_CARD_SCALE, FLOOR_CARD_SCALE)  # 손패보다 작게
		node.is_interactive = false
		add_child(node)
		_floor_nodes.append(node)


# ── 위치 계산 유틸 ───────────────────────────────────────

## 바닥에서 특정 월 카드의 위치 반환 (산패 날아가기 대상)
func get_floor_month_position(month: int) -> Vector2:
	for node in _floor_nodes:
		if node.card_data != null and node.card_data.month == month:
			return node.position
	return Vector2(FLOOR_CX, FLOOR_Y)


## 바닥 카드 n장일 때 마지막 카드가 놓일 위치 계산 (산패 미매칭 날아가기 대상)
func get_new_floor_card_position(new_floor_size: int) -> Vector2:
	var count := new_floor_size
	if count == 0:
		return Vector2(FLOOR_CX, FLOOR_Y)
	var cols := mini(count, 8)
	var rows := ceili(float(count) / float(cols))
	var total_w := float(cols) * CARD_W + float(cols - 1) * CARD_GAP
	var start_x := FLOOR_CX - total_w * 0.5 + CARD_W * 0.5
	var i := count - 1
	var col := i % cols
	var row := i / cols
	return Vector2(
		start_x + float(col) * (CARD_W + CARD_GAP),
		FLOOR_Y + float(row) * (CARD_H + CARD_GAP) - float(rows - 1) * (CARD_H + CARD_GAP) * 0.5
	)


# ── 연출 효과 ────────────────────────────────────────────

## 손패 카드 → 바닥 슬롯 날아가기 (손맛 연출)
## 들기(0.08s) + 기울기 + 날아가기(0.36s) → 비행 중 반투명·축소
## 총 비행 시간 ≈ 0.44s.  queue_free 는 round.gd 에서 직접 처리.
func animate_hand_card_fly(card_node: CardNode, target_pos: Vector2) -> void:
	_hand_nodes.erase(card_node)
	_reposition_hand()

	card_node.is_interactive = false
	if card_node._hover_tween != null:
		card_node._hover_tween.kill()
	card_node.z_index = 5   # 비행 중 최상위

	var tilt := randf_range(-22.0, 22.0)   # 더 강한 기울기
	var start_y := card_node.position.y

	# 위치: 살짝 들기 → 목표로 날아가기, 착지 후 z-order 를 바닥 카드 아래로
	var pos_tween := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	pos_tween.tween_property(card_node, "position:y", start_y - 26.0, 0.08)
	pos_tween.tween_property(card_node, "position", target_pos, 0.36)
	pos_tween.tween_callback(func() -> void:
		if is_instance_valid(card_node):
			card_node.z_index = -1   # 바닥 카드가 위에 렌더링 → 아래 패가 보임
	)

	# 회전: 기울어지며 날아가기 → 착지 직전 펴기
	var rot_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	rot_tween.tween_property(card_node, "rotation_degrees", tilt, 0.10)
	rot_tween.tween_interval(0.22)
	rot_tween.tween_property(card_node, "rotation_degrees", 0.0, 0.12)

	# 비행 중 반투명 → 아래 바닥 카드가 비쳐 보임
	var alpha_tween := create_tween().set_ease(Tween.EASE_OUT)
	alpha_tween.tween_property(card_node, "modulate:a", 0.78, 0.08)

	# 비행하며 축소 → 착지 시 바닥 카드 크기(0.80)에 근접한 0.88
	var scale_tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	scale_tween.tween_interval(0.08)
	scale_tween.tween_property(card_node, "scale", Vector2(0.88, 0.88), 0.36)


## 산패 → 바닥 날아가기 + 뒤집기 연출
## target_pos: 날아갈 목표 위치 (산패 미매칭이면 새 바닥 슬롯, 매칭이면 기존 카드 위)
func animate_mountain_flip(card: CardData.Card, matched: bool, target_pos: Vector2) -> void:
	var node := _make_card_node(card)
	node.position = Vector2(MOUNTAIN_X, MOUNTAIN_Y)
	node.is_interactive = false
	node.scale = Vector2(0.0, 1.0)   # 납작 → 뒤집히는 효과
	node.z_index = 5                  # 항상 최상위 레이어
	add_child(node)

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(node, "scale:x", 1.0, 0.18)          # 카드 뒤집히며 공개
	tween.tween_interval(0.15)                                  # 읽을 시간 (짧게)
	tween.tween_property(node, "position", target_pos, 0.40)   # 목표로 날아가기

	if matched:
		tween.tween_callback(func() -> void: node.flash_glow())
		tween.tween_interval(0.45)   # 글로우 감상

	tween.tween_property(node, "modulate:a", 0.0, 0.20)
	tween.tween_callback(func() -> void: node.queue_free())


## 꽃비 연출 — 꽃잎 낙하 + 안내 배너 (2.8s)
func animate_flower_rain(month: int) -> void:
	# 반투명 핑크 오버레이
	var overlay := ColorRect.new()
	overlay.size = Vector2(1920.0, 1080.0)
	overlay.position = Vector2.ZERO
	overlay.color = Color(0.95, 0.50, 0.65, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 20
	add_child(overlay)

	var ov_tween := create_tween()
	ov_tween.tween_property(overlay, "color:a", 0.15, 0.4)
	ov_tween.tween_interval(1.8)
	ov_tween.tween_property(overlay, "color:a", 0.0, 0.6)
	ov_tween.tween_callback(overlay.queue_free)

	# 꽃잎 28개 낙하
	var petal_colors := [
		Color(0.98, 0.55, 0.70),
		Color(0.95, 0.75, 0.85),
		Color(0.93, 0.50, 0.68),
		Color(1.00, 0.85, 0.90),
		Color(0.90, 0.40, 0.60),
	]
	for i in 28:
		var petal := ColorRect.new()
		var sz := float(randi_range(7, 16))
		petal.size = Vector2(sz, sz)
		petal.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
		petal.position = Vector2(randf_range(0.0, 1920.0), randf_range(-140.0, -10.0))
		petal.color = petal_colors[randi() % petal_colors.size()]
		petal.mouse_filter = Control.MOUSE_FILTER_IGNORE
		petal.z_index = 22
		add_child(petal)

		var dur := randf_range(1.6, 2.8)
		var end_y := randf_range(900.0, 1120.0)
		var drift_x := petal.position.x + randf_range(-200.0, 200.0)

		var py := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		py.tween_property(petal, "position:y", end_y, dur)
		var px := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
		px.tween_property(petal, "position:x", drift_x, dur)
		var pr := create_tween()
		pr.tween_property(petal, "rotation", randf_range(-PI, PI), dur)
		var pa := create_tween()
		pa.tween_interval(dur * 0.7)
		pa.tween_property(petal, "modulate:a", 0.0, dur * 0.3)
		pa.tween_callback(petal.queue_free)

	# 안내 배너 텍스트
	var banner := Label.new()
	banner.text = "꽃비!  %d월 패 점수 ×2" % month
	banner.size = Vector2(820.0, 90.0)
	banner.position = Vector2(FLOOR_CX - 410.0, 420.0)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_color", Color(1.0, 0.88, 0.92))
	banner.modulate.a = 0.0
	banner.z_index = 25
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.apply_serif(banner, 52)
	add_child(banner)

	var bt := create_tween()
	bt.tween_property(banner, "modulate:a", 1.0, 0.4)
	bt.tween_interval(1.8)
	bt.tween_property(banner, "modulate:a", 0.0, 0.5)
	bt.tween_callback(banner.queue_free)


## 턴 전환 플래시 — 화면이 잠깐 어두워졌다 밝아짐 (손패→산패 구분)
func flash_turn_transition() -> void:
	var overlay := ColorRect.new()
	overlay.size = Vector2(1920, 1080)
	overlay.position = Vector2.ZERO
	overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.38, 0.12)
	tween.tween_property(overlay, "color:a", 0.0, 0.22)
	tween.tween_callback(func() -> void: overlay.queue_free())


## 바닥 카드 매칭 시 "튀기" 효과 — 수집 직전 시각적 피드백
func animate_floor_hit(month: int) -> void:
	for node in _floor_nodes:
		if node.card_data == null or node.card_data.month != month:
			continue
		if not is_instance_valid(node):
			continue
		var s := FLOOR_CARD_SCALE
		var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(node, "scale", Vector2(s * 1.25, s * 1.25), 0.07)
		tween.tween_property(node, "scale", Vector2(s, s), 0.10)


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
	var start_x := FLOOR_CX - total_w * 0.5 + CARD_W * 0.5
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
