class_name Shop
extends CanvasLayer

## 상점 오버레이 — 판 종료 후 기운 카드 구매/스킵

signal shop_closed

var round_score: int = 0

# 상태
var _offered_cards: Array[KiCardData] = []
var _reroll_cost: int = 1
var _reroll_count: int = 0
var _pending_ki: KiCardData = null     # 슬롯 교체 대기 중인 신규 카드
var _exchange_panel: Control = null    # 슬롯 교체 선택 UI

# UI 노드
var _panel: Control
var _score_label: Label
var _coins_label: Label
var _card_container: HBoxContainer
var _reroll_btn: Button
var _skip_btn: Button


func _ready() -> void:
	_build_ui()
	_populate_offers()


func _build_ui() -> void:
	# 반투명 배경
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.75)
	overlay.size = Vector2(1920, 1080)
	add_child(overlay)

	# 패널
	_panel = Control.new()
	_panel.size = Vector2(960, 560)
	_panel.position = Vector2(480, 260)
	add_child(_panel)

	var bg := ColorRect.new()
	bg.size = _panel.size
	bg.color = Color(0.12, 0.12, 0.20, 0.97)
	_panel.add_child(bg)

	# 타이틀
	var title := Label.new()
	title.text = "☘ 상점"
	title.position = Vector2(380, 24)
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color(0.79, 0.66, 0.30))
	_panel.add_child(title)

	# 판 점수
	_score_label = Label.new()
	_score_label.text = "이번 판 점수: %d" % round_score
	_score_label.position = Vector2(40, 80)
	_score_label.add_theme_font_size_override("font_size", 22)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_panel.add_child(_score_label)

	# 엽전
	_coins_label = Label.new()
	_coins_label.position = Vector2(700, 80)
	_coins_label.add_theme_font_size_override("font_size", 22)
	_coins_label.add_theme_color_override("font_color", Color(0.79, 0.66, 0.30))
	_panel.add_child(_coins_label)
	_refresh_coins_label()

	# 안내 텍스트
	var hint := Label.new()
	hint.text = "기운 카드를 1장 구매하거나 스킵하세요."
	hint.position = Vector2(40, 116)
	hint.add_theme_font_size_override("font_size", 18)
	hint.modulate = Color(1, 1, 1, 0.6)
	_panel.add_child(hint)

	# 카드 선택 영역
	_card_container = HBoxContainer.new()
	_card_container.position = Vector2(40, 160)
	_card_container.add_theme_constant_override("separation", 24)
	_panel.add_child(_card_container)

	# 하단 버튼
	_reroll_btn = Button.new()
	_reroll_btn.position = Vector2(320, 480)
	_reroll_btn.size = Vector2(160, 48)
	_reroll_btn.add_theme_font_size_override("font_size", 20)
	_reroll_btn.pressed.connect(_on_reroll)
	_panel.add_child(_reroll_btn)
	_refresh_reroll_btn()

	_skip_btn = Button.new()
	_skip_btn.text = "스킵 →"
	_skip_btn.position = Vector2(680, 480)
	_skip_btn.size = Vector2(160, 48)
	_skip_btn.add_theme_font_size_override("font_size", 20)
	_skip_btn.pressed.connect(_on_skip)
	_panel.add_child(_skip_btn)

	# 등장 애니메이션
	_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 1.0, 0.25)


func _populate_offers() -> void:
	# 기존 카드 제거
	for child in _card_container.get_children():
		child.queue_free()
	_offered_cards.clear()

	# M1: 풀에서 최대 3종 제공 (슬롯 여유 있는 경우만)
	var pool := KiCardData.get_pool_m1()
	pool.shuffle()

	var ki_cards: Array = GameManager.current_run.ki_cards if GameManager.current_run else []
	var owned_ids := ki_cards.map(func(k: KiCardData) -> String: return k.id)

	# 이미 보유 중이지 않은 카드 우선 (M1은 종류 적으므로 중복 허용)
	var count := 0
	for ki in pool:
		if count >= 3:
			break
		_offered_cards.append(ki)
		_card_container.add_child(_make_card_button(ki, count))
		count += 1


func _make_card_button(ki: KiCardData, _index: int) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(260, 300)

	# 카드 배경
	var card_bg := ColorRect.new()
	card_bg.color = Color(0.18, 0.18, 0.28)
	card_bg.custom_minimum_size = Vector2(260, 220)
	container.add_child(card_bg)

	# 등급 띠
	var rarity_bar := ColorRect.new()
	rarity_bar.color = ki.get_rarity_color()
	rarity_bar.size = Vector2(260, 6)
	card_bg.add_child(rarity_bar)

	# 이모지
	var emoji_lbl := Label.new()
	emoji_lbl.text = ki.emoji
	emoji_lbl.position = Vector2(100, 20)
	emoji_lbl.add_theme_font_size_override("font_size", 56)
	card_bg.add_child(emoji_lbl)

	# 이름
	var name_lbl := Label.new()
	name_lbl.text = ki.display_name
	name_lbl.position = Vector2(10, 96)
	name_lbl.add_theme_font_size_override("font_size", 24)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	card_bg.add_child(name_lbl)

	# 등급
	var rarity_lbl := Label.new()
	rarity_lbl.text = ki.get_rarity_label()
	rarity_lbl.position = Vector2(10, 126)
	rarity_lbl.add_theme_font_size_override("font_size", 16)
	rarity_lbl.add_theme_color_override("font_color", ki.get_rarity_color())
	card_bg.add_child(rarity_lbl)

	# 설명
	var desc_lbl := Label.new()
	desc_lbl.text = ki.description
	desc_lbl.position = Vector2(10, 152)
	desc_lbl.size = Vector2(240, 60)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.modulate = Color(1, 1, 1, 0.8)
	card_bg.add_child(desc_lbl)

	# 구매 버튼 — 슬롯 꽉 차면 "교체"로 표시
	var btn := Button.new()
	var coins := GameManager.current_run.total_coins if GameManager.current_run else 0
	var ki_full := GameManager.current_run != null and GameManager.current_run.ki_cards.size() >= 5
	var can_buy := coins >= ki.price
	btn.text = ("교체 🪙%d" % ki.price) if ki_full else ("구매 🪙%d" % ki.price)
	btn.disabled = not can_buy
	btn.custom_minimum_size = Vector2(260, 48)
	btn.add_theme_font_size_override("font_size", 20)
	btn.pressed.connect(func() -> void: _on_buy(ki))
	container.add_child(btn)

	return container


func _on_buy(ki: KiCardData) -> void:
	if GameManager.current_run == null:
		return
	if not GameManager.spend_coins(ki.price):
		return
	if GameManager.current_run.ki_cards.size() >= 5:
		_pending_ki = ki
		_show_exchange_ui(ki)
		return
	GameManager.current_run.ki_cards.append(ki)
	_close()


## 슬롯 교체 UI — 기존 5개 중 하나를 선택하여 교체
func _show_exchange_ui(new_ki: KiCardData) -> void:
	var ki_cards: Array = GameManager.current_run.ki_cards

	_exchange_panel = Control.new()
	add_child(_exchange_panel)

	# 어두운 전체 오버레이 (클릭 차단)
	var bg := ColorRect.new()
	bg.size = Vector2(1920, 1080)
	bg.color = Color(0, 0, 0, 0.55)
	_exchange_panel.add_child(bg)

	# 패널
	const PX := 480.0;  const PY := 260.0
	const PW := 960.0;  const PH := 460.0
	var panel := ColorRect.new()
	panel.size = Vector2(PW, PH)
	panel.position = Vector2(PX, PY)
	panel.color = Color(0.08, 0.08, 0.17, 0.98)
	panel.modulate.a = 0.0
	_exchange_panel.add_child(panel)

	# 타이틀
	var title_lbl := Label.new()
	title_lbl.text = "어느 기운 카드와 교체할까요?"
	title_lbl.size = Vector2(PW - 80, 42)
	title_lbl.position = Vector2(PX + 40, PY + 18)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	_exchange_panel.add_child(title_lbl)

	# 새 카드 안내
	var new_lbl := Label.new()
	new_lbl.text = "새 카드: %s %s (%s)  —  %s" % [
		new_ki.emoji, new_ki.display_name, new_ki.get_rarity_label(), new_ki.description
	]
	new_lbl.size = Vector2(PW - 80, 28)
	new_lbl.position = Vector2(PX + 40, PY + 66)
	new_lbl.add_theme_font_size_override("font_size", 17)
	new_lbl.add_theme_color_override("font_color", new_ki.get_rarity_color())
	_exchange_panel.add_child(new_lbl)

	# 구분선
	var line := ColorRect.new()
	line.size = Vector2(PW - 80, 2)
	line.position = Vector2(PX + 40, PY + 102)
	line.color = Color(1, 1, 1, 0.10)
	_exchange_panel.add_child(line)

	# 기존 카드 5개 — 카드 배경 + 버튼
	const CARD_W := 160.0;  const CARD_GAP := 20.0
	const CARDS_START_X := PX + 40.0;  const CARDS_Y := PY + 114.0

	for i in ki_cards.size():
		var ki: KiCardData = ki_cards[i]
		var cx := CARDS_START_X + i * (CARD_W + CARD_GAP)
		var cy := CARDS_Y

		var card_bg := ColorRect.new()
		card_bg.size = Vector2(CARD_W, 210)
		card_bg.position = Vector2(cx, cy)
		card_bg.color = Color(0.14, 0.14, 0.24)
		_exchange_panel.add_child(card_bg)

		var rarity_bar := ColorRect.new()
		rarity_bar.size = Vector2(CARD_W, 5)
		rarity_bar.position = Vector2(cx, cy)
		rarity_bar.color = ki.get_rarity_color()
		_exchange_panel.add_child(rarity_bar)

		var emoji_lbl := Label.new()
		emoji_lbl.text = ki.emoji
		emoji_lbl.position = Vector2(cx + 52, cy + 12)
		emoji_lbl.add_theme_font_size_override("font_size", 44)
		_exchange_panel.add_child(emoji_lbl)

		var name_lbl := Label.new()
		name_lbl.text = ki.display_name
		name_lbl.size = Vector2(CARD_W - 8, 26)
		name_lbl.position = Vector2(cx + 4, cy + 74)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 17)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		_exchange_panel.add_child(name_lbl)

		var rarity_lbl := Label.new()
		rarity_lbl.text = ki.get_rarity_label()
		rarity_lbl.size = Vector2(CARD_W - 8, 20)
		rarity_lbl.position = Vector2(cx + 4, cy + 100)
		rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rarity_lbl.add_theme_font_size_override("font_size", 13)
		rarity_lbl.add_theme_color_override("font_color", ki.get_rarity_color())
		_exchange_panel.add_child(rarity_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = ki.description
		desc_lbl.size = Vector2(CARD_W - 10, 68)
		desc_lbl.position = Vector2(cx + 5, cy + 124)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.modulate = Color(1, 1, 1, 0.65)
		_exchange_panel.add_child(desc_lbl)

		# 선택 버튼
		var slot_btn := Button.new()
		slot_btn.text = "이 카드 교체"
		slot_btn.size = Vector2(CARD_W, 36)
		slot_btn.position = Vector2(cx, cy + 214)
		slot_btn.add_theme_font_size_override("font_size", 14)
		var idx := i
		slot_btn.pressed.connect(func() -> void: _on_exchange_confirmed(idx))
		_exchange_panel.add_child(slot_btn)

	# 취소 버튼 (환불)
	var cancel_btn := Button.new()
	cancel_btn.text = "취소 (코인 환불)"
	cancel_btn.size = Vector2(200, 44)
	cancel_btn.position = Vector2(PX + PW * 0.5 - 100, PY + PH - 52)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect(_on_exchange_cancelled)
	_exchange_panel.add_child(cancel_btn)

	# 등장 애니메이션
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)


func _on_exchange_confirmed(slot_idx: int) -> void:
	if _pending_ki == null or GameManager.current_run == null:
		return
	GameManager.current_run.ki_cards.remove_at(slot_idx)
	GameManager.current_run.ki_cards.append(_pending_ki)
	_pending_ki = null
	_close_exchange_ui()
	_close()


func _on_exchange_cancelled() -> void:
	if _pending_ki != null:
		GameManager.add_coins(_pending_ki.price)   # 차감됐던 코인 환불
		_pending_ki = null
	_close_exchange_ui()
	_refresh_coins_label()
	_populate_offers()   # 버튼 상태 갱신


func _close_exchange_ui() -> void:
	if _exchange_panel != null and is_instance_valid(_exchange_panel):
		_exchange_panel.queue_free()
		_exchange_panel = null


func _on_reroll() -> void:
	if not GameManager.spend_coins(_reroll_cost):
		return
	_reroll_count += 1
	_reroll_cost += 1
	_refresh_reroll_btn()
	_refresh_coins_label()
	_populate_offers()


func _on_skip() -> void:
	_close()


func _close() -> void:
	var tween := create_tween()
	tween.tween_property(_panel, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func() -> void:
		shop_closed.emit()
		queue_free()
	)


func _refresh_coins_label() -> void:
	var coins := GameManager.current_run.total_coins if GameManager.current_run else 0
	_coins_label.text = "🪙 %d" % coins


func _refresh_reroll_btn() -> void:
	var coins := GameManager.current_run.total_coins if GameManager.current_run else 0
	_reroll_btn.text = "리롤 🪙%d" % _reroll_cost
	_reroll_btn.disabled = coins < _reroll_cost
