class_name GoStopPopup
extends CanvasLayer

## 고/스톱 선택 팝업
## 목표 점수 달성 시 표시. 고 횟수에 따라 버튼 상태 변화.

signal stop_pressed
signal go_pressed

var _panel: PanelContainer
var _title_label: Label
var _score_label: Label
var _go_label: Label       # "고 (×2 → X점 예상)"
var _stop_btn: Button
var _go_btn: Button

var _go_stop: GoStop = null  # round_manager에서 주입


func _ready() -> void:
	visible = false
	_build_ui()


func _build_ui() -> void:
	# 반투명 배경
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.size = Vector2(1920, 1080)
	add_child(overlay)

	# 팝업 패널
	_panel = PanelContainer.new()
	_panel.size = Vector2(520, 320)
	_panel.position = Vector2(700, 380)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(vbox)

	# 타이틀
	_title_label = _make_label("목표 점수 달성!", 36, true)
	vbox.add_child(_title_label)

	# 현재 점수
	_score_label = _make_label("", 28)
	vbox.add_child(_score_label)

	# 고 선택 시 예상 점수 안내
	_go_label = _make_label("", 22)
	_go_label.modulate = Color(0.79, 0.66, 0.30)
	vbox.add_child(_go_label)

	# 버튼 행
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	_stop_btn = Button.new()
	_stop_btn.text = "스톱"
	_stop_btn.custom_minimum_size = Vector2(160, 56)
	_stop_btn.add_theme_font_size_override("font_size", 26)
	_stop_btn.pressed.connect(func() -> void: stop_pressed.emit())
	hbox.add_child(_stop_btn)

	_go_btn = Button.new()
	_go_btn.text = "고 (×2)"
	_go_btn.custom_minimum_size = Vector2(200, 56)
	_go_btn.add_theme_font_size_override("font_size", 26)
	_go_btn.pressed.connect(func() -> void: go_pressed.emit())
	hbox.add_child(_go_btn)


## 팝업 표시
func show_popup(current_score: int, target_score: int, go_stop_state: GoStop) -> void:
	_go_stop = go_stop_state
	_score_label.text = "현재 점수: %d  (목표: %d)" % [current_score, target_score]

	var next_mult := go_stop_state.get_next_multiplier()
	var estimated := int(current_score * next_mult)
	var go_count_next := go_stop_state.go_count + 1

	_go_label.text = "고 선택 시 × %s → 약 %d점 예상 (실패 시 점수 소멸)" % [
		_mult_str(next_mult), estimated
	]

	# 버튼 라벨 갱신
	match go_count_next:
		1: _go_btn.text = "고 (×2)"
		2: _go_btn.text = "고고 (×4)"
		3: _go_btn.text = "쓰리고 (×8)"

	_go_btn.disabled = not go_stop_state.can_go()

	# 등장 애니메이션
	visible = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.85, 0.85)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func hide_popup() -> void:
	visible = false


func _make_label(text: String, size: int, bold: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _mult_str(mult: float) -> String:
	if mult == int(mult):
		return str(int(mult))
	return "%.1f" % mult
