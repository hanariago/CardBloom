class_name HUD
extends CanvasLayer

## HUD — 점수, 목표 점수, 턴, 엽전 표시

var score_display: ScoreDisplay = ScoreDisplay.new()

## 화면 흔들림 대상 (round.gd에서 board를 주입)
var screen_shake_target: Node2D:
	set(v):
		screen_shake_target = v
		score_display.screen_shake_target = v

# 기운 카드 슬롯 (5칸)
var _ki_slots: Array[Control] = []

var _score_label: Label
var _target_label: Label
var _turn_label: Label
var _coins_label: Label
var _combo_label: Label   # 연쇄 매칭 텍스트 (잠깐 표시)

var _combo_tween: Tween


func _ready() -> void:
	add_child(score_display)
	_build_ui()
	score_display.score_label = _score_label


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.18, 0.85)
	bg.size = Vector2(1920, 64)
	add_child(bg)

	# 점수 (중앙)
	_score_label = _make_label("0", Vector2(760, 8), 48, true)
	_score_label.custom_minimum_size = Vector2(400, 48)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 목표 점수 (점수 우측)
	_target_label = _make_label("목표: 0", Vector2(1170, 16), 28)

	# 턴 (좌측)
	_turn_label = _make_label("턴 1 / 10", Vector2(40, 16), 28)

	# 엽전 (우측)
	_coins_label = _make_label("🪙 0", Vector2(1680, 16), 28)

	# 기운 카드 슬롯 5칸 (HUD 우측 하단 영역)
	_build_ki_slots()

	# 연쇄 팝업 (화면 중앙 하단)
	_combo_label = _make_label("", Vector2(860, 120), 36, true)
	_combo_label.modulate = Color(0.79, 0.66, 0.30)
	_combo_label.visible = false


func _build_ki_slots() -> void:
	var slot_size := Vector2(56, 56)
	var start_x := 1920.0 - (slot_size.x + 6) * 5 - 16
	var slot_y := 74.0
	for i in 5:
		var slot := ColorRect.new()
		slot.size = slot_size
		slot.position = Vector2(start_x + i * (slot_size.x + 6), slot_y)
		slot.color = Color(0.2, 0.2, 0.3, 0.8)
		add_child(slot)
		var lbl := Label.new()
		lbl.text = str(i + 1)
		lbl.position = Vector2(start_x + i * (slot_size.x + 6) + 20, slot_y + 16)
		lbl.add_theme_font_size_override("font_size", 18)
		lbl.modulate = Color(1, 1, 1, 0.3)
		add_child(lbl)
		_ki_slots.append(slot)


## 기운 카드 슬롯 업데이트
func update_ki_slots(ki_cards: Array) -> void:
	for i in _ki_slots.size():
		var slot := _ki_slots[i] as ColorRect
		if i < ki_cards.size():
			var ki := ki_cards[i] as KiCardData
			slot.color = ki.get_rarity_color()
			# 슬롯 위 이모지 라벨
			if slot.get_child_count() == 0:
				var lbl := Label.new()
				lbl.add_theme_font_size_override("font_size", 28)
				lbl.position = Vector2(8, 10)
				slot.add_child(lbl)
			(slot.get_child(0) as Label).text = ki.emoji
		else:
			slot.color = Color(0.2, 0.2, 0.3, 0.8)


func _make_label(text: String, pos: Vector2, size: int, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	return label


# ── 업데이트 메서드 ────────────────────────────────────

func update_score(new_score: int) -> void:
	score_display.animate_to(new_score)


func update_target(target: int) -> void:
	_target_label.text = "목표: %d" % target


func update_turn(current: int, max_turns: int) -> void:
	_turn_label.text = "턴 %d / %d" % [current, max_turns]


func update_coins(coins: int) -> void:
	_coins_label.text = "🪙 %d" % coins


## 연쇄 매칭 텍스트 잠깐 표시
func show_chain(label: String) -> void:
	if label.is_empty():
		return
	_combo_label.text = label
	_combo_label.visible = true
	_combo_label.modulate.a = 1.0

	if _combo_tween:
		_combo_tween.kill()
	_combo_tween = create_tween()
	_combo_tween.tween_interval(0.8)
	_combo_tween.tween_property(_combo_label, "modulate:a", 0.0, 0.4)
	_combo_tween.tween_callback(func() -> void: _combo_label.visible = false)
