class_name ScorePopup
extends Node2D

## 점수 획득 팝업 — "+N점" 텍스트가 위로 떠오르며 사라짐

var _label: Label


func _ready() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	UITheme.apply_pretendard(_label, 32)
	add_child(_label)


## 팝업 시작 (ready 후 호출)
func _start(amount: int) -> void:
	_label.text = "+%d점" % amount
	_label.modulate.a = 1.0

	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "position:y", position.y - 80.0, 0.7)
	tween.parallel().tween_property(_label, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.tween_callback(queue_free)


## 월드 좌표에 팝업 스폰 (parent = Board Node2D)
static func spawn(parent: Node, world_pos: Vector2, amount: int) -> void:
	if amount <= 0:
		return
	var popup := ScorePopup.new()
	parent.add_child(popup)
	popup.position = world_pos
	popup._start(amount)
