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
var _combo_label: Label

var _combo_tween: Tween
var _score_pulse_tween: Tween


func _ready() -> void:
	add_child(score_display)
	_build_ui()
	score_display.score_label = _score_label


func _build_ui() -> void:
	# 상단 HUD 배경
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.14, 0.90)
	bg.size = Vector2(1920, 60)
	add_child(bg)

	# 점수 (중앙 크게)
	_score_label = _make_label("0", Vector2(710, 4), 52, true)
	_score_label.custom_minimum_size = Vector2(500, 54)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 목표 점수 (점수 우측, 강조)
	_target_label = _make_label("목표: 0", Vector2(1220, 14), 30)
	_target_label.add_theme_color_override("font_color", Color(0.85, 0.70, 0.35))

	# 턴 (좌측)
	_turn_label = _make_label("턴 1 / 10", Vector2(340, 14), 30)

	# 엽전 (우측)
	_coins_label = _make_label("엽전 0", Vector2(1530, 14), 28)

	# 기운 카드 슬롯
	_build_ki_slots()

	# 연쇄 팝업 (화면 중앙)
	_combo_label = _make_label("", Vector2(760, 130), 40, true)
	_combo_label.size = Vector2(400, 50)
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.add_theme_color_override("font_color", Color(0.97, 0.84, 0.40))
	_combo_label.visible = false


func _build_ki_slots() -> void:
	var slot_size := Vector2(60, 60)
	var start_x := 1920.0 - (slot_size.x + 6) * 5 - 16
	var slot_y := 70.0
	for i in 5:
		var slot := ColorRect.new()
		slot.size = slot_size
		slot.position = Vector2(start_x + i * (slot_size.x + 6), slot_y)
		slot.color = Color(0.18, 0.18, 0.28, 0.85)
		add_child(slot)

		var lbl := Label.new()
		lbl.text = str(i + 1)
		lbl.position = Vector2(start_x + i * (slot_size.x + 6) + 22, slot_y + 18)
		lbl.add_theme_color_override("font_color", Color(1, 1, 1, 0.28))
		UITheme.apply_pretendard(lbl, 18)
		add_child(lbl)
		_ki_slots.append(slot)


## 기운 카드 슬롯 업데이트
func update_ki_slots(ki_cards: Array) -> void:
	for i in _ki_slots.size():
		var slot := _ki_slots[i] as ColorRect
		if i < ki_cards.size():
			var ki := ki_cards[i] as KiCardData
			slot.color = ki.get_rarity_color()
			if slot.get_child_count() == 0:
				var lbl := Label.new()
				UITheme.apply_pretendard(lbl, 26)
				lbl.position = Vector2(10, 12)
				slot.add_child(lbl)
			(slot.get_child(0) as Label).text = ki.emoji
		else:
			slot.color = Color(0.18, 0.18, 0.28, 0.85)


func _make_label(text: String, pos: Vector2, size: int, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_color_override("font_color", Color.WHITE)
	UITheme.apply_pretendard(label, size)
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
	_coins_label.text = "엽전 %d" % coins


## 고 모드 — 점수 레이블 붉은 맥박 / 해제 시 원래 색 복귀
func set_go_mode(active: bool) -> void:
	if _score_pulse_tween:
		_score_pulse_tween.kill()
		_score_pulse_tween = null
	if active:
		_score_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		_score_pulse_tween = create_tween().set_loops()
		_score_pulse_tween.tween_property(_score_label, "modulate", Color(1.25, 0.38, 0.38), 0.50)
		_score_pulse_tween.tween_property(_score_label, "modulate", Color(1.0, 0.75, 0.75), 0.50)
	else:
		_score_label.add_theme_color_override("font_color", Color.WHITE)
		_score_label.modulate = Color.WHITE


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
