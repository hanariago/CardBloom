class_name HUD
extends CanvasLayer

## HUD — 점수, 목표 점수, 턴, 엽전 표시

var score_display: ScoreDisplay = ScoreDisplay.new()

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
	_coins_label = _make_label("🪙 0", Vector2(1750, 16), 28)

	# 연쇄 팝업 (화면 중앙 하단)
	_combo_label = _make_label("", Vector2(860, 120), 36, true)
	_combo_label.modulate = Color(0.79, 0.66, 0.30)
	_combo_label.visible = false


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
