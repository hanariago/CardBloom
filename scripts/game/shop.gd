class_name Shop
extends CanvasLayer

## 상점 오버레이 — 판 종료 후 기운 카드 구매/스킵

signal shop_closed

var round_score: int = 0

# 상태
var _offered_cards: Array[KiCardData] = []
var _reroll_cost: int = 1
var _reroll_count: int = 0

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

	# 구매 버튼
	var btn := Button.new()
	var coins := GameManager.current_run.total_coins if GameManager.current_run else 0
	var can_buy := coins >= ki.price and \
		(GameManager.current_run == null or GameManager.current_run.ki_cards.size() < 5)
	btn.text = "구매 🪙%d" % ki.price
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
		# TODO: 슬롯 교체 UI (M2)
		return
	GameManager.current_run.ki_cards.append(ki)
	_close()


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
